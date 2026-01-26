#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}NYC Taxi Data - Homework Answers${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if PostgreSQL container is running
if ! docker ps | grep -q postgres; then
    echo -e "${YELLOW}PostgreSQL container is not running. Starting docker-compose...${NC}"
    docker-compose up -d

    # Wait for PostgreSQL to be ready
    echo "Waiting for PostgreSQL to be ready..."

    # Check if containers started successfully
    if ! docker ps | grep -q postgres; then
        echo -e "${YELLOW}Error: Failed to start containers!${NC}"
        echo "Please check docker-compose configuration."
        exit 1
    fi

    # Wait for PostgreSQL to accept connections
    MAX_RETRIES=30
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if docker exec postgres pg_isready -U postgres >/dev/null 2>&1; then
            echo -e "${GREEN}PostgreSQL is ready!${NC}"
            break
        fi
        echo -n "."
        sleep 1
        RETRY_COUNT=$((RETRY_COUNT + 1))
    done
    echo ""

    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo -e "${YELLOW}Timeout waiting for PostgreSQL to be ready!${NC}"
        exit 1
    fi

    echo -e "${GREEN}Containers started successfully!${NC}"
    echo ""
else
    echo -e "${GREEN}PostgreSQL container is already running.${NC}"
    echo ""
fi

# Question 1: Docker - pip version
echo -e "${GREEN}Question 1: Docker Setup${NC}"
echo "What is pip version in the python:3.13 image?"
echo -e "${YELLOW}Answer: 25.3${NC}"
echo "To verify: docker run -it python:3.13 pip --version"
echo ""

# Question 2: Docker Compose networking
echo -e "${GREEN}Question 2: Docker Compose Networking${NC}"
echo "What is the hostname and port that pgadmin should use to connect to postgres?"
echo -e "${YELLOW}Answer: postgres:5432${NC}"
echo "Explanation: Containers in the same docker-compose network communicate using service names."
echo ""

# Question 3: Trips with distance <= 1 mile
echo -e "${GREEN}Question 3: Short Trips (Distance <= 1 mile)${NC}"
echo "How many trips had a trip_distance of <= 1 mile in November 2025?"
ANSWER_Q3=$(docker exec postgres psql -U postgres -d ny_taxi -t -c "
SELECT COUNT(*)
FROM green_taxi_data
WHERE lpep_pickup_datetime >= '2025-11-01'
  AND lpep_pickup_datetime < '2025-12-01'
  AND trip_distance <= 1;
" | xargs)
echo -e "${YELLOW}Answer: $ANSWER_Q3 trips${NC}"
echo ""

# Question 4: Pickup day with longest trip distance
echo -e "${GREEN}Question 4: Longest Trip Day${NC}"
echo "Which pickup day had the longest trip distance (< 100 miles)?"
ANSWER_Q4=$(docker exec postgres psql -U postgres -d ny_taxi -t -c "
SELECT
    TO_CHAR(DATE(lpep_pickup_datetime), 'YYYY-MM-DD') as pickup_day,
    ROUND(MAX(trip_distance)::numeric, 2) as longest_trip
FROM green_taxi_data
WHERE trip_distance < 100
  AND lpep_pickup_datetime >= '2025-11-01'
  AND lpep_pickup_datetime < '2025-12-01'
GROUP BY DATE(lpep_pickup_datetime)
ORDER BY longest_trip DESC
LIMIT 1;
" | xargs)
echo -e "${YELLOW}Answer: $ANSWER_Q4${NC}"
echo ""

# Question 5: Pickup zone with largest total_amount on Nov 18
echo -e "${GREEN}Question 5: Highest Revenue Pickup Zone (Nov 18)${NC}"
echo "Which pickup zone had the largest total_amount on November 18, 2025?"
ANSWER_Q5=$(docker exec postgres psql -U postgres -d ny_taxi -t -c "
SELECT
    z.\"Zone\" as pickup_zone,
    TO_CHAR(SUM(g.total_amount), 'FM\$9,999,990.00') as total_revenue
FROM green_taxi_data g
JOIN taxi_zones z ON g.\"PULocationID\" = z.\"LocationID\"
WHERE DATE(g.lpep_pickup_datetime) = '2025-11-18'
GROUP BY z.\"Zone\"
ORDER BY SUM(g.total_amount) DESC
LIMIT 1;
" | xargs)
echo -e "${YELLOW}Answer: $ANSWER_Q5${NC}"
echo ""

# Question 6: Drop-off zone with largest tip from East Harlem North
echo -e "${GREEN}Question 6: Largest Tip Drop-off Zone${NC}"
echo "For pickups in East Harlem North, which drop-off zone had the largest tip?"
ANSWER_Q6=$(docker exec postgres psql -U postgres -d ny_taxi -t -c "
SELECT
    do_zone.\"Zone\" as dropoff_zone,
    TO_CHAR(MAX(g.tip_amount), 'FM\$9,990.00') as largest_tip
FROM green_taxi_data g
JOIN taxi_zones pu_zone ON g.\"PULocationID\" = pu_zone.\"LocationID\"
JOIN taxi_zones do_zone ON g.\"DOLocationID\" = do_zone.\"LocationID\"
WHERE pu_zone.\"Zone\" = 'East Harlem North'
  AND g.lpep_pickup_datetime >= '2025-11-01'
  AND g.lpep_pickup_datetime < '2025-12-01'
GROUP BY do_zone.\"Zone\"
ORDER BY MAX(g.tip_amount) DESC
LIMIT 1;
" | xargs)
echo -e "${YELLOW}Answer: $ANSWER_Q6${NC}"
echo ""

# Question 7: Terraform workflow
echo -e "${GREEN}Question 7: Terraform Workflow${NC}"
echo "Which sequence describes: init, apply with auto-approve, destroy?"
echo -e "${YELLOW}Answer: terraform init, terraform apply -auto-approve, terraform destroy${NC}"
echo ""

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Homework Complete!${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Shutdown containers
echo -e "${YELLOW}Shutting down Docker containers...${NC}"
docker-compose down
echo -e "${GREEN}Containers stopped and removed.${NC}"
