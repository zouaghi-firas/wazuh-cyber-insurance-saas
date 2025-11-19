#!/bin/bash

# Wazuh Docker Services Start Script
# This script starts the Wazuh Manager, OpenSearch, and Dashboard services

echo "Starting Wazuh services with Docker Compose..."

# Start all services
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Check if services are running
echo "Checking service status..."
docker-compose ps

# Display access information
echo ""
echo "Services started successfully!"
echo "Wazuh API: https://192.168.56.10:55000"
echo "OpenSearch Dashboard: https://192.168.56.10:5601"
echo ""
echo "Default credentials:"
echo "  OpenSearch: admin / SecretPassword"
echo "  Wazuh API: wazuh / wazuh"
echo ""
echo "Note: It may take a few more minutes for all services to fully initialize."
