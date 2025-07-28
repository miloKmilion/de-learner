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