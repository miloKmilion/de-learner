# Ingesting Data to POSTGRES

It is possible just to use a Docker image with Postgres on the bat.
For the docker some things are needed, such as:

- USER
- PASSWORD
- DB

The previous environmental variables need to be pass in the Docker image.

Volumes is a way to map the folder in the host machine to the docker image. Since Postgres is a DB needs to keep record of the files stored somehow. And if the image is shutdown we dont want to keep the data available.

```bash
docker run -it \
    -e POSTGRES_USER="root" \
    -e POSTGRES_PASSWORD="root" \
    -e POSTGRES_DB="ny_taxi" \
    -v ~/projects/de-learner/data/ny_taxi_postgres_data:/var/lib/posgresql/data \
    -p 5432:5432 \
    postgres:latest
```

After the server is running we can alternatively observe the data in several forms:

## PGCLI

It is a python library that allos to view and manipoulate the date in the PostGres DB. Since we are running an UV environment. Needs to be run with the command:

```bash
uv run pgcli postgresql://root:root@localhost:5432/ny_taxi
```

At this point the tables are empty and the command `\dt` will return nothing.

### How to put the data in PostGres

- Create a script that reads the dataframe.
- Generate the schema, which is a collection of the columns and the Dtype, for example in pandas -> `pd.io.sql.get_schema(df, table_name)`.
- We need to generate the DDL statement (Data Definition Language) to make Postgres understand how the data looks like.
- SqlAlchemy: Needed to create the engine:

  ```python
  from sqlalchemy import create_engine

  engine = create_engine('postgresql://root:root@localhost:5432/ny_taxi')
  engine.connect()

  # To check:
  print(pd.io.sql.get_schema(df, table_name, con=engine)
  ```

- It is important to chunk the df or parquet to insert the data in batches, e.g., chunksize=100000
- **Note:** The iterator in pandas only works for csv data, not parquet.
- It is a good practice to initially create the table, and introduce the column names to evlauate the connection and the schema:

  ```python
  df.to_sql(name='yellow_taxi_data', con=engine, if_exists='replace')
  ```

#### Follow these steps

- In order to run the process properly, it is necessary:

  1. Open Docker.
  2. Run the Postgres Image. So is active and ready to accept data.
  3. Run the script, sometimes psycogpg2 needs to be installed beforehand.
  4. Evaluate the process by `\dt`, this will retrieve the tables created.
  5. in PGCLI: `SELECT * FROM yellow_taxi_data LIMIT 10;` to observe a set of the table
  6. in PGCLI: `\d ny_taxi_data` to describe the data.

### Connecting PgAdmin and PostGres

PgCLI is mainly used to have a quick view of the data. The command line environment sometimes can be difficult. Hence, pgAdmin is used.

- pdAdmin: It is a web-based GUI tool used to interact with the postgres Database.
- It can be installed locally or via docker `docker pull dpage/pgadmin4:snapshot`

To run it via docker:

```bash
docker run -it \
    -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
    -e PGADMIN_DEFAULT_PASSWORD="root" \
    -p 8080:80 \
    dpage/pgadmin4:snapshot
```

It is important to remember that if running from the container, the localhost indicates the port in the container and not your machine. To connect with the local network we need to bridge them using **docker networks**.

### Docker Networks

It is a way to connect containers inside the same "hood". Making possible to tunnel ports between containers for data transfer and communication.

1. To create a network: `docker network create <name>`
2. Add the `--network=<name>` abd the name `--name=<name>` which will be the way in how pgAdmin finds the network.

```bash
docker network create pg-network

docker run -it \
    -e POSTGRES_USER="root" \
    -e POSTGRES_PASSWORD="root" \
    -e POSTGRES_DB="ny_taxi" \
    -v ~/projects/de-learner/data/ny_taxi_postgres_data:/var/lib/posgresql/data \
    -p 5432:5432 \
    --network=pg-network \
    --name=pg-database \
    postgres:latest
```

### How to dockerize the ingestion Script

If the script is in a Jupiter notebook it is possible to:

```bash
jupyter nbconvert --to=script
```

However for the script **ingest_data.py** we can use either argparse or typer to create the input fields necessary for the script to run.

Based on the structure of the project:

```Dockerfile
# Base image
FROM python:3.12-slim

WORKDIR /app

# Install uv
RUN pip install uv

# Copy project metadata from root into /app
COPY pyproject.toml uv.lock ./

# Install dependencies via uv
RUN uv pip install -r uv.lock

# Copy the module folder only
COPY de_learner/ de_learner/

# Set default command
ENTRYPOINT ["uv", "run", "python", "de_learner/module01/2_docker_sql/ingest_data.py"]
```

to Build the image, it is necessary to be in the project root:

```bash
docker build -f de_learner/module01/2_docker_sql/Dockerfile -t ingest-script .

# Running the container with params
docker run ingest-script \
    --url "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2021-01.parquet" \
    --user root \
    --password root \
    --host host.docker.internal \
    --port 5432 \
    --db ny_taxi \
    --table_name yellow_taxi_data \
    --chunk_size 100000
```

### Connecting Postgres and pgAdmin using DockerCompose

At this moment we have different docker commands running in different environments or terminals, also connected by the Docker-network.

A way to make things run easier is to move those containers into a single file and running them all at once.

> DockerCompose: Is a tool for defining and running multi-containers. Using YAML file to configure the application's services.

```yaml
version: "3.8"

services:
  pgdatabase:
    image: postgres:latest
    container_name: pg-database
    environment:
      POSTGRES_USER: root
      POSTGRES_PASSWORD: root
      POSTGRES_DB: ny_taxi
    volumes:
      - ./data/ny_taxi_postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - pg-network

  pgadmin:
    image: dpage/pgadmin4:snapshot
    container_name: pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@admin.com
      PGADMIN_DEFAULT_PASSWORD: root
    ports:
      - "8080:80"
    depends_on:
      - pgdatabase
    networks:
      - pg-network

networks:
  pg-network:
```

To run the yaml in a detach mode abnd shutting it down:

```bash
docker-compose up -d

docker-compose down
```
