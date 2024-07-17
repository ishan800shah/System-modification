#!/bin/bash

# Function to check and install a package if not already installed
install_package() {
  if ! dpkg -l | grep -q "$1"; then
    echo "Installing $1..."
    apt-get update && apt-get install -y "$1"
  else
    echo "$1 is already installed."
  fi
}

# Configure network interface
configure_network() {
  local netplan_file="/etc/netplan/01-netcfg.yaml"
  local interface="ens33" # Replace with the actual interface name if different

  echo "Configuring network interface..."
  if grep -q "192.168.16.21/24" "$netplan_file"; then
    echo "Network interface is already configured."
  else
    cat <<EOT > "$netplan_file"
network:
  version: 2
  ethernets:
    $interface:
      addresses:
        - 192.168.16.21/24
      gateway4: 192.168.16.1
      nameservers:
        addresses:
          - 8.8.8.8
EOT
    netplan apply
  fi
}

# Update /etc/hosts file
update_hosts() {
  local hosts_file="/etc/hosts"

  echo "Updating /etc/hosts file..."
  if grep -q "192.168.16.21 server1" "$hosts_file"; then
    echo "/etc/hosts is already updated."
  else
    sed -i '/server1/d' "$hosts_file"
    echo "192.168.16.21 server1" >> "$hosts_file"
  fi
}

# Install required packages
install_packages() {
  install_package "apache2"
  install_package "squid"
}

# Configure firewall
configure_firewall() {
  echo "Configuring firewall..."
  ufw allow in on eth0 to any port 22 proto tcp
  ufw allow in on eth1 to any port 80 proto tcp
  ufw allow in on eth1 to any port 3128 proto tcp
  ufw enable
}

# Create user accounts
create_users() {
  local users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
  local public_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

  for user in "${users[@]}"; do
    if id "$user" &>/dev/null; then
      echo "User $user already exists."
    else
      echo "Creating user $user..."
      useradd -m -s /bin/bash "$user"
    fi

    if [ "$user" == "dennis" ]; then
      usermod -aG sudo "$user"
    fi

    mkdir -p /home/"$user"/.ssh
    chown "$user":"$user" /home/"$user"/.ssh
    chmod 700 /home/"$user"/.ssh

    echo "$public_key" > /home/"$user"/.ssh/authorized_keys
    chown "$user":"$user" /home/"$user"/.ssh/authorized_keys
    chmod 600 /home/"$user"/.ssh/authorized_keys
  done
}

# Execute all functions
configure_network
update_hosts
install_packages
configure_firewall
create_users

echo "Configuration complete."
