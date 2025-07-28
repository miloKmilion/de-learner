from pathlib import Path
from time import time

import pandas as pd
import pyarrow.parquet as pq
import requests
from loguru import logger
from sqlalchemy import Engine, create_engine
from sqlalchemy.exc import SQLAlchemyError
from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_fixed


@retry(
    wait=wait_fixed(5),
    stop=stop_after_attempt(3),
    retry=retry_if_exception_type(requests.RequestException),
    reraise=True,
)
def download_file(url: str, file_name: str) -> None:
    logger.info(f"Downloading file from {url} ...")
    response = requests.get(url, stream=True, timeout=10)
    response.raise_for_status()
    with open(file_name, "wb") as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
    logger.success(f"File downloaded successfully: {file_name}")


def process_data(  # noqa: PLR0913
    url: str,
    user: str,
    password: str,
    host: str,
    port: str,
    db: str,
    table_name: str,
    chunk_size: int = 100000,
) -> None:
    logger.info("Starting data processing for URL: {}", url)

    if not url.endswith(".parquet"):
        msg = f"Unsupported file format: {url}"
        logger.error(msg)
        raise ValueError(msg)

    file_name = "output.parquet"

    try:
        download_file(url, file_name)
        logger.success("File downloaded: {}", file_name)
    except requests.RequestException as e:
        logger.exception("Download failed.")
        raise RuntimeError(f"Download failed: {e}") from e  # noqa: TRY003

    try:
        engine: Engine = create_engine(f"postgresql://{user}:{password}@{host}:{port}/{db}")
        logger.debug("Database engine created for DB: {}", db)
    except Exception:
        logger.exception("Could not create database engine.")
        raise

    try:
        logger.info("Ingesting Parquet file into table '{}'", table_name)
        ingest_parquet_to_postgresql(file_name, table_name, engine, chunk_size)
        logger.success("Ingestion complete for table '{}'", table_name)
    except Exception:
        logger.exception("Ingestion failed.")
        raise


@retry(
    wait=wait_fixed(3),
    stop=stop_after_attempt(3),
    retry=retry_if_exception_type((SQLAlchemyError, ConnectionError)),
    reraise=True,
)
def insert_chunk_to_postgres(df_chunk: pd.DataFrame, table_name: str, engine: Engine) -> None:
    df_chunk.to_sql(table_name, engine, if_exists="append", index=False)


def ingest_parquet_to_postgresql(
    parquet_file: str | Path,
    table_name: str,
    engine: Engine,
    chunk_size: int = 100000,
) -> None:
    """
    Ingests data from a Parquet file into PostgreSQL in chunks.
    """
    table = pq.read_table(parquet_file)
    total_rows = table.num_rows
    logger.info(f"Starting ingestion of {total_rows} rows from '{parquet_file}' into table '{table_name}'.")

    for start in range(0, total_rows, chunk_size):
        t_start = time()

        end = min(start + chunk_size, total_rows)
        df_chunk = table.slice(start, end - start).to_pandas()

        try:
            insert_chunk_to_postgres(df_chunk, table_name, engine)
            t_end = time()
            logger.debug(f"Inserted rows {start} to {end}, took {t_end - t_start:.2f} seconds.")
        except Exception:
            logger.exception(f"Failed to insert chunk {start} to {end}.")
            raise

    logger.success(f"Finished ingesting Parquet data into table '{table_name}'.")


process_data(
    url="https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2021-01.parquet",
    user="root",
    password="root",  # noqa: S106
    host="localhost",
    port="5432",
    db="ny_taxi",
    table_name="yellow_taxi_data",
    chunk_size=100000,
)
