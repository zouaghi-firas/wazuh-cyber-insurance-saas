#!/bin/bash

# EICAR Ransomware Simulation Script for org-1
# This script creates an EICAR test file to simulate ransomware detection
# EICAR is a standard test file that should be detected by all antivirus systems

# Set variables
SCRIPT_NAME="EICAR Ransomware Simulation"
ORG_ID="org-1"
TEST_DIR="/tmp/eicar_test"
RULE_ID="100001"

# Print script header
echo "=== $SCRIPT_NAME for $ORG_ID ==="
echo "Creating EICAR test file to trigger ransomware detection..."

# Create a directory for test if it doesn't exist
if [ ! -d "$TEST_DIR" ]; then
    mkdir -p "$TEST_DIR"
    echo "Created test directory: $TEST_DIR"
fi
cd "$TEST_DIR"

# Create EICAR test file
# This is the standard EICAR test string that should be detected by antivirus systems
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > eicar.txt

echo "EICAR test file created: $TEST_DIR/eicar.txt"
echo "This file should be detected by Wazuh as a potential ransomware test."

# Create a copy with a different name to simulate more files
cp eicar.txt eicar_copy.txt

echo "Created additional EICAR test file: $TEST_DIR/eicar_copy.txt"

# Create a subdirectory with more test files to simulate ransomware spread
mkdir -p "$TEST_DIR/encrypted_files"
cp eicar.txt "$TEST_DIR/encrypted_files/important_document.txt.enc"
cp eicar.txt "$TEST_DIR/encrypted_files/financial_data.csv.enc"

echo "Created encrypted files in subdirectory to simulate ransomware activity"

# List created files
echo "Files created:"
ls -la "$TEST_DIR/"

# Create a ransom note (simulating ransomware behavior)
echo "YOUR FILES HAVE BEEN ENCRYPTED! Send 1 Bitcoin to decrypt." > "$TEST_DIR/README_DECRYPT.txt"
echo "Created fake ransom note: $TEST_DIR/README_DECRYPT.txt"

echo "EICAR ransomware simulation complete."
echo "Check Wazuh dashboard for alerts (rule ID: $RULE_ID)."
echo "This simulation helps test detection capabilities for malware/ransomware threats."
