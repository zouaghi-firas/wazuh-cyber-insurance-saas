#!/bin/bash

# Network Scanning Simulation Script for org-3
# This script simulates network scanning activities to trigger detection

echo "=== Network Scanning Simulation for org-3 ==="
echo "Simulating network scanning activities..."

# Target network range (internal network)
NETWORK="192.168.56.0/24"

# Log file for scan results
SCAN_LOG="/tmp/network_scan_results.log"

echo "Starting network scan of $NETWORK"
echo "This will trigger rule ID 100004 for network scanning detection."

# Perform a quick scan of the network
echo "Performing a quick scan of the network..."
nmap -sn $NETWORK > $SCAN_LOG 2>&1

# Perform a more detailed scan of a few hosts
echo "Performing a detailed scan of selected hosts..."
nmap -sS -O -p 22,80,443,3389 192.168.56.10 192.168.56.11 192.168.56.12 >> $SCAN_LOG 2>&1

# Perform a version detection scan
echo "Performing a version detection scan..."
nmap -sV -p 22,80,443 192.168.56.10 >> $SCAN_LOG 2>&1

echo "Network scanning simulation complete."
echo "Scan results saved to $SCAN_LOG"
echo "Check the Wazuh dashboard for alerts (rule ID: 100004)."

# Show a summary of the scan results
echo ""
echo "Scan summary:"
echo "Hosts discovered:"
grep -E "Nmap scan report for|Host is up" $SCAN_LOG | head -n 10

echo ""
echo "Ports discovered:"
grep -E "^[0-9]+/tcp" $SCAN_LOG | head -n 10
