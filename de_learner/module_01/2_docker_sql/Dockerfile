FROM python:3.12-slim

# Install uv using the official method
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Set workdir
WORKDIR /app

# Copy project files needed for dependency installation
COPY ingest_data.py pipeline.py ./

# Install dependencies
RUN uv pip install --system \
    pandas>=2.3.1 \
    pyarrow>=21.0.0 \
    sqlalchemy>=2.0.41 \
    psycopg2-binary>=2.9.10 \
    requests>=2.32.4

# Run the pipeline script
ENTRYPOINT ["python", "pipeline.py"]
