#!/bin/bash

# Wazuh Docker Services Start Script
# This script starts Wazuh Manager, OpenSearch, and Dashboard services
# with health checks and proper error handling

# Set variables
COMPOSE_FILE="docker-compose.yml"
MAX_RETRIES=3
RETRY_DELAY=30
API_URL="https://192.168.56.10:55000"
DASHBOARD_URL="https://192.168.56.10:5601"

echo "Starting Wazuh services with Docker Compose..."

# Check if docker-compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "ERROR: Docker Compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Start all services with error handling
echo "Starting services..."
if ! docker-compose -f "$COMPOSE_FILE" up -d; then
    echo "ERROR: Failed to start services"
    exit 1
fi

# Wait for services to be ready with health checks
echo "Waiting for services to be ready..."
for i in $(seq 1 $MAX_RETRIES); do
    echo "Health check attempt $i/$MAX_RETRIES..."

    # Check if Wazuh Manager is responding
    if curl -s --connect-timeout 5 "$API_URL" > /dev/null 2>&1; then
        echo "SUCCESS: Wazuh Manager is responding"
        MANAGER_READY=true
    else
        echo "WARNING: Wazuh Manager not yet responding"
        MANAGER_READY=false
    fi

    # Check if OpenSearch Dashboard is responding
    if curl -s --connect-timeout 5 "$DASHBOARD_URL" > /dev/null 2>&1; then
        echo "SUCCESS: OpenSearch Dashboard is responding"
        DASHBOARD_READY=true
    else
        echo "WARNING: OpenSearch Dashboard not yet responding"
        DASHBOARD_READY=false
    fi

    # If both services are ready, break the loop
    if [ "$MANAGER_READY" = true ] && [ "$DASHBOARD_READY" = true ]; then
        echo "All services are ready!"
        break
    fi

    # If not the last attempt, wait before retrying
    if [ $i -lt $MAX_RETRIES ]; then
        echo "Waiting $RETRY_DELAY seconds before next health check..."
        sleep $RETRY_DELAY
    fi
done

# Check if services are running
echo ""
echo "Checking service status..."
docker-compose -f "$COMPOSE_FILE" ps

# Display access information
echo ""
if [ "$MANAGER_READY" = true ] && [ "$DASHBOARD_READY" = true ]; then
    echo "Services started successfully!"
    echo "Wazuh API: $API_URL"
    echo "OpenSearch Dashboard: $DASHBOARD_URL"
    echo ""
    echo "Default credentials:"
    echo "  OpenSearch: admin / SecretPassword"
    echo "  Wazuh API: wazuh / wazuh"
    echo ""
    echo "Note: All services are fully initialized and ready to use."
else
    echo "WARNING: Services may not be fully ready. Please check manually."
    echo "You can access services at:"
    echo "  Wazuh API: $API_URL"
    echo "  OpenSearch Dashboard: $DASHBOARD_URL"
    echo ""
    echo "To check service status manually, run: docker-compose -f $COMPOSE_FILE ps"
    echo "To view logs, run: docker-compose -f $COMPOSE_FILE logs [service_name]"
fi
