#!/bin/bash

# Wazuh Docker Services Stop Script
# This script stops the Wazuh Manager, OpenSearch, and Dashboard services

echo "Stopping Wazuh services..."

# Stop all services
docker-compose down

echo "Wazuh services stopped successfully!"
