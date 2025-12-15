#!/bin/bash

# Script to run integration tests against Flowable REST API container
# Usage: ./run_tests.sh [options]
#
# Options:
#   --start     Start the Flowable container before tests
#   --stop      Stop the Flowable container after tests
#   --unit      Run only unit tests (with WebMock)
#   --integration Run only integration tests (against real API)
#   --all       Run both unit and integration tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

START_CONTAINER=false
STOP_CONTAINER=false
RUN_UNIT=false
RUN_INTEGRATION=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --start)
            START_CONTAINER=true
            ;;
        --stop)
            STOP_CONTAINER=true
            ;;
        --unit)
            RUN_UNIT=true
            ;;
        --integration)
            RUN_INTEGRATION=true
            ;;
        --all)
            RUN_UNIT=true
            RUN_INTEGRATION=true
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

# Default to integration tests if nothing specified
if [ "$RUN_UNIT" = false ] && [ "$RUN_INTEGRATION" = false ]; then
    RUN_INTEGRATION=true
fi

# Function to wait for Flowable to be ready
wait_for_flowable() {
    echo -e "${YELLOW}Waiting for Flowable REST API to be ready...${NC}"
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://localhost:8080/flowable-rest/actuator/health" > /dev/null 2>&1; then
            echo -e "${GREEN}Flowable REST API is ready!${NC}"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts - waiting..."
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}Flowable REST API did not become ready in time${NC}"
    return 1
}

# Start container if requested
if [ "$START_CONTAINER" = true ]; then
    echo -e "${YELLOW}Starting Flowable REST API container...${NC}"
    docker-compose up -d
    wait_for_flowable
fi

# Run unit tests
if [ "$RUN_UNIT" = true ]; then
    echo -e "${YELLOW}Running unit tests...${NC}"
    bundle exec ruby test/all_tests.rb
    echo -e "${GREEN}Unit tests completed!${NC}"
fi

# Run integration tests
if [ "$RUN_INTEGRATION" = true ]; then
    echo -e "${YELLOW}Running integration tests against Flowable REST API...${NC}"
    
    # Check if Flowable is available
    if ! curl -s -f "http://localhost:8080/flowable-rest/actuator/health" > /dev/null 2>&1; then
        echo -e "${RED}Flowable REST API is not available at localhost:8080${NC}"
        echo "Start the container with: docker-compose up -d"
        echo "Or run tests with: ./run_tests.sh --start --integration"
        exit 1
    fi
    
    bundle exec ruby test/integration/run_all.rb
    echo -e "${GREEN}Integration tests completed!${NC}"
fi

# Stop container if requested
if [ "$STOP_CONTAINER" = true ]; then
    echo -e "${YELLOW}Stopping Flowable REST API container...${NC}"
    docker-compose down
    echo -e "${GREEN}Container stopped.${NC}"
fi

echo -e "${GREEN}All tests completed successfully!${NC}"
# 2025-10-02T07:31:12Z - Add multipart upload support
# 2025-10-27T10:59:41Z - Refactor deploy methods to share code
# 2025-11-14T14:57:57Z - Migrate DSL examples into README
# 2025-10-06T09:14:20Z - Add multipart upload support
# 2025-10-28T11:47:11Z - Refactor deploy methods to share code
# 2025-11-21T12:55:40Z - Migrate DSL examples into README
