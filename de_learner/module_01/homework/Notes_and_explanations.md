# Homework Module 1

This homework is focused in the docker and pipeline setup and Docker.

## Question 1

### Requirements for docker

1. Docker image needs to start from python v 3.13.
2. Entrypoint needs to be Bash
3. Update Pip and check the version.

```docker
# Docker image that we will build on
FROM python:3.13

# Update pip and check the version
RUN pip install --upgrade pip && \
    pip --version

# Set the entrypoint to bash
ENTRYPOINT ["/bin/bash"]
```

After created the image and run the following lines:

```bash
cd <Navigate to the homework folder>

# Build the docker image:
docker build -t my-python-image .
# Run the image:
docker run -it my-python-image

pip -V # --version
```

The output at this moment is 25.3

## Question 2: Docker Compose and networking

```yaml
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: "postgres"
      POSTGRES_PASSWORD: "postgres"
      POSTGRES_DB: "ny_taxi"
    ports:
      - "5433:5432"
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```

To run the docker-compose:

```bash
docker-compose -f docker-compose.yaml up -d
```

The -d will run the docker-compose in detached mode, releasing the terminal for other processes and running docker in the background.

The up will show the logs in the terminal while building.

This will do the following:

### Postgres

1. PostgreSQL DB will run on por `5433` -> postgress container.
2. The database is ny_taxi
3. User and Password: `postgres/postgres`

### pgAdmin

1. Runs on port `8080` -> Cpgadmin container.
2. Email: `pgadmin@pgadmin.com`
3. Password: `pgadmin`

This will give you access to:

- PostgreSQL: `localhost:5433`
- pgAdmin web interface: `http://localhost:8080`

#### Question: What is the hostname and port that pgadmin should use to connect to the postgres database?

Answer: `postgres:5432`, Since containers in the same docker-compose communicate using names as hostnames.

5433 corresponds to the port in the host machine mapping to the port 5432 inside the container. Thus, pgAdmin container will needs to connect internally with `postgres:5432`.

### Data Ingestion

Before, we need to run the data ingestion script with typer. And in case the docker compose.

### Steps to Ingest NYC Taxi Data into PostgreSQL

#### 1. Start Docker Containers

Navigate to the homework directory and start PostgreSQL and pgAdmin containers:

```bash
cd de_learner/module_01/homework
docker-compose up -d
```

This starts:

- **PostgreSQL container**: Maps port 5433 (host) → 5432 (container)

- **pgAdmin container**: Available at <http://localhost:8080>

#### 2. Verify Containers Are Running

```bash
docker ps | grep -E "(postgres|pgadmin)"
```

You should see both `postgres` and `pgadmin` containers running.

#### 3. Run the Data Ingestion Script

The `homework_taxi.py` script downloads Parquet data and loads it into PostgreSQL:

```bash
uv run homework_taxi.py \
  --url "https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet" \
  --user postgres \
  --password postgres \
  --host localhost \
  --port 5433 \
  --db ny_taxi \
  --table_name green_taxi_data
```

**Important connection parameters:**

- Use `--port 5433` when connecting from the host machine (WSL/local)

- Use `--port 5432` when connecting from inside Docker containers

#### 4. Verify Data Was Loaded

Check row count:

```bash
docker exec postgres psql -U postgres -d ny_taxi -c "SELECT COUNT(*) FROM green_taxi_data;"
```

View sample data:

```bash
docker exec postgres psql -U postgres -d ny_taxi -c "SELECT * FROM green_taxi_data LIMIT 3;"
```

### What the Script Does

1. **Downloads** the Parquet file from the provided URL
2. **Validates** the file format (must be .parquet)
3. **Creates** a PostgreSQL connection using SQLAlchemy
4. **Chunks** the data into manageable pieces (default: 100,000 rows)
5. **Inserts** each chunk into the database with retry logic
6. **Logs** progress throughout the process

### Key Features

- **Retry logic**: Automatically retries on transient failures (network, database)

- **Memory efficient**: Processes data in chunks to avoid loading entire file into memory

- **Error handling**: Comprehensive error handling with detailed logging

