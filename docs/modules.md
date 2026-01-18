# de-learner Modules

This section provides comprehensive documentation for all modules in the de-learner project.

## Module 01: Data Engineering Fundamentals

Module 01 covers the foundational concepts and practical implementations of data engineering workflows.

### Topics Covered

#### 1. Docker Basics

Learn containerization fundamentals, Docker commands, and best practices for creating isolated development environments.

**Documentation**: See [1_docker_basics.md](../de_learner/module_01/1_docker_basics.md)

#### 2. Infrastructure as Code with Terraform

Understand how to provision and manage cloud infrastructure using Terraform on AWS, including S3 data lakes and Athena databases.

**Documentation**: See [terraform.md](../de_learner/module_01/1_terraform/terraform.md)

**Configuration Files**:

- [main.tf](../de_learner/module_01/1_terraform/main.tf) - AWS resource definitions
- [variables.tf](../de_learner/module_01/1_terraform/variables.tf) - Configurable parameters

#### 3. Data Ingestion with Docker & PostgreSQL

Build data ingestion pipelines that load data into PostgreSQL using Docker Compose for orchestration.

**Key Components**:

- [ingest_data.py](../de_learner/module_01/2_docker_sql/ingest_data.py) - Parquet to PostgreSQL ingestion script
- [pipeline.py](../de_learner/module_01/2_docker_sql/pipeline.py) - Data pipeline template
- [docker-compose.yaml](../de_learner/module_01/2_docker_sql/docker-compose.yaml) - Service orchestration

### Learning Path

1. Start with Docker basics to understand containerization
2. Move to Terraform to learn infrastructure provisioning
3. Apply both concepts in the data ingestion pipeline example

### Prerequisites

- Python 3.12+
- Docker & Docker Compose
- Terraform CLI
- AWS account (for Terraform examples)

## API Reference

::: de_learner.module_01
