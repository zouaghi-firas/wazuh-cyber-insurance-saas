#!/bin/bash

# Wazuh Docker Services Backup Script
# This script creates backups of Wazuh data and configurations
# with proper error handling and verification

# Set variables
COMPOSE_FILE="docker-compose.yml"
BACKUP_BASE_DIR="/tmp/wazuh_backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE_DIR_$TIMESTAMP"
FINAL_ARCHIVE="$BACKUP_BASE_DIR_$TIMESTAMP.tar.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Creating Wazuh backup in $BACKUP_DIR..."

# Function to backup a container
backup_container() {
    local container_name=$1
    local data_path=$2
    local backup_name=$3

    echo "Backing up $container_name data..."

    # Check if container is running
    if ! docker ps | grep -q "$container_name"; then
        echo "WARNING: Container $container_name is not running. Skipping backup."
        return 1
    fi

    # Create backup inside container
    if ! docker exec "$container_name" tar czf "/tmp/$backup_name.tar.gz" "$data_path"; then
        echo "ERROR: Failed to create backup inside $container_name"
        return 1
    fi

    # Copy backup from container
    if ! docker cp "$container_name:/tmp/$backup_name.tar.gz" "$BACKUP_DIR/"; then
        echo "ERROR: Failed to copy backup from $container_name"
        return 1
    fi

    echo "SUCCESS: $container_name data backed up"
    return 0
}

# Backup OpenSearch data
backup_container "wazuh.indexer" "/usr/share/opensearch/data" "indexer_data"

# Backup Wazuh manager data
backup_container "wazuh.manager" "/var/ossec" "manager_data"

# Backup Dashboard data
backup_container "wazuh.dashboard" "/usr/share/wazuh-dashboard/data" "dashboard_data"

# Backup configuration files
echo "Backing up configuration files..."
if [ -d "../configs" ]; then
    if ! cp -r ../configs "$BACKUP_DIR/"; then
        echo "ERROR: Failed to backup configuration files"
    else
        echo "SUCCESS: Configuration files backed up"
    fi
else
    echo "WARNING: Configuration directory not found"
fi

# Create a compressed archive
echo "Creating compressed archive..."
cd "$(dirname "$BACKUP_DIR")"
if ! tar czf "$FINAL_ARCHIVE" "$(basename "$BACKUP_DIR")"; then
    echo "ERROR: Failed to create compressed archive"
    exit 1
fi

# Verify backup was created
if [ -f "$FINAL_ARCHIVE" ]; then
    BACKUP_SIZE=$(du -h "$FINAL_ARCHIVE" | cut -f1)
    echo "SUCCESS: Backup completed successfully!"
    echo "Backup location: $FINAL_ARCHIVE"
    echo "Backup size: $BACKUP_SIZE"
else
    echo "ERROR: Backup archive not found"
    exit 1
fi

# Clean up temporary directory
rm -rf "$BACKUP_DIR"

echo ""
echo "Backup process completed!"
echo "To restore this backup, use the restore.sh script with: $FINAL_ARCHIVE"
