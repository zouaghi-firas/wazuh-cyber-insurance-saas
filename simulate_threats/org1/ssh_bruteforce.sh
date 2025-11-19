#!/bin/bash

# SSH Brute-Force Simulation Script for org-1
# This script simulates SSH brute-force attacks to trigger detection

echo "=== SSH Brute-Force Simulation for org-1 ==="
echo "Simulating SSH brute-force attacks..."

# Target host (local SSH server)
TARGET="localhost"

# List of common passwords to try
PASSWORDS=("password" "123456" "admin" "root" "test" "guest" "user" "qwerty")

# User to brute-force
USERNAME="testuser"

echo "Starting SSH brute-force simulation against $USERNAME@$TARGET"
echo "This will generate multiple failed login attempts to trigger rule ID 100002."

# Attempt to login with each password (will fail)
for password in "${PASSWORDS[@]}"; do
    echo "Trying password: $password"
    # Use hydra to simulate brute-force attempts (will fail)
    hydra -l $USERNAME -p $password ssh://$TARGET -V -t 1 -w 1 -o /tmp/hydra_output.log 2>&1 | head -n 10
    sleep 1
done

# Alternative method without hydra (in case hydra is not available)
echo "Trying alternative method with ssh command..."
for password in "${PASSWORDS[@]}"; do
    echo "Attempting SSH login with password: $password"
    timeout 2 ssh -o BatchMode=yes -o ConnectTimeout=1 -o StrictHostKeyChecking=no $USERNAME@$TARGET "echo 'login successful'" 2>&1 || true
done

echo "SSH brute-force simulation complete."
echo "Failed login attempts have been logged to /var/log/auth.log"
echo "Check the Wazuh dashboard for alerts (rule ID: 100002)."

# Show the last few lines of auth log to confirm attempts
echo ""
echo "Recent authentication failures:"
tail -n 10 /var/log/auth.log | grep "authentication failure"
