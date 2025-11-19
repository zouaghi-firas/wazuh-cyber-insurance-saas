#!/bin/bash

# Demo Run Script for Wazuh Multi-Tenant PoC
# This script runs all threat simulation scripts on the respective VMs

echo "=== Wazuh Multi-Tenant PoC Demo ==="
echo "This script will run threat simulations on all SME VMs."
echo ""

# Function to execute a command on a VM
execute_on_vm() {
    local vm_name=$1
    local script_path=$2
    local description=$3

    echo "---------------------------------------------------"
    echo "Executing on $vm_name: $description"
    echo "---------------------------------------------------"

    # Check if VM is running before attempting to connect
    if ! vagrant status $vm_name | grep -q "running"; then
        echo "ERROR: VM $vm_name is not running. Skipping execution."
        return 1
    fi

    # Execute the script on the VM with error handling
    echo "Connecting to $vm_name and executing script..."
    if vagrant ssh $vm_name -c "sudo bash $script_path"; then
        echo "SUCCESS: Script execution on $vm_name completed."
    else
        echo "ERROR: Failed to execute script on $vm_name."
        return 1
    fi

    echo ""

    # Wait a bit for events to be processed
    sleep 5
}

# Execute org-1 threat simulations
echo "Starting threat simulations for org-1..."

execute_on_vm "vm-insurer1-org1" "/vagrant/simulate_threats/org1/eicar_ransomware.sh" "EICAR Ransomware Simulation"
execute_on_vm "vm-insurer1-org1" "/vagrant/simulate_threats/org1/ssh_bruteforce.sh" "SSH Brute-Force Simulation"

# Execute org-2 threat simulation
echo "Starting threat simulations for org-2..."

execute_on_vm "vm-insurer1-org2" "/vagrant/simulate_threats/org2/privilege_escalation.sh" "Privilege Escalation Simulation"

# Execute org-3 threat simulation
echo "Starting threat simulations for org-3..."

execute_on_vm "vm-insurer2-org3" "/vagrant/simulate_threats/org3/network_scan.sh" "Network Scanning Simulation"

# Execute org-4 threat simulation
echo "Starting threat simulations for org-4..."

execute_on_vm "vm-insurer2-org4" "/vagrant/simulate_threats/org4/file_modification.sh" "File Modification Simulation"

echo "=== All Threat Simulations Complete ==="
echo ""
echo "You can now check the Wazuh dashboard at https://192.168.56.10:5601"
echo ""
echo "Login with different user accounts to verify multi-tenant access controls:"
echo "  - REINSURER admin: Can see all data"
echo "  - INSURER1 admin: Can see org-1 and org-2 data"
echo "  - INSURER2 admin: Can see org-3 and org-4 data"
echo "  - SME users: Can only see their organization's data"
echo ""
echo "Expected alerts:"
echo "  - org-1: EICAR ransomware detection (rule ID: 100001)"
echo "  - org-1: SSH brute-force detection (rule ID: 100002)"
echo "  - org-2: Privilege escalation detection (rule ID: 100003)"
echo "  - org-3: Network scanning detection (rule ID: 100004)"
echo "  - org-4: File modification detection (rule ID: 100005)"
