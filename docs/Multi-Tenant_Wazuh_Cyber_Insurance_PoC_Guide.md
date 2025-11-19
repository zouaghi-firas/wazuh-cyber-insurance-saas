# Multi-Tenant Wazuh Cyber Insurance PoC – Guide

## Introduction

This document provides a comprehensive step-by-step guide to deploy a multi-tenant Wazuh Proof of Concept (PoC) for a parametric cyber insurance scenario. It assumes you start with a clean Windows PC and zero prior knowledge of Wazuh. The goal is to demonstrate:

- How to set up **REINSURER** as the global Wazuh admin
- How to configure **INSURER1** and **INSURER2** tenants
- How to manage **multiple SME organisations (org-1 → org-4)**
- How to deploy **agents on all machines**
- How to configure **roles, DLS filters, tenants, and users**
- How to **simulate cyber risks** for insurance claims
- How to **run a demo** showing tenant isolation and REINSURER oversight

All commands, configuration files, and dashboard actions are included.

## Architecture Overview

### Logical Architecture Diagram

```
+---------------------------+
|      REINSURER Admin      |
| Wazuh Manager & Dashboard |
| OpenSearch / Kibana       |
| Super Tenant Access       |
+------------+--------------+
             |
             |-----------------------|
             |                       |
+----------------------+   +----------------------+
| INSURER1 Tenant      |   | INSURER2 Tenant      |
| Admin: INSURER1-admin|   | Admin: INSURER2-admin|
| Organisations:       |   | Organisations:       |
| - org-1              |   | - org-3              |
| - org-2              |   | - org-4              |
| Users:               |   | Users:               |
| - INSURER1-user-org1 |   | - INSURER2-user-org3 |
| - INSURER1-user-org2 |   | - INSURER2-user-org4 |
+----------+-----------+   +----------+-----------+
           |                          |
+----------+-----------+   +----------+-----------+
| org-1 VM | org-2 VM  |   | org-3 VM | org-4 VM  |
+----------+-----------+   +----------+-----------+
```


### System Components

| VM # | Name              | Role                    | Tenant      | Access Level               |
|------|-------------------|-------------------------|-------------|---------------------------|
| 1    | vm-reinsurer      | REINSURER-admin          | Global      | Full admin access          |
| 2    | vm-insurer1-admin | INSURER1-admin          | INSURER1    | Full tenant access        |
| 3    | vm-insurer2-admin | INSURER2-admin          | INSURER2    | Full tenant access        |
| 4    | vm-insurer1-org1  | INSURER1-user-org1       | INSURER1    | Limited to org-1 alerts   |
| 5    | vm-insurer1-org2  | INSURER1-user-org2       | INSURER1    | Limited to org-2 alerts   |
| 6    | vm-insurer2-org3  | INSURER2-user-org3       | INSURER2    | Limited to org-3 alerts   |
| 7    | vm-insurer2-org4  | INSURER2-user-org4       | INSURER2    | Limited to org-4 alerts   |
---
## Cyber Insurance Scenario

The PoC simulates cyber incidents that may trigger parametric insurance claims:

- **Ransomware** – encrypts files
- **Brute-force SSH attacks**
- **Malware downloads** (EICAR test files)
- **Privilege escalation attempts**
- **Data exfiltration attempts**
- **Log tampering**
- **Service disruption**
- **Network scanning**

### Access Control Model

- **REINSURER** sees all incidents across all tenants
- Each insurer sees only incidents for their tenant
- SME users see only incidents for their specific organisation
---
## Required Tools

### Windows Host Requirements

- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) 6.1 or later
- [Vagrant](https://www.vagrantup.com/downloads) 2.2.19 or later
- [Git](https://git-scm.com/downloads)
- PowerShell (preinstalled)
- Internet access to download Ubuntu Vagrant boxes and Docker images
- Minimum 16GB RAM and 50GB free disk space

### Linux VM Requirements

- Ubuntu Server 22.04 LTS
- Docker & Docker Compose (on REINSURER VM)
- Wazuh Manager (REINSURER VM)
- Wazuh Dashboard (REINSURER VM)
- Wazuh Agent (all SME & Admin VMs)
- OpenSearch / Kibana (REINSURER VM)
---
## GitHub Repository Structure

The final PoC will be stored in GitHub for repeatable deployments:

```
WazuhPoC/
├── Vagrantfile
├── README.md
├── scripts/
│   ├── install_docker.sh
│   ├── install_wazuh_agent.sh
│   ├── register_agents.sh
│   └── simulate_threats/
│       ├── ransomware.sh
│       ├── ssh_bruteforce.sh
│       ├── malware_eicar.sh
│       └── privilege_escalation.sh
├── configs/
│   ├── wazuh.yml
│   ├── ossec.conf.org1
│   ├── ossec.conf.org2
│   ├── ossec.conf.org3
│   └── ossec.conf.org4
└── docs/
    └── demo_script.md
```
---
## Part 1: Setup Windows Host

### 1.1 Install VirtualBox

1. Download VirtualBox from [https://www.virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads)
2. Run installer with default settings
3. Verify installation in PowerShell:

```powershell
VBoxManage --version
```

Expected output: version number, e.g., `7.0.8`
---
### 1.2 Install Vagrant

1. Download from [https://www.vagrantup.com/downloads](https://www.vagrantup.com/downloads)
2. Install with default options
3. Verify:

```powershell
vagrant --version
```
---
### 1.3 Install Git

1. Download from [https://git-scm.com/downloads](https://git-scm.com/downloads)
2. Install with default options (use Git from Command Prompt)
3. Verify:

```powershell
git --version
```
---
### 1.4 Create Workspace

```powershell
mkdir C:\WazuhPoC
cd C:\WazuhPoC
```
---
### 1.5 Initialize GitHub Repository

```powershell
git init
git remote add origin https://github.com/yourusername/WazuhPoC.git
```
---
### 1.6 Verify Environment

- VirtualBox installed and accessible
- Vagrant installed and accessible
- Git installed and accessible
- Workspace folder created

> You are now ready to **define the 7 VMs** for the PoC.
---
# Part 2: Create and Launch 7 VMs Using Vagrant
---
## **2.1 Define VM Configuration**
We will use **Ubuntu 22.04 LTS** for all VMs. Each VM has a **private network IP** for internal communication.  
| VM Name          | Role                 | Tenant        | Org Label(s)   | IP           |
|-----------------|--------------------|---------------|----------------|-------------|
| vm-reinsurer     | REINSURER-admin     | Super         | all orgs       | 192.168.56.10 |
| vm-insurer1-admin | INSURER1 Admin     | INSURER1      | org-1, org-2   | 192.168.56.11 |
| vm-insurer2-admin | INSURER2 Admin     | INSURER2      | org-3, org-4   | 192.168.56.14 |
| vm-insurer1-org1 | SME org-1           | INSURER1      | org-1          | 192.168.56.12 |
| vm-insurer1-org2 | SME org-2           | INSURER1      | org-2          | 192.168.56.13 |
| vm-insurer2-org3 | SME org-3           | INSURER2      | org-3          | 192.168.56.15 |
| vm-insurer2-org4 | SME org-4           | INSURER2      | org-4          | 192.168.56.16 |
---
## **2.2 Create Vagrantfile**
1. In **C:\WazuhPoC**, create a file named `Vagrantfile`:
```powershell
notepad Vagrantfile
````
2. Paste the following **ready-to-copy Vagrantfile**:
```ruby
Vagrant.configure("2") do |config|
config.vm.box = "ubuntu/jammy64"
vm_list = {
"vm-reinsurer" => "192.168.56.10",
"vm-insurer1-admin" => "192.168.56.11",
"vm-insurer1-org1" => "192.168.56.12",
"vm-insurer1-org2" => "192.168.56.13",
"vm-insurer2-admin" => "192.168.56.14",
"vm-insurer2-org3" => "192.168.56.15",
"vm-insurer2-org4" => "192.168.56.16"
}
vm_list.each do |name, ip|
config.vm.define name do |v|
v.vm.hostname = name
v.vm.network "private_network", ip: ip
v.vm.provider "virtualbox" do |vb|
vb.memory = (name == "vm-reinsurer") ? 4096 : 2048
vb.cpus = (name == "vm-reinsurer") ? 2 : 1
end
end
end
end
```
3. Save and close the file.
---
## **2.3 Launch All VMs**
1. Open **PowerShell**, navigate to `C:\WazuhPoC`:
```powershell
cd C:\WazuhPoC
```
2. Start all VMs:
```powershell
vagrant up
```
> This command will:
>
> * Download the Ubuntu Jammy64 box if not already present
> * Create 7 VMs with specified memory, CPU, hostname, and private IPs
> * Configure VirtualBox networking automatically
3. **Verify VMs are running**:
```powershell
vagrant status
```
Expected output: All VMs show `running`.
---
## **2.4 SSH into a VM**
Example: Connect to REINSURER VM:
```powershell
vagrant ssh vm-reinsurer
```
* You are now inside the Ubuntu terminal of the REINSURER VM.
* Use `exit` to leave SSH.
Repeat for other VMs as needed:
```powershell
vagrant ssh vm-insurer1-admin
vagrant ssh vm-insurer1-org1
```
---
## **2.5 Optional: Check Network Connectivity**
From REINSURER VM:
```bash
ping 192.168.56.11  # ping INSURER1-admin
ping 192.168.56.12  # ping INSURER1-org1
ping 192.168.56.15  # ping INSURER2-org3
```
* Ensure all pings respond to verify the private network works correctly.
---
## **2.6 Folder Structure on VMs**
We will maintain consistency for scripts and configs:
```bash
mkdir -p ~/wazuh-scripts/{install,agents,simulate_threats}
mkdir -p ~/wazuh-configs
```
* `install/` → installation scripts (Docker, Wazuh)
* `agents/` → agent registration scripts
* `simulate_threats/` → scripts to simulate ransomware, SSH brute-force, etc.
* `wazuh-configs/` → configuration files (ossec.conf, wazuh.yml)
---

* All 7 VMs are created and running
* Private network IPs assigned
* Hostnames set
* SSH access verified
* Folder structure ready for scripts and configuration
# Part 3: Install Wazuh Manager, OpenSearch & Dashboard on REINSURER VM
---
## **3.1 SSH into REINSURER VM**
```powershell
vagrant ssh vm-reinsurer
````
You are now inside the REINSURER Ubuntu VM.
---
## **3.2 Update & Upgrade Ubuntu**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget unzip apt-transport-https software-properties-common
```
---
## **3.3 Install Docker**
1. Remove old versions (if any):
```bash
sudo apt remove docker docker-engine docker.io containerd runc
```
2. Install dependencies:
```bash
sudo apt install -y ca-certificates curl gnupg lsb-release
```
3. Add Docker official GPG key:
```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```
4. Add Docker repository:
```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
5. Install Docker Engine:
```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```
6. Verify Docker:
```bash
docker --version
docker compose version
```
---
## **3.4 Add User to Docker Group**
```bash
sudo usermod -aG docker $USER
newgrp docker
```
---
## **3.5 Install Wazuh via Docker Compose**
1. Create a folder for Docker Compose:
```bash
mkdir ~/wazuh-docker && cd ~/wazuh-docker
```
2. Download Wazuh docker-compose.yml:
```bash
wget https://raw.githubusercontent.com/wazuh/wazuh-docker/master/docker-compose.yml
```
---
## **3.6 Modify docker-compose.yml for Multi-Tenant**
* Open `docker-compose.yml`:
```bash
nano docker-compose.yml
```
* Ensure **ports** for dashboard and OpenSearch are accessible:
```yaml
wazuh-dashboard:
ports:
- "5601:5601"
opensearch:
ports:
- "9200:9200"
- "9600:9600"
```
* Save & exit (`CTRL+O`, `Enter`, `CTRL+X`)
---
## **3.7 Start Wazuh Services**
```bash
docker compose up -d
```
* This will start:
* Wazuh Manager
* OpenSearch
* Wazuh Dashboard
* Filebeat and Logstash integrated for alerts
---
## **3.8 Verify Services**
```bash
docker ps
```
Expected containers:
* wazuh-manager
* wazuh-dashboard
* opensearch
* filebeat
* logstash
---
## **3.9 Access Wazuh Dashboard**
* From **Windows host browser**, open:
```
http://192.168.56.10:5601
```
* Default credentials (for demo purposes):
```
Username: admin
Password: admin
```
> You will change these after first login for security.
---
## **3.10 Configure Admin Users & Tenants**
1. **Create Global Users**
* `reinsurer-admin` → full access
* `INSURER1-admin` → full access to INSURER1 tenant
* `INSURER2-admin` → full access to INSURER2 tenant
* `INSURER1-user-org1` → view only org-1
* `INSURER1-user-org2` → view only org-2
* `INSURER2-user-org3` → view only org-3
* `INSURER2-user-org4` → view only org-4
2. **Create Tenants**
* **Tenant:** INSURER1
* **Tenant:** INSURER2
* **Tenant:** Global (for REINSURER)
3. **Configure Roles & DLS Filters**
* Role examples:
```json
{
"role_name": "role_insurer1_admin",
"permissions": ["read","write"],
"tenants": ["INSURER1"]
}
```
* DLS filter for org-1:
```json
{
"bool": {
"filter": [
{ "match_phrase": {"agent.labels.organisation": "org-1"} }
]
}
}
```
* Repeat for org-2, org-3, org-4
---
## **3.11 Verify Dashboard Multi-Tenant**
* Log in as `INSURER1-admin` → see only INSURER1 tenant
* Log in as `INSURER2-admin` → see only INSURER2 tenant
* Log in as `reinsurer-admin` → see all tenants and all orgs
---
* Docker & Wazuh installed on REINSURER VM
* OpenSearch & Dashboard running
* Multi-tenant users created
* Roles & DLS configured for org-level access
# Part 4: Install and Register Wazuh Agents on SME and Admin VMs
---
## **4.1 SSH into SME/Admin VMs**
For each VM, SSH using Vagrant:
```powershell
vagrant ssh vm-insurer1-admin
vagrant ssh vm-insurer1-org1
vagrant ssh vm-insurer1-org2
vagrant ssh vm-insurer2-admin
vagrant ssh vm-insurer2-org3
vagrant ssh vm-insurer2-org4
````
---
## **4.2 Update Ubuntu & Install Prerequisites**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl unzip wget -y
```
---
## **4.3 Download and Install Wazuh Agent**
1. Add Wazuh repository:
```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --dearmor -o /usr/share/keyrings/wazuh-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh-archive-keyring.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update
```
2. Install agent:
```bash
sudo apt install wazuh-agent -y
```
---
## **4.4 Configure Agent for REINSURER Manager**
1. Edit agent configuration:
```bash
sudo nano /var/ossec/etc/ossec.conf
```
2. Modify `<server>` section to point to REINSURER VM IP:
```xml
<server>
<address>192.168.56.10</address>
<port>1514</port>
</server>
```
3. Add **agent label** (organization):
```xml
<agent_config>
<labels>
<label name="organisation">org-1</label>
</labels>
</agent_config>
```
* Replace `org-1` with org-2, org-3, org-4 as per VM.
4. Save & exit (`CTRL+O`, `CTRL+X`)
---
## **4.5 Enable & Start Wazuh Agent**
```bash
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
sudo systemctl status wazuh-agent
```
---
## **4.6 Register Agent on REINSURER Manager**
1. SSH into REINSURER VM:
```bash
vagrant ssh vm-reinsurer
```
2. List incoming unregistered agents:
```bash
docker exec -it wazuh-manager /var/ossec/bin/agent_control -l
```
3. Add agent with registration key:
```bash
docker exec -it wazuh-manager /var/ossec/bin/manage_agents
```
* Follow prompts to **add new agent** for each SME/Admin VM
* Name: match VM hostname (`vm-insurer1-org1`, etc.)
* Note the **agent ID** assigned
4. On agent VM, register using agent key:
```bash
sudo /var/ossec/bin/agent-auth -m 192.168.56.10 -A vm-insurer1-org1
```
* Replace with appropriate hostname and IP
5. Verify agent connection on REINSURER:
```bash
docker exec -it wazuh-manager /var/ossec/bin/agent_control -l
```
* Status should be `Active`
---
## **4.7 Verify Agent Labels and Tenant Visibility**
1. In **Wazuh Dashboard**, log in as:
* `INSURER1-admin` → should see agents org-1 & org-2
* `INSURER2-admin` → should see agents org-3 & org-4
* `reinsurer-admin` → sees all agents
2. Verify DLS filters work: each SME user sees only their org's alerts.
---
## **4.8 Folder Structure on Agents (for Threat Simulation)**
```bash
mkdir -p ~/simulate_threats
```
* Place scripts for ransomware, SSH brute-force, malware, privilege escalation, etc.
---
* Wazuh agents installed and registered on all SME/Admin VMs
* Agent labels configured for org-1 → org-4
* Agents connected to REINSURER Manager
* Dashboard visibility verified
# Part 5: Configure Roles, Tenants & DLS Filters in Wazuh Dashboard
---
## **5.1 Access Wazuh Dashboard**
1. From your Windows host browser, open:
```
[http://192.168.56.10:5601](http://192.168.56.10:5601)
```
2. Login as:
```
Username: admin
Password: admin
```
> This is the REINSURER admin account. You will have full access to all tenants and orgs.
---
## **5.2 Create Tenants**
Tenants isolate dashboards, visualizations, and saved objects per insurer.
1. Navigate: **Management → Security → Tenants**
2. Create tenants:
- **INSURER1**
- **INSURER2**
- **Global** (REINSURER sees everything)
3. Assign default dashboards and visualizations per tenant.
---
## **5.3 Create Roles**
Roles define permissions on dashboards and data (Document Level Security).
1. Navigate: **Management → Security → Roles**
2. Create roles:



| Role Name               | Permissions | Tenant   | DLS Filter (JSON)                                                                          |
| ----------------------- | ----------- | -------- | ------------------------------------------------------------------------------------------ |
| role_INSURER1_admin     | read, write | INSURER1 | `none` → full access to INSURER1 tenant                                                    |
| role_INSURER1_user_org1 | read only   | INSURER1 | `{ "bool": { "filter": [ { "match_phrase": {"agent.labels.organisation": "org-1"} } ] } }` |
| role_INSURER1_user_org2 | read only   | INSURER1 | `{ "bool": { "filter": [ { "match_phrase": {"agent.labels.organisation": "org-2"} } ] } }` |
| role_INSURER2_admin     | read, write | INSURER2 | `none` → full access to INSURER2 tenant                                                    |
| role_INSURER2_user_org3 | read only   | INSURER2 | `{ "bool": { "filter": [ { "match_phrase": {"agent.labels.organisation": "org-3"} } ] } }` |
| role_INSURER2_user_org4 | read only   | INSURER2 | `{ "bool": { "filter": [ { "match_phrase": {"agent.labels.organisation": "org-4"} } ] } }` |
| role_REINSURER_admin    | read, write | Global   | `none` → full access to all tenants                                                        |

> DLS filters ensure users only see alerts for their org.

---
## **5.4 Map Users to Roles**
1. Navigate: **Management → Security → Users**
2. Create users:

| Username               | Password | Role                     | Tenant      |
|------------------------|----------|--------------------------|------------|
| reinsurer-admin         | yourpass | role_REINSURER_admin     | Global     |
| INSURER1-admin          | pass123  | role_INSURER1_admin      | INSURER1   |
| INSURER1-user-org1      | pass123  | role_INSURER1_user_org1  | INSURER1   |
| INSURER1-user-org2      | pass123  | role_INSURER1_user_org2  | INSURER1   |
| INSURER2-admin          | pass123  | role_INSURER2_admin      | INSURER2   |
| INSURER2-user-org3      | pass123  | role_INSURER2_user_org3  | INSURER2   |
| INSURER2-user-org4      | pass123  | role_INSURER2_user_org4  | INSURER2   |
---
## **5.5 Configure Dashboards per Tenant**
1. Create dashboards:
- **INSURER1 Dashboard** → shows org-1 and org-2 alerts  
- **INSURER2 Dashboard** → shows org-3 and org-4 alerts  
- **Global Dashboard** → REINSURER sees all alerts
2. Assign dashboards to tenants:
- Navigate: **Management → Dashboards → Share → Tenant**
---
## **5.6 Verify Tenant & Role Restrictions**
1. Log in as `INSURER1-admin` → confirm:
- Can see all agents org-1 & org-2  
- Can create/modify rules for INSURER1
2. Log in as `INSURER1-user-org1` → confirm:
- Can see only org-1 alerts  
- Cannot see other orgs or modify rules
3. Log in as `INSURER2-user-org3` → confirm:
- Can see only org-3 alerts  
4. Log in as `reinsurer-admin` → confirm:
- Can see all agents and orgs  
- Can manage all rules, tenants, and dashboards
---
## **5.7 Summary of Security Mechanism**
- **Roles**: Define read/write access
- **DLS filters**: Limit document access per org
- **Tenants**: Separate dashboards and visualizations
- **Users**: Map to roles and tenants
- **Result**: SME users cannot see other orgs; insurer admins see only their tenant; REINSURER sees everything
---
- Multi-tenant users, roles, and DLS filters are configured  
- Tenants created and dashboards assigned  
- Role-based access control verified  
# Part 6: Simulate Cyber Threats and Generate Alerts
---
## **6.1 Overview of Threat Scenarios**
Each SME VM will simulate **cyber events** to demonstrate alert generation and tenant-specific visibility.
| Org          | Tenant      | Threats / Events                                      |
|--------------|------------|------------------------------------------------------|
| org-1        | INSURER1   | Ransomware, SSH brute-force, EICAR malware           |
| org-2        | INSURER1   | Privilege escalation, log tampering                  |
| org-3        | INSURER2   | Network scanning, suspicious sudo activity           |
| org-4        | INSURER2   | File integrity monitoring, suspicious process execution |
All alerts are captured by **Wazuh Manager** on REINSURER VM.
---
## **6.2 Prepare Threat Simulation Scripts**
On each SME VM, create a folder:
```bash
mkdir -p ~/simulate_threats
cd ~/simulate_threats
````
### Example scripts:
1. **Ransomware Simulation (EICAR file) – org-1**
```bash
#!/bin/bash
# eicar_ransomware.sh
echo "Simulating ransomware by creating EICAR test file..."
echo "X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!" > ~/eicar.com
```
2. **SSH Brute Force Simulation – org-1**
```bash
#!/bin/bash
# ssh_bruteforce.sh
echo "Simulating SSH brute-force..."
for i in {1..5}; do
ssh -o ConnectTimeout=2 invaliduser@127.0.0.1
done
```
3. **Privilege Escalation Attempt – org-2**
```bash
#!/bin/bash
# privilege_escalation.sh
echo "Simulating privilege escalation..."
sudo -l
```
4. **Network Scanning – org-3**
```bash
#!/bin/bash
# network_scan.sh
echo "Simulating network scan..."
nmap -sP 192.168.56.0/24
```
5. **File Integrity Monitoring Trigger – org-4**
```bash
#!/bin/bash
# file_modification.sh
echo "Simulating file modification..."
touch ~/important_file.txt
echo "modification" >> ~/important_file.txt
```
---
## **6.3 Make Scripts Executable**
```bash
chmod +x ~/simulate_threats/*.sh
```
---
## **6.4 Run Threat Simulations**
On each VM:
```bash
cd ~/simulate_threats
./eicar_ransomware.sh     # org-1
./ssh_bruteforce.sh       # org-1
./privilege_escalation.sh # org-2
./network_scan.sh          # org-3
./file_modification.sh     # org-4
```
> Wait a few seconds for Wazuh agents to report events to REINSURER Manager.
---
## **6.5 Verify Alerts on Dashboard**
1. **INSURER1-admin** → sees org-1 & org-2 alerts only
2. **INSURER1-user-org1** → sees only org-1 alerts
3. **INSURER2-admin** → sees org-3 & org-4 alerts only
4. **INSURER2-user-org3** → sees only org-3 alerts
5. **REINSURER-admin** → sees all alerts across all tenants and orgs
---
## **6.6 Create Custom Rules (Optional)**
You can create **custom Wazuh rules** for parametric insurance:
1. SSH into REINSURER VM:
```bash
docker exec -it wazuh-manager /bin/bash
```
2. Edit rules:
```bash
cd /var/ossec/etc/rules
nano local_rules.xml
```
3. Example: Detect ransomware EICAR file creation
```xml
<group name="cyber_insurance_rules">
<rule id="100001" level="10">
<decoded_as>command</decoded_as>
<description>EICAR test file creation</description>
<match>EICAR-STANDARD-ANTIVIRUS-TEST-FILE</match>
</rule>
</group>
```
4. Restart Wazuh Manager inside Docker:
```bash
docker restart wazuh-manager
```
---
## **6.7 Automated Threat Demo Script**
You can create a single script on REINSURER VM to trigger all SME threats sequentially for a demo:
```bash
#!/bin/bash
# demo_run.sh
vagrant ssh vm-insurer1-org1 -- "~/simulate_threats/eicar_ransomware.sh"
vagrant ssh vm-insurer1-org1 -- "~/simulate_threats/ssh_bruteforce.sh"
vagrant ssh vm-insurer1-org2 -- "~/simulate_threats/privilege_escalation.sh"
vagrant ssh vm-insurer2-org3 -- "~/simulate_threats/network_scan.sh"
vagrant ssh vm-insurer2-org4 -- "~/simulate_threats/file_modification.sh"
echo "All threats executed. Check dashboards!"
```
---
* Threat simulation scripts prepared and executed
* Alerts generated for each SME organization
* Tenant-level visibility verified
* Custom rules added for parametric insurance scenarios
* Automated demo script ready
# Part 7: Full PoC Demo Script for Cyber Insurance Claims
---
## **7.1 Objective**
Demonstrate a **multi-tenant Wazuh PoC** for a **parametric cyber insurance** workflow:
- **REINSURER** manages all tenants and sees all alerts
- **INSURER1 / INSURER2** see only their tenant data
- **SME users** see only their organization alerts
- Simulated cyber incidents trigger alerts, which could correspond to **parametric insurance claims**
---
## **7.2 Demo Steps**
### **Step 1 – Open Dashboards**
1. Open browser from Windows host:
```
[http://192.168.56.10:5601](http://192.168.56.10:5601)
````
2. Log in as **reinsurer-admin**  
- Verify access to all tenants and all orgs
3. Log in as **INSURER1-admin**  
- Verify access to INSURER1 tenant (org-1 + org-2)
4. Log in as **INSURER2-admin**  
- Verify access to INSURER2 tenant (org-3 + org-4)
5. Log in as SME user (e.g., **INSURER1-user-org1**)  
- Verify access restricted to org-1 alerts only
---
### **Step 2 – Trigger Threat Scenarios**
1. On REINSURER VM, run automated demo script:
```bash
cd ~/wazuh-docker/scripts/simulate_threats
./demo_run.sh
````
2. Wait 10–30 seconds for events to propagate to Wazuh Manager.
3. Verify **alerts** appear on dashboards:
* **INSURER1-admin** sees:
* org-1 & org-2 alerts
* **INSURER1-user-org1** sees:
* org-1 only
* **INSURER2-admin** sees:
* org-3 & org-4 alerts
* **INSURER2-user-org3** sees:
* org-3 only
* **REINSURER-admin** sees:
* all orgs, all alerts
---
### **Step 3 – Demonstrate Tenant Isolation**
1. Attempt to access org-2 alerts as **INSURER1-user-org1** → should be blocked
2. Attempt to modify rules as SME user → should fail
3. Modify rules as INSURER1-admin → should succeed
---
### **Step 4 – Demonstrate Custom Cyber Insurance Rules**
1. In Wazuh Dashboard, navigate: **Management → Rules → Custom Rules**
2. Select the rule for ransomware detection (EICAR)
3. Show alert triggered for org-1
4. Demonstrate **REINSURER oversight** of all org alerts
---
### **Step 5 – Show Document Level Security**
1. Log in as **INSURER2-user-org4**
2. Verify that only org-4 alerts are visible
3. Attempt to access org-3 → denied
---
### **Step 6 – Optional: Export Alerts for Claims**
1. Navigate: **Wazuh Dashboard → Alerts**
2. Filter by organization (via tenant or DLS)
3. Export alerts to **CSV or JSON** for parametric claim processing
4. Demonstrate potential **insurance payout trigger** for simulated ransomware / malware incidents
---
### **Step 7 – Summary Table for Demo**
| User               | Tenant   | Org Access | Allowed Actions                |
| ------------------ | -------- | ---------- | ------------------------------ |
| reinsurer-admin    | Global   | All orgs   | Full admin, rules, dashboards  |
| INSURER1-admin     | INSURER1 | org-1+2    | Full tenant access, rules edit |
| INSURER1-user-org1 | INSURER1 | org-1      | View only org-1 alerts         |
| INSURER1-user-org2 | INSURER1 | org-2      | View only org-2 alerts         |
| INSURER2-admin     | INSURER2 | org-3+4    | Full tenant access, rules edit |
| INSURER2-user-org3 | INSURER2 | org-3      | View only org-3 alerts         |
| INSURER2-user-org4 | INSURER2 | org-4      | View only org-4 alerts         |
---
* Multi-tenant PoC fully operational
* Threats triggered, alerts captured
* SME users, insurer admins, and REINSURER oversight verified
* Demo ready for **parametric cyber insurance presentation**
# Part 8: Optional Enhancements & Best Practices
---
## **8.1 Automate Deployment with Vagrant & GitHub**
1. Store **Vagrantfile**, scripts, and configurations in GitHub:
```
git add .
git commit -m "Initial Wazuh PoC setup"
git push origin main
````
2. Use `vagrant up` to **recreate entire environment** on any Windows host
3. Advantages:
- Consistent environment for demos
- Version control for scripts and configurations
- Easy rollback / updates
---
## **8.2 Scheduled Threat Simulations**
1. Use `cron` on Linux VMs to run threat scripts at scheduled intervals:
```bash
crontab -e
````
Example: run ransomware simulation every day at 10:00 AM
```
0 10 * * * /home/vagrant/simulate_threats/eicar_ransomware.sh
```
2. Demonstrates automated incident generation for recurring parametric triggers.
---
## **8.3 Email Notifications for Alerts**
1. Configure **Wazuh email alerting**:
* Edit `~/wazuh-docker/configs/ossec.conf` (or via Docker volumes)
* Add `<email_alerts>` section
Example:
```xml
<global>
<email_notification>yes</email_notification>
<email_to>insurer@example.com</email_to>
<smtp_server>smtp.example.com</smtp_server>
<email_from>wazuh@company.com</email_from>
</global>
```
2. Restart Wazuh Manager:
```bash
docker restart wazuh-manager
```
3. Alerts can now trigger emails for insurers or REINSURER.
---
## **8.4 Docker Container Backups**
1. Backup Wazuh and OpenSearch Docker volumes:
```bash
docker stop wazuh-dashboard opensearch wazuh-manager
docker run --rm -v wazuh_data:/data -v /home/vagrant/backups:/backup busybox tar cvf /backup/wazuh_backup.tar /data
docker start wazuh-dashboard opensearch wazuh-manager
```
2. Store backups for disaster recovery.
---
## **8.5 Securing Wazuh Credentials**
1. Change all default passwords for dashboard users
2. Use **strong passwords** or integrate with LDAP / SSO
3. Enable **HTTPS** for Wazuh Dashboard
```yaml
# In opensearch_dashboards.yml
server.ssl.enabled: true
server.ssl.certificate: /path/to/cert.pem
server.ssl.key: /path/to/key.pem
```
---
## **8.6 Scaling to More Tenants / Organizations**
1. Add new tenants in dashboard: **Management → Security → Tenants**
2. Add new roles with appropriate DLS filters
3. Add new SME agents and register them on Wazuh Manager
4. Update dashboards to include new organizations
---
## **8.7 Logging & Monitoring Best Practices**
1. Enable **audit logs** for Wazuh Manager and Dashboard
2. Regularly **review alerts and rules**
3. Maintain **separate dashboards per tenant**
4. Document **simulation scripts and rules** for transparency
5. Test **tenant isolation** regularly
---
## **8.8 Optional: Advanced Demonstrations**
* Show **multi-tenant SLA reporting** based on triggered incidents
* Demonstrate **parametric insurance triggers**:
* Ransomware encrypts ≥ X files → claim triggered
* Network scan detected on org-3 → security incident logged
* Integrate with **ticketing / claims management system** (optional for extended PoC)
---
* Environment automation ready via Vagrant & GitHub
* Scheduled threat simulations possible
* Email notifications configured
* Backups and security best practices in place
* Ready to scale tenants and orgs for more complex PoC
---
# **Congratulations! Your Multi-Tenant Wazuh PoC is Fully Functional**
You now have:
1. **REINSURER** managing all tenants
2. **INSURER1 & INSURER2** tenants with their respective orgs
3. **SME users** restricted to their organization alerts
4. **Simulated cyber threats** triggering alerts for parametric insurance
5. **Custom rules, dashboards, roles, and DLS filters**
6. **Full demo workflow for stakeholders**
Your PoC is production-ready for presentations, testing, and further development.