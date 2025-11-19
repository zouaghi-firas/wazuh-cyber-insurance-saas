#!/bin/bash

# Wazuh Docker Services Backup Script
# This script creates backups of Wazuh data and configurations

BACKUP_DIR="/tmp/wazuh_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

echo "Creating Wazuh backup in $BACKUP_DIR..."

# Backup OpenSearch data
echo "Backing up OpenSearch data..."
docker exec wazuh.indexer tar czf /tmp/indexer_data.tar.gz /usr/share/opensearch/data
docker cp wazuh.indexer:/tmp/indexer_data.tar.gz $BACKUP_DIR/

# Backup Wazuh manager data
echo "Backing up Wazuh manager data..."
docker exec wazuh.manager tar czf /tmp/manager_data.tar.gz /var/ossec
docker cp wazuh.manager:/tmp/manager_data.tar.gz $BACKUP_DIR/

# Backup Dashboard data
echo "Backing up Dashboard data..."
docker exec wazuh.dashboard tar czf /tmp/dashboard_data.tar.gz /usr/share/wazuh-dashboard/data
docker cp wazuh.dashboard:/tmp/dashboard_data.tar.gz $BACKUP_DIR/

# Backup configuration files
echo "Backing up configuration files..."
cp -r ../configs $BACKUP_DIR/

# Create a compressed archive
echo "Creating compressed archive..."
cd /tmp
tar czf wazuh_backup_$(date +%Y%m%d_%H%M%S).tar.gz $BACKUP_DIR

echo "Backup completed successfully!"
echo "Backup location: /tmp/wazuh_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
