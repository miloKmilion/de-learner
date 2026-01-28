# de-learner

[![Build status](https://img.shields.io/github/actions/workflow/status/miloKmilion/de-learner/main.yml?branch=main)](https://github.com/miloKmilion/de-learner/actions/workflows/main.yml?query=branch%3Amain)
[![Commit activity](https://img.shields.io/github/commit-activity/m/miloKmilion/de-learner)](https://img.shields.io/github/commit-activity/m/miloKmilion/de-learner)
[![License](https://img.shields.io/github/license/miloKmilion/de-learner)](https://img.shields.io/github/license/miloKmilion/de-learner)

A hands-on Data Engineering learning repository featuring practical exercises, real-world data pipelines, and infrastructure-as-code implementations.

- **Github repository**: <https://github.com/miloKmilion/de-learner/>
- **Documentation** <https://miloKmilion.github.io/de-learner/>

## What You'll Learn

This repository contains modular learning content covering essential Data Engineering concepts and tools:

### Module 01: Data Engineering Fundamentals

#### 1. Docker Basics

- Container fundamentals and why Docker matters for DE
- Writing Dockerfiles and building images
- Docker Compose for multi-container orchestration
- Integration with modern Python tooling (UV package manager)

#### 2. Infrastructure as Code with Terraform

- IaC fundamentals and workflow (init, plan, apply, destroy)
- AWS cloud infrastructure provisioning
- S3 buckets, versioning, and lifecycle rules
- Athena database setup for querying data lakes
- Service account management and security best practices

#### 3. Data Ingestion Pipelines

- Building production-grade data ingestion scripts
- PostgreSQL database setup with Docker
- Batch processing and chunking strategies
- SQLAlchemy for database connectivity
- Working with Parquet and CSV formats
- Retry logic and error handling

#### Homework: NYC Taxi Data Analysis

Complete hands-on exercises using real NYC taxi trip data:

- Data ingestion from remote sources
- SQL queries for analytics (trip analysis, revenue calculations, zone lookups)
- Multi-table joins and aggregations
- Automated pipeline execution with bash scripts

## Technologies & Tools

- **Languages**: Python 3.12+, SQL, HCL (Terraform), Bash
- **Containerization**: Docker, Docker Compose
- **Infrastructure**: Terraform, AWS (S3, Athena, IAM)
- **Databases**: PostgreSQL, pgAdmin, pgCLI
- **Data Processing**: pandas, PyArrow, SQLAlchemy
- **Package Management**: UV
- **Development**: pytest, ruff, mypy, pre-commit hooks

## Getting Started

### Prerequisites

- Python 3.12 or higher
- Docker and Docker Compose
- UV package manager
- Make (optional, for convenience commands)

### Setup Development Environment

1. Clone the repository:

```bash
git clone https://github.com/miloKmilion/de-learner.git
cd de-learner
```

1. Install dependencies and pre-commit hooks:
```bash
make install
```

This will set up your virtual environment, install all dependencies, and configure pre-commit hooks for code quality.

### Running Module 01

#### Docker Basics

Follow along with [1_docker_basics.md](de_learner/module_01/1_docker_basics.md) to learn container fundamentals.

#### Terraform

See [terraform.md](de_learner/module_01/1_terraform/terraform.md) for IaC setup and AWS provisioning.

#### Data Ingestion

Work through [2_ingesting_data.md](de_learner/module_01/2_ingesting_data.md) and run:

```bash
cd de_learner/module_01/2_docker_sql
docker-compose up -d
python ingest_data.py
```

#### Homework

Run the complete Module 01 homework automatically:

```bash
cd de_learner/module_01/homework
./run_homework.sh
```

Or run individual questions manually after starting the Docker services.

## Project Structure

```text
de-learner/
├── de_learner/
│   └── module_01/           # Module 01: Data Engineering Fundamentals
│       ├── 1_docker_basics.md
│       ├── 1_terraform/     # Terraform configurations and docs
│       ├── 2_docker_sql/    # Data ingestion pipeline
│       └── homework/        # NYC taxi data analysis exercises
├── tests/                   # Unit tests
├── docs/                    # MkDocs documentation
└── pyproject.toml          # Project configuration and dependencies
```

## Development Commands

```bash
make install    # Install dependencies and pre-commit hooks
make check      # Run code quality checks (ruff, mypy)
make test       # Run tests with coverage
make docs       # Build and serve documentation locally
```

## Contributing

This is a personal learning repository, but feel free to:

- Open issues for questions or suggestions
- Submit PRs for fixes or improvements
- Fork the repo for your own learning journey

## Resources & Attribution

- Repository structure based on [shaneholloman/uvi](https://github.com/shaneholloman/uvi)
- NYC taxi data from [NYC Taxi & Limousine Commission](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