- **Streaming download**: Downloads large files efficiently using streaming

### Result

Successfully ingested **46,912 rows** of NYC green taxi trip data for November 2025 into the `green_taxi_data` table.

## Question 3: Count trips with distance <= 1 mile in November 2025

**Question:** For the trips in November 2025 (lpep_pickup_datetime between '2025-11-01' and '2025-12-01', exclusive of the upper bound), how many trips had a trip_distance of less than or equal to 1 mile?

```sql
SELECT COUNT(*) as trip_count
FROM green_taxi_data
WHERE lpep_pickup_datetime >= '2025-11-01'
  AND lpep_pickup_datetime < '2025-12-01'
  AND trip_distance <= 1;
```

**Running the query:**

```bash
docker exec postgres psql -U postgres -d ny_taxi -c "SELECT COUNT(*) as trip_count FROM green_taxi_data WHERE lpep_pickup_datetime >= '2025-11-01' AND lpep_pickup_datetime < '2025-12-01' AND trip_distance <= 1;"
```

**Answer:** **8,007 trips**

## Query 4: Pickup day with the longest trip distance in november

**Question:** Which was the pickup day with the longest trip distance? Only consider trips with trip_distance less than 100 miles (to exclude data errors). Use the pickup time for your calculations. Only consider November 2025.

```sql
SELECT
    DATE(lpep_pickup_datetime) as pickup_day,
    MAX(trip_distance) as longest_trip
FROM green_taxi_data
WHERE trip_distance < 100
  AND lpep_pickup_datetime >= '2025-11-01'
  AND lpep_pickup_datetime < '2025-12-01'
GROUP BY DATE(lpep_pickup_datetime)
ORDER BY longest_trip DESC
LIMIT 1;
```

**Running the query:**

```bash
docker exec postgres psql -U postgres -d ny_taxi -c "
SELECT
    DATE(lpep_pickup_datetime) as pickup_day,
    MAX(trip_distance) as longest_trip
FROM green_taxi_data
WHERE trip_distance < 100
  AND lpep_pickup_datetime >= '2025-11-01'
  AND lpep_pickup_datetime < '2025-12-01'
GROUP BY DATE(lpep_pickup_datetime)
ORDER BY longest_trip DESC
LIMIT 1;"
```

**Answer:** **November 14, 2025** with a trip distance of **88.03 miles**

**Top 5 days with longest trips:**

| Pickup Day | Longest Trip | Total Trips |
| ---------- | ------------ | ----------- |
| 2025-11-14 | 88.03 miles  | 1,726       |
| 2025-11-20 | 73.84 miles  | 1,931       |
| 2025-11-23 | 45.26 miles  | 1,280       |
| 2025-11-22 | 40.16 miles  | 1,329       |
| 2025-11-15 | 39.81 miles  | 1,431       |

## Question 5. Which was the pickup zone with the largest total_amount (sum of all trips) on November 18th, 2025?

### Prerequisites: Load Taxi Zones Data

First, we need to load the taxi zone lookup table into the database. The script now supports CSV files:

```bash
uv run homework_taxi.py \
  --url "https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv" \
  --user postgres \
  --password postgres \
  --host localhost \
  --port 5433 \
  --db ny_taxi \
  --table_name taxi_zones
```

This creates a `taxi_zones` table with 265 rows containing:

- `LocationID`: Zone identifier (matches `PULocationID`/`DOLocationID` in trip data)
- `Borough`: Borough name

- `Zone`: Zone name

- `service_zone`: Service zone classification

### Query

```sql
SELECT
    z."Zone" as pickup_zone,
    SUM(g.total_amount) as total_revenue
FROM green_taxi_data g
JOIN taxi_zones z ON g."PULocationID" = z."LocationID"
WHERE DATE(g.lpep_pickup_datetime) = '2025-11-18'
GROUP BY z."Zone"
ORDER BY total_revenue DESC
LIMIT 5;
```

**Running the query:**

