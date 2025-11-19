#!/bin/bash

# Privilege Escalation Simulation Script for org-2
# This script simulates privilege escalation attempts to trigger detection

echo "=== Privilege Escalation Simulation for org-2 ==="
echo "Simulating privilege escalation attempts..."

# Switch to testuser to simulate a non-privileged user
echo "Switching to testuser for privilege escalation simulation..."
su - testuser -c "
echo 'Attempting privilege escalation as testuser...'

# Attempt to use sudo with a wrong password (will fail)
echo 'Attempting sudo with wrong password...'
echo 'wrongpassword' | sudo -S whoami 2>&1 | head -n 5

# Attempt to switch to root using su (will fail)
echo 'Attempting to switch to root using su...'
echo 'wrongpassword' | su - root -c 'whoami' 2>&1 | head -n 5

# Attempt to read a shadow file (will fail)
echo 'Attempting to read /etc/shadow...'
cat /etc/shadow 2>&1 | head -n 5

# Attempt to modify a system file (will fail)
echo 'Attempting to modify /etc/hosts...'
echo '192.168.1.100 attacker.com' >> /etc/hosts 2>&1 | head -n 5

echo 'Privilege escalation attempts completed.'
"

echo "Privilege escalation simulation complete."
echo "Failed attempts have been logged to /var/log/auth.log"
echo "Check the Wazuh dashboard for alerts (rule ID: 100003)."

# Show the last few lines of auth log to confirm attempts
echo ""
echo "Recent privilege escalation attempts:"
tail -n 10 /var/log/auth.log | grep -E "sudo|su:" | tail -n 5
