# -*- mode: ruby -*-
# vi: set ft=ruby :

# Multi-tenant Wazuh Cyber Insurance PoC Vagrantfile
# This file defines 7 virtual machines:
# - 1 REINSURER VM (Global Admin)
# - 2 INSURER Admin VMs
# - 4 SME organization VMs

# Define the number of VMs and their configurations
Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 LTS box
  config.vm.box = "bento/ubuntu-22.04"

  # Global configuration for all VMs
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = "2"
  end

  # Disable automatic box update checking
  config.vm.box_check_update = false

  # REINSURER VM (Global Admin)
  # This VM hosts the Wazuh Manager, OpenSearch, and Dashboard
  config.vm.define "vm-reinsurer" do |reinsurer|
    reinsurer.vm.hostname = "vm-reinsurer"
    reinsurer.vm.network "private_network", ip: "192.168.56.10"

    # Assign more resources to the REINSURER VM
    reinsurer.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"  # More memory for Docker containers
      vb.cpus = "2"
    end

    # Mount shared folders
    reinsurer.vm.synced_folder ".", "/vagrant", disabled: false
    reinsurer.vm.synced_folder "./wazuh-configs", "/vagrant/wazuh-configs"
    reinsurer.vm.synced_folder "./wazuh-docker", "/vagrant/wazuh-docker"

    # Provisioning
    reinsurer.vm.provision "shell", inline: <<-SHELL
      # Update package lists
      apt-get update

      # Install basic dependencies
      apt-get install -y curl wget unzip git

      # Install Docker
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
      apt-get update
      apt-get install -y docker-ce docker-ce-cli containerd.io

      # Install Docker Compose (using the latest stable version)
      DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
      curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose

      # Add vagrant user to docker group
      usermod -aG docker vagrant

      # Install Wazuh manager dependencies
      apt-get install -y lsof

      # Create directory for Wazuh
      mkdir -p /var/ossec

      # Download and install Wazuh manager
      curl -L https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /etc/apt/trusted.gpg.d/wazuh.gpg
      echo "deb [signed-by=/etc/apt/trusted.gpg.d/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
      apt-get update
      apt-get install -y wazuh-manager

      # Configure Wazuh manager
      cp /vagrant/wazuh-docker/configs/ossec.conf /var/ossec/etc/ossec.conf

      # Start Wazuh manager
      systemctl enable wazuh-manager
      systemctl start wazuh-manager

      # Open firewall ports
      ufw allow 1514/tcp  # Wazuh agent communication
      ufw allow 1515/tcp  # Wazuh agent registration
      ufw allow 5601/tcp  # OpenSearch Dashboard
      ufw allow 9200/tcp  # OpenSearch REST API
      ufw allow 9300/tcp  # OpenSearch node communication

      # Create startup script for Docker services
      echo '#!/bin/bash' > /home/vagrant/start_wazuh.sh
      echo 'cd /vagrant/wazuh-docker' >> /home/vagrant/start_wazuh.sh
      echo 'docker-compose up -d' >> /home/vagrant/start_wazuh.sh
      chmod +x /home/vagrant/start_wazuh.sh

      # Create stop script for Docker services
      echo '#!/bin/bash' > /home/vagrant/stop_wazuh.sh
      echo 'cd /vagrant/wazuh-docker' >> /home/vagrant/stop_wazuh.sh
      echo 'docker-compose down' >> /home/vagrant/stop_wazuh.sh
      chmod +x /home/vagrant/stop_wazuh.sh

      echo "REINSURER VM setup complete"
    SHELL
  end

  # INSURER1 Admin VM
  config.vm.define "vm-insurer1-admin" do |insurer1_admin|
    insurer1_admin.vm.hostname = "vm-insurer1-admin"
    insurer1_admin.vm.network "private_network", ip: "192.168.56.11"

    # Mount shared folders
    insurer1_admin.vm.synced_folder ".", "/vagrant", disabled: false
    insurer1_admin.vm.synced_folder "./wazuh-configs", "/vagrant/wazuh-configs"

    # Provisioning
    insurer1_admin.vm.provision "shell", inline: <<-SHELL
      # Update package lists
      apt-get update

      # Install basic dependencies
      apt-get install -y curl wget unzip git

      echo "INSURER1 Admin VM setup complete"
    SHELL
  end

  # INSURER1 org-1 VM
  config.vm.define "vm-insurer1-org1" do |insurer1_org1|
    insurer1_org1.vm.hostname = "vm-insurer1-org1"
    insurer1_org1.vm.network "private_network", ip: "192.168.56.12"

    # Mount shared folders
    insurer1_org1.vm.synced_folder ".", "/vagrant", disabled: false
    insurer1_org1.vm.synced_folder "./wazuh-configs", "/vagrant/wazuh-configs"
    insurer1_org1.vm.synced_folder "./simulate_threats", "/vagrant/simulate_threats"

    # Provisioning
    insurer1_org1.vm.provision "shell", inline: <<-SHELL
      # Update package lists
      apt-get update

      # Install basic dependencies
      apt-get install -y curl wget unzip git

      # Install Wazuh agent dependencies
      apt-get install -y lsof

      # Download and install Wazuh agent
      curl -L https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /etc/apt/trusted.gpg.d/wazuh.gpg
      echo "deb [signed-by=/etc/apt/trusted.gpg.d/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
      apt-get update
      apt-get install -y wazuh-agent

      # Configure Wazuh agent
      cp /vagrant/wazuh-configs/agents/org1_agent_config.xml /var/ossec/etc/ossec.conf

      # Start Wazuh agent
      systemctl enable wazuh-agent
      systemctl start wazuh-agent

      # Install additional tools for threat simulation
      apt-get install -y nmap hydra openssh-server

      # Enable SSH service
      systemctl enable ssh
      systemctl start ssh

      # Create a user for SSH brute-force simulation
      useradd -m -s /bin/bash testuser
      echo "testuser:weakpassword" | chpasswd

      # Make threat simulation scripts executable
      chmod +x /vagrant/simulate_threats/org1/*.sh

      echo "INSURER1 org-1 VM setup complete"
    SHELL
  end

  # INSURER1 org-2 VM
  config.vm.define "vm-insurer1-org2" do |insurer1_org2|
    insurer1_org2.vm.hostname = "vm-insurer1-org2"
    insurer1_org2.vm.network "private_network", ip: "192.168.56.13"

    # Mount shared folders
    insurer1_org2.vm.synced_folder ".", "/vagrant", disabled: false
    insurer1_org2.vm.synced_folder "./wazuh-configs", "/vagrant/wazuh-configs"
    insurer1_org2.vm.synced_folder "./simulate_threats", "/vagrant/simulate_threats"

    # Provisioning
    insurer1_org2.vm.provision "shell", inline: <<-SHELL
      # Update package lists
      apt-get update

      # Install basic dependencies
      apt-get install -y curl wget unzip git

      # Install Wazuh agent dependencies
      apt-get install -y lsof

      # Download and install Wazuh agent
      curl -L https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /etc/apt/trusted.gpg.d/wazuh.gpg
      echo "deb [signed-by=/etc/apt/trusted.gpg.d/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
      apt-get update
      apt-get install -y wazuh-agent

      # Configure Wazuh agent
      cp /vagrant/wazuh-configs/agents/org2_agent_config.xml /var/ossec/etc/ossec.conf

      # Start Wazuh agent
      systemctl enable wazuh-agent
      systemctl start wazuh-agent

      # Install additional tools for threat simulation
      apt-get install -y sudo

      # Create a user for privilege escalation simulation
      useradd -m -s /bin/bash testuser
      echo "testuser:weakpassword" | chpasswd

      # Make threat simulation scripts executable
      chmod +x /vagrant/simulate_threats/org2/*.sh

      echo "INSURER1 org-2 VM setup complete"
    SHELL
  end

  # INSURER2 Admin VM
  config.vm.define "vm-insurer2-admin" do |insurer2_admin|
    insurer2_admin.vm.hostname = "vm-insurer2-admin"
    insurer2_admin.vm.network "private_network", ip: "192.168.56.14"

    # Mount shared folders
    insurer2_admin.vm.synced_folder ".", "/vagrant", disabled: false
    insurer2_admin.vm.synced_folder "./wazuh-configs", "/vagrant/wazuh-configs"

    # Provisioning
    insurer2_admin.vm.provision "shell", inline: <<-SHELL
      # Update package lists
      apt-get update

      # Install basic dependencies
      apt-get install -y curl wget unzip git

      echo "INSURER2 Admin VM setup complete"
    SHELL
  end

  # INSURER2 org-3 VM
  config.vm.define "vm-insurer2-org3" do |insurer2_org3|
    insurer2_org3.vm.hostname = "vm-insurer2-org3"
    insurer2_org3.vm.network "private_network", ip: "192.168.56.15"

    # Mount shared folders
    insurer2_org3.vm.synced_folder ".", "/vagrant", disabled: false
    insurer2_org3.vm.synced_folder "./wazuh-configs", "/vagrant/wazuh-configs"
    insurer2_org3.vm.synced_folder "./simulate_threats", "/vagrant/simulate_threats"

    # Provisioning
    insurer2_org3.vm.provision "shell", inline: <<-SHELL
      # Update package lists
      apt-get update

      # Install basic dependencies
      apt-get install -y curl wget unzip git

      # Install Wazuh agent dependencies
      apt-get install -y lsof

      # Download and install Wazuh agent
      curl -L https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /etc/apt/trusted.gpg.d/wazuh.gpg
      echo "deb [signed-by=/etc/apt/trusted.gpg.d/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
      apt-get update
      apt-get install -y wazuh-agent

      # Configure Wazuh agent
      cp /vagrant/wazuh-configs/agents/org3_agent_config.xml /var/ossec/etc/ossec.conf

      # Start Wazuh agent
      systemctl enable wazuh-agent
      systemctl start wazuh-agent

      # Install additional tools for threat simulation
      apt-get install -y nmap

      # Make threat simulation scripts executable
      chmod +x /vagrant/simulate_threats/org3/*.sh

      echo "INSURER2 org-3 VM setup complete"
    SHELL
  end

  # INSURER2 org-4 VM
  config.vm.define "vm-insurer2-org4" do |insurer2_org4|
    insurer2_org4.vm.hostname = "vm-insurer2-org4"
    insurer2_org4.vm.network "private_network", ip: "192.168.56.16"

    # Mount shared folders
    insurer2_org4.vm.synced_folder ".", "/vagrant", disabled: false
    insurer2_org4.vm.synced_folder "./wazuh-configs", "/vagrant/wazuh-configs"
    insurer2_org4.vm.synced_folder "./simulate_threats", "/vagrant/simulate_threats"

    # Provisioning
    insurer2_org4.vm.provision "shell", inline: <<-SHELL
      # Update package lists
      apt-get update

      # Install basic dependencies
      apt-get install -y curl wget unzip git

      # Install Wazuh agent dependencies
      apt-get install -y lsof

      # Download and install Wazuh agent
      curl -L https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /etc/apt/trusted.gpg.d/wazuh.gpg
      echo "deb [signed-by=/etc/apt/trusted.gpg.d/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
      apt-get update
      apt-get install -y wazuh-agent

      # Configure Wazuh agent
      cp /vagrant/wazuh-configs/agents/org4_agent_config.xml /var/ossec/etc/ossec.conf

      # Start Wazuh agent
      systemctl enable wazuh-agent
      systemctl start wazuh-agent

      # Make threat simulation scripts executable
      chmod +x /vagrant/simulate_threats/org4/*.sh

      echo "INSURER2 org-4 VM setup complete"
    SHELL
  end
end