```bash
docker exec postgres psql -U postgres -d ny_taxi -c "
SELECT
    z.\"Zone\" as pickup_zone,
    SUM(g.total_amount) as total_revenue
FROM green_taxi_data g
JOIN taxi_zones z ON g.\"PULocationID\" = z.\"LocationID\"
WHERE DATE(g.lpep_pickup_datetime) = '2025-11-18'
GROUP BY z.\"Zone\"
ORDER BY total_revenue DESC
LIMIT 5;"
```

**Answer:** **East Harlem North** with a total revenue of **$9,281.92**

**Top 5 pickup zones by revenue on November 18, 2025:**

| Pickup Zone              | Total Revenue |
| ------------------------ | ------------- |
| East Harlem North        | $9,281.92     |
| East Harlem South        | $6,696.13     |
| Central Park             | $2,378.79     |
| Washington Heights South | $2,139.05     |
| Morningside Heights      | $2,100.59     |

## Question 6. For the passengers picked up in "East Harlem North" in November 2025, which was the drop off zone that had the largest tip?

**Question:** For passengers picked up in the zone named "East Harlem North" in November 2025, which was the drop off zone that had the largest tip?

### Query

```sql
SELECT
    do_zone."Zone" as dropoff_zone,
    MAX(g.tip_amount) as largest_tip
FROM green_taxi_data g
JOIN taxi_zones pu_zone ON g."PULocationID" = pu_zone."LocationID"
JOIN taxi_zones do_zone ON g."DOLocationID" = do_zone."LocationID"
WHERE pu_zone."Zone" = 'East Harlem North'
  AND g.lpep_pickup_datetime >= '2025-11-01'
  AND g.lpep_pickup_datetime < '2025-12-01'
GROUP BY do_zone."Zone"
ORDER BY largest_tip DESC
LIMIT 5;
```

**Running the query:**

```bash
docker exec postgres psql -U postgres -d ny_taxi -c "
SELECT
    do_zone.\"Zone\" as dropoff_zone,
    MAX(g.tip_amount) as largest_tip
FROM green_taxi_data g
JOIN taxi_zones pu_zone ON g.\"PULocationID\" = pu_zone.\"LocationID\"
JOIN taxi_zones do_zone ON g.\"DOLocationID\" = do_zone.\"LocationID\"
WHERE pu_zone.\"Zone\" = 'East Harlem North'
  AND g.lpep_pickup_datetime >= '2025-11-01'
  AND g.lpep_pickup_datetime < '2025-12-01'
GROUP BY do_zone.\"Zone\"
ORDER BY largest_tip DESC
LIMIT 5;"
```

**Answer:** **Yorkville West** with a tip of **$81.89**

**Trip details:**

- Pickup: East Harlem North on November 30, 2025 at 4:30 PM
- Distance: 2.63 miles
- Fare: $14.20
- Tip: $81.89 (577% tip!)
- Total: $100.34

**Top 5 drop-off zones by largest tip:**

| Drop-off Zone                 | Largest Tip |
| ----------------------------- | ----------- |
| Yorkville West                | $81.89      |
| LaGuardia Airport             | $50.00      |
| East Harlem North             | $45.00      |
| Long Island City/Queens Plaza | $34.25      |
| Unknown Zone                  | $28.90      |

## Question 7. Terraform Workflow

**Question:** Which of the following sequences, respectively, describes the workflow for:

1. Downloading the provider plugins and setting up backend
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform

### Answer: Option 4

**Correct sequence:** `terraform init`, `terraform apply -auto-approve`, `terraform destroy`

### Explanation

1. **`terraform init`** - Initializes a Terraform working directory
   - Downloads provider plugins specified in configuration
   - Sets up the backend for storing state
   - Prepares the working directory for other Terraform commands

2. **`terraform apply -auto-approve`** - Applies changes to infrastructure
   - Generates an execution plan showing what will be created/modified/destroyed
   - The `-auto-approve` flag skips the interactive approval prompt
   - Auto-executes the plan without requiring manual confirmation

3. **`terraform destroy`** - Destroys all managed infrastructure
   - Removes all resources defined in the Terraform configuration
   - Prompts for confirmation (unless `-auto-approve` is used)
   - Cleans up all infrastructure managed by Terraform

