#!/bin/bash

# =========================================================
# Ensure script is run as root
# =========================================================
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script as root."
  exit 1
fi

INFO_FILE="/root/server_info.txt"
source /etc/os-release
CODENAME=$VERSION_CODENAME

# =========================================================
# Error Handling Helper
# =========================================================
check_status() {
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: The last command failed to execute."
        echo "💡 HINT: Since you are operating from Iran, this is likely due to:"
        echo "   - Sanctions (403 Forbidden)"
        echo "   - Network filtering / Iran-Access only restrictions"
        echo "👉 Try using Proxychains or check if the selected mirror is down."
        echo "---------------------------------------------------"
        read -p "Press Enter to continue..."
    else
        echo "✅ Success!"
    fi
}

# =========================================================
# 1. INITIAL SETUP MENU
# =========================================================
setup_mirrors() {
    echo -e "\n--- Ubuntu Repository Mirrors (Iran) ---"
    echo "1) ArvanCloud (mirror.arvancloud.ir) - Recommended"
    echo "2) IranServer (repo.iranserver.com)"
    echo "3) Radin (mirror.radin.ir)"
    read -p "Select a mirror [1-3] (Enter to skip): " mirror_choice

    local mirror_url=""
    case $mirror_choice in
        1) mirror_url="mirror.arvancloud.ir/ubuntu" ;;
        2) mirror_url="repo.iranserver.com/ubuntu" ;;
        3) mirror_url="mirror.radin.ir/ubuntu" ;;
        *) echo "Skipping mirror setup."; return ;;
    esac

    echo "Cleaning up old backup files..."
    rm -f /etc/apt/sources.list.d/*.backup
    rm -f /etc/apt/sources.list.d/*.save

    echo "Generating fresh mirror configurations for Ubuntu $VERSION_ID ($CODENAME)..."

    if [[ "$VERSION_ID" == "24.04" ]]; then
        cat <<EOF > /etc/apt/sources.list.d/ubuntu.sources
Types: deb
URIs: http://$mirror_url
Suites: $CODENAME $CODENAME-updates $CODENAME-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://$mirror_url
Suites: $CODENAME-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
        > /etc/apt/sources.list
    else
        cat <<EOF > /etc/apt/sources.list
deb http://$mirror_url $CODENAME main restricted universe multiverse
deb http://$mirror_url $CODENAME-updates main restricted universe multiverse
deb http://$mirror_url $CODENAME-backports main restricted universe multiverse
deb http://$mirror_url $CODENAME-security main restricted universe multiverse
EOF
    fi
    
    echo "Updating package lists..."
    systemctl daemon-reload 2>/dev/null
    apt update -y
    check_status
}

restore_mirrors() {
    echo -e "\n--- Restoring Original Ubuntu Mirrors ---"
    local mirror_url="archive.ubuntu.com/ubuntu"
    
    if [[ "$VERSION_ID" == "24.04" ]]; then
        cat <<EOF > /etc/apt/sources.list.d/ubuntu.sources
Types: deb
URIs: http://$mirror_url
Suites: $CODENAME $CODENAME-updates $CODENAME-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu
Suites: $CODENAME-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
        > /etc/apt/sources.list
    else
        cat <<EOF > /etc/apt/sources.list
deb http://$mirror_url $CODENAME main restricted universe multiverse
deb http://$mirror_url $CODENAME-updates main restricted universe multiverse
deb http://$mirror_url $CODENAME-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu $CODENAME-security main restricted universe multiverse
EOF
    fi
    echo "✅ Original mirrors restored."
    apt update -y
    check_status
}

check_network_mirrors() {
    echo -e "\n--- Network & Mirror Diagnostic ---"
    echo -n "1. Checking Internet Connectivity (Ping 8.8.8.8)... "
    if ping -c 2 -W 2 8.8.8.8 &> /dev/null; then echo "✅ OK"; else echo "❌ FAILED"; fi

    echo -n "2. Checking DNS Resolution (google.com)... "
    if ping -c 1 -W 2 google.com &> /dev/null; then echo "✅ OK"; else echo "❌ FAILED"; fi

    echo "3. Testing APT Mirrors..."
    apt update
    if [ $? -eq 0 ]; then
        echo "✅ APT Mirrors are working fine!"
    else
        echo "❌ APT update failed. (Your current mirror might be down, try changing it)"
    fi
    read -p "Press Enter to continue..."
}

setup_docker() {
    echo -e "\n--- Installing Docker ---"
    apt install -y docker.io docker-compose
    systemctl enable --now docker

    echo "Configuring Docker Registry Mirror..."
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

install_nginx_basic() {
    echo -e "\n--- Installing Base Nginx ---"
    apt install -y nginx
    systemctl enable --now nginx
    check_status
}

menu_initial_setup() {
    while true; do
        echo -e "\n======================================"
        echo "         INITIAL SETUP MENU           "
        echo "======================================"
        echo "1) Setup Iranian Mirrors (Robust & Clean)"
        echo "2) Restore Original Ubuntu Mirrors"
        echo "3) Check Network & Mirrors (Diagnostics)"
        echo "4) Install Docker (with Mirrors)"
        echo "5) Configure Proxychains"
        echo "6) Install Base Nginx"
        echo "7) Run Smart Initial Setup (Mirrors, Docker, Proxy, Nginx)"
        echo "8) Back to Main Menu"
        read -p "Select option: " opt
        case $opt in
            1) setup_mirrors ;;
            2) restore_mirrors ;;
            3) check_network_mirrors ;;
            4) setup_docker ;;
            5) setup_proxychains ;;
            6) install_nginx_basic ;;
            7) setup_mirrors; setup_docker; setup_proxychains; install_nginx_basic ;;
            8) break ;;
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

    echo "Setting up NPM Mirror..."
    npm config set registry https://registry.npmjs.ir/ 2>/dev/null || npm config set registry https://registry.npmjs.org/
    
    echo "Installing Node Version Manager 'n'..."
    npm install -g n
    check_status

    read -p "Enter desired Node.js version [Default: 22]: " node_version
    node_version=${node_version:-22}

    echo "Fetching Node.js v$node_version..."
    N_NODE_MIRROR=https://mirrors.aliyun.com/nodejs-release/ n $node_version
    hash -r
    check_status

    echo "Installing React CLI globally..."
    npm install -g create-react-app
    check_status
}

install_golang() {
    echo -e "\n--- Installing Go (Golang) ---"
    apt install -y golang
    check_status

    go env -w GOPROXY=https://goproxy.io,direct
    echo "GOPROXY configured successfully."
}

menu_dev_tools() {
    while true; do
        echo -e "\n======================================"
        echo "         DEVELOPER TOOLS MENU         "
        echo "======================================"
        echo "1) Node.js (Select Version) + npm + React CLI"
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
    if ! command -v docker &> /dev/null; then setup_docker; fi

    read -p "Enter a new MongoDB Admin Username: " mongo_user
    read -s -p "Enter Password for $mongo_user: " mongo_pass
    echo ""
    
    docker run -d --name mongodb --restart unless-stopped -p 27017:27017 \
      -e MONGO_INITDB_ROOT_USERNAME=$mongo_user \
      -e MONGO_INITDB_ROOT_PASSWORD=$mongo_pass mongo:latest
    check_status
    
    echo "MongoDB -> Username: $mongo_user | Password: $mongo_pass" >> $INFO_FILE
    echo "MongoDB URI -> mongodb://$mongo_user:$mongo_pass@127.0.0.1:27017/?authSource=admin" >> $INFO_FILE
}

install_redis() {
    echo -e "\n--- Installing Redis (via Docker) ---"
    if ! command -v docker &> /dev/null; then setup_docker; fi
    
    read -p "Do you want to set a Redis password? (y/n): " set_pass
    if [[ "$set_pass" == "y" || "$set_pass" == "Y" ]]; then
        read -s -p "Enter Redis Password: " redis_pass
        echo ""
        docker run -d --name redis --restart unless-stopped -p 6379:6379 \
          redis:latest redis-server --requirepass "$redis_pass"
        
        echo "Redis -> Password: $redis_pass" >> $INFO_FILE
        echo "Redis URI -> redis://:$redis_pass@127.0.0.1:6379" >> $INFO_FILE
    else
        docker run -d --name redis --restart unless-stopped -p 6379:6379 redis:latest
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
    echo "1) Initial Server Setup (Mirrors, Proxy, Docker, Nginx)"
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
            setup_mirrors; setup_docker; setup_proxychains; install_nginx_basic
            install_node_react; install_golang; install_mongodb; install_redis
            echo "ALL TASKS COMPLETED!"
            ;;
        5) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option!" ;;
    esac
done
