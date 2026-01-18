# Module 1

## 1. Introduction to DOCKER

What is docker?
An application that delivers software in containers that are isolated from each other.

Example a data pipeline will run in isolation, but what is a pipeline? It is a process service that ingest data to produce data. Or from source to destination.

```shell
CSV -> DATA PIPELINE (py script) -> Table in Postres
```

A pipeline can be composed from different pipelines way smaller.

### How does it run?

- A Host Computer (Win, Linux)
  - Container in UBUNTU
    - Python
    - Pandas
    - Postgres connection library

A host computer can have several containers, one for example containing the data pipeline steps and another with PostgresDB or different databases that will not interfere with each other.

pgAdmin used to run SQL queries and be apart of the DB so the data is safe.

### Why is DOCKER needed?

- Reproducibility
- Local experiments
- Testing and integration (CI/CD) -> Github Actions
- Running pipelines on the cloud (AWS Batch, Kubernetes jobs)
- Spark
- Serverless (AWS lambda, Google Functions)

### What is needed

#### 1. Testing Docker

```bash
docker hello-world
```

This will go to docker hub and search an image with this name and give some output. Necessary to know if docker is working correctly.

Another alternative is to run:

```bash
docker run -it bash
```

The mode i indicates interative and the t terminal, it means that we are able to run the image in the terminal, example the batch.

The images are immutable, so for example if something is deleted from the image. By running the image again it will return to the original state.

```bash
docker run -it python:3.12
```

This will run the basal container with a python image installed. However, when installing a component like pandas or a script it will vanish when the image is resetted.

#### 2. Dockerfile

This file is the starting point with the instructions needed to build an image container.

The following is an excample of the basic dockerfile, in order to build the image we need to run `docker build -t test:pandas .` the name:tag is needed as well as the location (.)

To run the image after being built: `docker run -it test:pandas`

When a file or a script needs to be added to the docker image, it is necessary to copy the file from the host to the docker.

In order to a pipeline to be called a real pipeline. It is necessary to perform certain automatizations such as the pipeline script needs to be run automatically, the data gathered needs to be fetch on demand and by date for example.

The entrypoint can change to point directly to the script where the main pipeline is stored.

```Dockerfile
FROM python:3.12

RUN pip install pandas

# Copyng the pipeline.py to the docker
WORKDIR /app
COPY pipeline.py pipeline.py

ENTRYPOINT ["python", "pipeline.py"]
```

While using UV as package and project manager the dockerfile can change to:

```Dockerfile
FROM python:3.12-slim

# Install uv
RUN pip install uv

# Set workdir
WORKDIR /app

# Copy project files
COPY pyproject.toml uv.lock ./
RUN uv pip install -r uv.lock  # Installs deps from lockfile

# Copy the actual pipeline code
COPY pipeline.py .

# Run the script using uv's environment
ENTRYPOINT ["python", "pipeline.py"]
```
