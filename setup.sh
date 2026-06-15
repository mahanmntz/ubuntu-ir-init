#!/bin/bash

# =========================================================
# Ensure script is run as root
# =========================================================
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script as root."
  exit 1
fi

CREDENTIALS_FILE="/root/db_credentials.txt"

# =========================================================
# Error Handling Helper
# =========================================================
check_status() {
    if [ $? -ne 0 ]; then
        echo "ERROR: The last command failed to execute."
        echo "HINT: Since you are operating from Iran, this is likely due to:"
        echo "   - Sanctions (403 Forbidden)"
        echo "   - Network filtering / Iran-Access only restrictions"
        echo "   - DNS poisoning"
        echo "Try running the task with Proxychains, or ensure your local mirrors are working."
        echo "---------------------------------------------------"
        read -p "Press Enter to continue..."
    else
        echo "Success!"
    fi
}

# =========================================================
# 1. INITIAL SETUP MENU
# =========================================================
setup_mirrors() {
    echo -e "\n--- Ubuntu Repository Mirrors (Iran) ---"
    echo "1) IranServer (repo.iranserver.com)"
    echo "2) ArvanCloud (mirror.arvancloud.ir)"
    read -p "Select a mirror [1-2] (Enter to skip): " mirror_choice

    local mirror_url=""
    case $mirror_choice in
        1) mirror_url="repo.iranserver.com/ubuntu" ;;
        2) mirror_url="mirror.arvancloud.ir/ubuntu" ;;
        *) echo "Skipping mirror setup."; return ;;
    esac

    echo "Cleaning up old backup files to prevent APT warnings..."
    rm -f /etc/apt/sources.list.d/*.backup
    rm -f /etc/apt/sources.list.d/*.save

    echo "Applying new mirror: $mirror_url"

    if [ -f /etc/apt/sources.list ]; then
        cp /etc/apt/sources.list /root/sources.list.backup
        sed -i -E "s|https?://([a-zA-Z0-9-]+\.)?archive\.ubuntu\.com/ubuntu/?|http://$mirror_url/|g" /etc/apt/sources.list
        sed -i -E "s|https?://security\.ubuntu\.com/ubuntu/?|http://$mirror_url/|g" /etc/apt/sources.list
    fi

    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
        cp /etc/apt/sources.list.d/ubuntu.sources /root/ubuntu.sources.backup
        sed -i -E "s|URIs: .*ubuntu.com/ubuntu/?|URIs: http://$mirror_url/|g" /etc/apt/sources.list.d/ubuntu.sources
    fi
    
    echo "Updating package lists..."
    apt update -y
    check_status
}

setup_docker() {
    echo -e "\n--- Installing Docker ---"
    apt install -y docker.io docker-compose
    systemctl enable --now docker

    echo "Configuring IranServer Docker Registry Mirror..."
    mkdir -p /etc/docker
    cat <<EOF > /etc/docker/daemon.json
{
  "registry-mirrors": ["https://docker.iranserver.com", "https://registry.docker.ir"]
}
EOF
    systemctl restart docker
    check_status
}

setup_proxychains() {
    echo -e "\n--- Installing Proxychains ---"
    apt install -y proxychains4
    read -p "Enter proxy string (e.g., 'socks5 127.0.0.1 1080') or Enter to skip: " proxy_string

    if [ -n "$proxy_string" ]; then
        sed -i 's/^strict_chain/#strict_chain/g' /etc/proxychains4.conf
        sed -i 's/^#dynamic_chain/dynamic_chain/g' /etc/proxychains4.conf
        sed -i '/^socks4 \+127.0.0.1 \+9050/d' /etc/proxychains4.conf
        echo "$proxy_string" >> /etc/proxychains4.conf
        echo "Proxychains configured with: $proxy_string"
    fi
    check_status
}

menu_initial_setup() {
    while true; do
        echo -e "\n======================================"
        echo "         INITIAL SETUP MENU           "
        echo "======================================"
        echo "1) Setup Iranian Mirrors"
        echo "2) Install Docker (with Mirrors)"
        echo "3) Configure Proxychains"
        echo "4) Run All Initial Setups"
        echo "5) Back to Main Menu"
        read -p "Select option: " opt
        case $opt in
            1) setup_mirrors ;;
            2) setup_docker ;;
            3) setup_proxychains ;;
            4) setup_mirrors; setup_docker; setup_proxychains ;;
            5) break ;;
            *) echo "Invalid option." ;;
        esac
    done
}

# =========================================================
# 2. DEVELOPER TOOLS MENU
# =========================================================
install_node_react() {
    echo -e "\n--- Installing Node.js, npm, and React CLI ---"
    apt install -y nodejs npm
    check_status

    echo "Setting up NPM Mirror to bypass restrictions..."
    npm config set registry https://registry.npmjs.ir/ 2>/dev/null || npm config set registry https://registry.npmjs.org/
    
    echo "Installing React CLI (create-react-app) globally..."
    npm install -g create-react-app
    check_status
}

install_golang() {
    echo -e "\n--- Installing Go (Golang) ---"
    apt install -y golang
    check_status

    echo "Setting GOPROXY to bypass Iran restrictions for Go modules..."
    go env -w GOPROXY=https://goproxy.io,direct
    echo "GOPROXY configured successfully."
}

menu_dev_tools() {
    while true; do
        echo -e "\n======================================"
        echo "         DEVELOPER TOOLS MENU         "
        echo "======================================"
        echo "1) Node.js + npm + React CLI"
        echo "2) Go (Golang)"
        echo "3) Install All Dev Tools"
        echo "4) Back to Main Menu"
        read -p "Select option: " opt
        case $opt in
            1) install_node_react ;;
            2) install_golang ;;
            3) install_node_react; install_golang ;;
            4) break ;;
            *) echo "Invalid option." ;;
        esac
    done
}

# =========================================================
# 3. DATABASES MENU
# =========================================================
install_mongodb() {
    echo -e "\n--- Installing MongoDB (via Docker) ---"
    echo "Deploying MongoDB securely via local Docker registry mirror..."
    
    if ! command -v docker &> /dev/null; then
        echo "Docker is required for MongoDB installation. Installing Docker first..."
        setup_docker
    fi

    read -p "Enter a new MongoDB Admin Username: " mongo_user
    read -s -p "Enter Password for $mongo_user: " mongo_pass
    echo ""
    
    docker run -d \
      --name mongodb \
      --restart unless-stopped \
      -p 27017:27017 \
      -e MONGO_INITDB_ROOT_USERNAME=$mongo_user \
      -e MONGO_INITDB_ROOT_PASSWORD=$mongo_pass \
      mongo:latest
      
    check_status
    
    echo "MongoDB -> Username: $mongo_user | Password: $mongo_pass" >> $CREDENTIALS_FILE
    echo "Credentials securely saved to $CREDENTIALS_FILE"
}

install_redis() {
    echo -e "\n--- Installing Redis (via Docker) ---"
    echo "Deploying Redis securely via local Docker registry mirror..."
    
    if ! command -v docker &> /dev/null; then
        echo "Docker is required for Redis installation. Installing Docker first..."
        setup_docker
    fi
    
    read -p "Do you want to set a Redis password? (y/n): " set_pass
    if [[ "$set_pass" == "y" || "$set_pass" == "Y" ]]; then
        read -s -p "Enter Redis Password: " redis_pass
        echo ""
        docker run -d \
          --name redis \
          --restart unless-stopped \
          -p 6379:6379 \
          redis:latest redis-server --requirepass "$redis_pass"
        
        echo "Redis -> Password: $redis_pass" >> $CREDENTIALS_FILE
        echo "Credentials securely saved to $CREDENTIALS_FILE"
    else
        docker run -d \
          --name redis \
          --restart unless-stopped \
          -p 6379:6379 \
          redis:latest
    fi
    check_status
}

menu_databases() {
    while true; do
        echo -e "\n======================================"
        echo "            DATABASES MENU            "
        echo "======================================"
        echo "1) MongoDB"
        echo "2) Redis"
        echo "3) Install All Databases"
        echo "4) Back to Main Menu"
        read -p "Select option: " opt
        case $opt in
            1) install_mongodb ;;
            2) install_redis ;;
            3) install_mongodb; install_redis ;;
            4) break ;;
            *) echo "Invalid option." ;;
        esac
    done
}

# =========================================================
# MAIN LOOP
# =========================================================
while true; do
    echo -e "\n======================================"
    echo "    IRAN SERVER BOOTSTRAP - MAIN MENU "
    echo "======================================"
    echo "1) Initial Server Setup (Mirrors, Proxy, Docker)"
    echo "2) Developer Tools (Go, Node, React)"
    echo "3) Databases (MongoDB, Redis)"
    echo "4) Run EVERYTHING (Full Provisioning)"
    echo "5) Exit"
    echo "======================================"
    read -p "Select an option [1-5]: " main_choice

    case $main_choice in
        1) menu_initial_setup ;;
        2) menu_dev_tools ;;
        3) menu_databases ;;
        4) 
            setup_mirrors; setup_docker; setup_proxychains
            install_node_react; install_golang
            install_mongodb; install_redis
            echo "ALL TASKS COMPLETED!"
            ;;
        5) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option!" ;;
    esac
done
