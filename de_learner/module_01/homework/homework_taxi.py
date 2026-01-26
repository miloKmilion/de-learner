import argparse
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
    """Download any file from URL with retry logic."""
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

    # Detect file type
    if url.endswith(".parquet"):
        file_name = "output.parquet"
        file_type = "parquet"
    elif url.endswith(".csv"):
        file_name = "output.csv"
        file_type = "csv"
    else:
        msg = f"Unsupported file format: {url}. Only .parquet and .csv are supported."
        logger.error(msg)
        raise ValueError(msg)

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
        if file_type == "parquet":
            logger.info("Ingesting Parquet file into table '{}'", table_name)
            ingest_parquet_to_postgresql(file_name, table_name, engine, chunk_size)
        else:  # csv
            logger.info("Ingesting CSV file into table '{}'", table_name)
            ingest_csv_to_postgresql(file_name, table_name, engine, chunk_size)
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


def ingest_csv_to_postgresql(
    csv_file: str | Path,
    table_name: str,
    engine: Engine,
    chunk_size: int = 100000,
) -> None:
    """
    Ingests data from a CSV file into PostgreSQL in chunks.
    """
    # First, read just to count rows
    df_temp = pd.read_csv(csv_file, nrows=1)
    total_rows = sum(1 for _ in open(csv_file)) - 1  # Subtract header row
    logger.info(f"Starting ingestion of {total_rows} rows from '{csv_file}' into table '{table_name}'.")

    # Read and insert in chunks
    for chunk_num, df_chunk in enumerate(pd.read_csv(csv_file, chunksize=chunk_size)):
        t_start = time()
        start = chunk_num * chunk_size
        end = start + len(df_chunk)

        try:
            insert_chunk_to_postgres(df_chunk, table_name, engine)
            t_end = time()
            logger.debug(f"Inserted rows {start} to {end}, took {t_end - t_start:.2f} seconds.")
        except Exception:
            logger.exception(f"Failed to insert chunk {start} to {end}.")
            raise

    logger.success(f"Finished ingesting CSV data into table '{table_name}'.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download and ingest Parquet or CSV data into PostgreSQL.")

    parser.add_argument(
        "--url",
        default="https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet",
        required=True,
        help="URL of the Parquet or CSV file",
    )
    parser.add_argument("--user", default="root", required=True, help="PostgreSQL username")
    parser.add_argument("--password", default="root", required=True, help="PostgreSQL password")
    parser.add_argument("--host", default="localhost", help="PostgreSQL host (default: localhost)")
    parser.add_argument("--port", default="5432", help="PostgreSQL port (default: 5432)")
    parser.add_argument("--db", default="ny_taxi", required=True, help="PostgreSQL database name")
    parser.add_argument("--table_name", default="yellow_taxi_data", required=True, help="Table name to ingest into")
    parser.add_argument("--chunk_size", type=int, default=100000, help="Chunk size for ingestion (default: 100000)")

    args = parser.parse_args()

    process_data(
        url=args.url,
        user=args.user,
        password=args.password,
        host=args.host,
        port=args.port,
        db=args.db,
        table_name=args.table_name,
        chunk_size=args.chunk_size,
    )
