#!/bin/bash

# Wazuh Docker Services Stop Script
# This script stops the Wazuh Manager, OpenSearch, and Dashboard services
# with proper error handling and confirmation

# Set variables
COMPOSE_FILE="docker-compose.yml"
TIMEOUT=30

echo "Stopping Wazuh services..."

# Check if docker-compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "ERROR: Docker Compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Stop all services with timeout
echo "Attempting to stop services (timeout: ${TIMEOUT}s)..."
if timeout $TIMEOUT docker-compose -f "$COMPOSE_FILE" down; then
    echo "SUCCESS: All services stopped gracefully"
else
    echo "WARNING: Services did not stop gracefully within timeout"
    echo "Forcing services to stop..."
    docker-compose -f "$COMPOSE_FILE" down --remove-orphans
    if [ $? -eq 0 ]; then
        echo "SUCCESS: All services stopped after force"
    else
        echo "ERROR: Failed to stop services completely"
        echo "You may need to manually remove containers with: docker rm -f \$(docker ps -aq)"
        exit 1
    fi
fi

# Check if any containers are still running
echo ""
echo "Checking for remaining containers..."
REMAINING=$(docker ps -q --filter "label=com.docker.compose.project" | wc -l)
if [ "$REMAINING" -gt 0 ]; then
    echo "WARNING: $REMAINING containers are still running"
    echo "To view remaining containers: docker ps -a"
else
    echo "SUCCESS: No containers are running"
fi

echo ""
echo "Wazuh services stop process completed!"
