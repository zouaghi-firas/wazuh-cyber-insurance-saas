#!/bin/bash

# EICAR Ransomware Simulation Script for org-1
# This script creates an EICAR test file to simulate ransomware detection

echo "=== EICAR Ransomware Simulation for org-1 ==="
echo "Creating EICAR test file to trigger ransomware detection..."

# Create a directory for the test
mkdir -p /tmp/eicar_test
cd /tmp/eicar_test

# Create the EICAR test file
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > eicar.txt

echo "EICAR test file created: /tmp/eicar_test/eicar.txt"
echo "This file should be detected by Wazuh as a potential ransomware test."

# Create a copy with a different name to simulate more files
cp eicar.txt eicar_copy.txt

echo "Created additional EICAR test file: /tmp/eicar_test/eicar_copy.txt"

# List the created files
ls -la /tmp/eicar_test/

echo "EICAR ransomware simulation complete."
echo "Check the Wazuh dashboard for alerts (rule ID: 100001)."
