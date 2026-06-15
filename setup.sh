#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script as root."
  exit 1
fi

setup_mirrors() {
    echo "======================================"
    echo "       Ubuntu Repository Mirrors      "
    echo "======================================"
    echo "1) IranServer (repo.iranserver.com)"
    echo "2) ArvanCloud (mirror.arvancloud.ir)"
    echo "3) Radin (mirror.radin.ir)"
    read -p "Select a mirror [1-3] (Press Enter to skip): " mirror_choice

    local mirror_url=""
    case $mirror_choice in
        1) mirror_url="repo.iranserver.com/ubuntu" ;;
        2) mirror_url="mirror.arvancloud.ir/ubuntu" ;;
        3) mirror_url="mirror.radin.ir/ubuntu" ;;
        *) echo "Skipping mirror setup."; return ;;
    esac

    echo "Backing up original sources.list to /etc/apt/sources.list.backup..."
    cp /etc/apt/sources.list /etc/apt/sources.list.backup

    echo "Applying new mirror: $mirror_url"
    sed -i "s|http://archive.ubuntu.com/ubuntu/|http://$mirror_url/|g" /etc/apt/sources.list
    sed -i "s|http://security.ubuntu.com/ubuntu/|http://$mirror_url/|g" /etc/apt/sources.list
    sed -i "s|http://ports.ubuntu.com/ubuntu-ports/|http://$mirror_url/|g" /etc/apt/sources.list

    echo "Updating package lists..."
    apt update -y
    echo "Mirrors configured successfully!"
}

setup_docker() {
    echo "======================================"
    echo "          Installing Docker           "
    echo "======================================"
    
    echo "Installing Docker..."
    apt install -y docker.io docker-compose

    echo "Starting and enabling Docker service..."
    systemctl enable --now docker

    echo "Configuring Docker Registry Mirror (IranServer)..."
    mkdir -p /etc/docker
    
    cat <<EOF > /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.iranserver.com",
    "https://registry.docker.ir"
  ]
}
EOF

    echo "Restarting Docker to apply changes..."
    systemctl restart docker
    echo "Docker installed and mirror configured successfully!"
}

setup_proxychains() {
    echo "======================================"
    echo "        Installing Proxychains        "
    echo "======================================"
    
    echo "Installing proxychains4..."
    apt install -y proxychains4

    read -p "Enter your proxy string (e.g., 'socks5 127.0.0.1 1080') or press Enter to skip: " proxy_string

    if [ -n "$proxy_string" ]; then
        echo "Configuring /etc/proxychains4.conf..."
        # Comment out the default strict_chain/socks4 if needed, and force dynamic_chain
        sed -i 's/^strict_chain/#strict_chain/g' /etc/proxychains4.conf
        sed -i 's/^#dynamic_chain/dynamic_chain/g' /etc/proxychains4.conf
        
        # Remove default socks4 line
        sed -i '/^socks4 \+127.0.0.1 \+9050/d' /etc/proxychains4.conf
        
        # Append the user proxy
        echo "$proxy_string" >> /etc/proxychains4.conf
        echo "Proxychains configured successfully with: $proxy_string"
    else
        echo "No proxy provided. Proxychains installed with default config."
    fi
}

show_menu() {
    echo ""
    echo "======================================"
    echo "      Server Initial Setup Script     "
    echo "======================================"
    echo "1) Setup Ubuntu Mirrors (Iran Mirrors)"
    echo "2) Install & Configure Docker (IranServer Mirror)"
    echo "3) Install & Configure Proxychains"
    echo "4) Run All Configurations"
    echo "5) Exit"
    echo "======================================"
    read -p "Select an option [1-5]: " choice

    case $choice in
        1) setup_mirrors ;;
        2) setup_docker ;;
        3) setup_proxychains ;;
        4) 
            setup_mirrors
            setup_docker
            setup_proxychains
            echo "All tasks completed!"
            ;;
        5) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option! Please try again." ;;
    esac
}

# Main Loop
while true; do
    show_menu
done
