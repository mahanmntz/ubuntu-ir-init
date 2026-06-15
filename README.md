# Ubuntu IR Init

A comprehensive, modular Bash script designed for automated server provisioning in restricted network environments. Built specifically for developers dealing with "Iran-Access" networks, heavy filtering, and international sanctions (403 errors).

This tool ensures that dependencies, databases, and developer environments are pulled from functional internal mirrors or correctly routed through bypass proxies without needing manual interventions.

## How It Works (Core Features)

### 1. Network & Bypass Capabilities
* **Local APT Mirrors:** The script replaces the default Ubuntu archive URLs in `/etc/apt/sources.list` with high-speed local mirrors (IranServer, ArvanCloud). This allows `apt install` commands to work without requiring international internet access.
* **Proxychains Integration:** Installs `proxychains4` and modifies its configuration file (`/etc/proxychains4.conf`) dynamically based on user terminal input to tunnel specific commands through a provided proxy (e.g., SOCKS5).
* **Docker Registry Injection:** Installs Docker via the local APT mirrors. To bypass Docker Hub restrictions (403 errors), it creates or updates `/etc/docker/daemon.json` to automatically inject unblocked local registry mirrors (like docker.iranserver.com).

### 2. Developer Tools Auto-Setup
Instead of fetching from official, restricted sources, the script safely installs tools using local networks:
* **Node.js & NPM:** Installs Node.js from the local APT mirrors. It then runs `npm config set registry` to point to a functional Iranian mirror (`registry.npmjs.ir`), allowing future `npm install` commands to succeed.
* **React CLI:** Installs `create-react-app` globally using the configured local NPM registry.
* **Go (Golang):** Installs Go via the local APT mirrors. It then executes `go env -w GOPROXY=https://goproxy.io,direct` to configure the Go proxy, ensuring module downloads bypass regional restrictions.

### 3. Database Provisioning
* **MongoDB & Redis:** Both databases are installed directly from the standard Ubuntu repositories routed through the local APT mirrors configured in step 1. 
* **Credential Management:** Upon installation, the script configures the services and prompts for authentication details. These inputted passwords are automatically and securely appended to `/root/db_credentials.txt` for safe keeping.

## Prerequisites
* **OS:** Ubuntu 20.04 / 22.04 LTS
* **Access:** Root privileges required (Run with sudo or as root user)

## Usage Guide

Depending on your server's initial network conditions, choose one of the methods below:

### Method 1: Using Git (If GitHub is accessible)

1. Clone the repository:
   ```bash
   git clone [https://github.com/mahanmntz/ubuntu-ir-init.git](https://github.com/mahanmntz/ubuntu-ir-init.git)
   cd ubuntu-ir-init

```

2. Make the script executable:
```bash
chmod +x setup.sh

```


3. Run the script as root:
```bash
sudo ./setup.sh

```



### Method 2: Manual Setup (If GitHub is blocked)

If your server cannot access GitHub due to filtering, you can easily create the file manually:

1. Create a new file using nano:
```bash
nano setup.sh

```


2. Copy the entire contents of the `setup.sh` script from your local machine and paste it into the terminal.
3. Save and exit (Press `Ctrl + O`, `Enter`, then `Ctrl + X`).
4. Make the script executable and run it:
```bash
chmod +x setup.sh
sudo ./setup.sh

```



## Installation Test Commands

After running the script, you can verify the successful installation and configuration of the tools using the following commands:

### 1. Initial Setup (Mirrors, Proxy, Docker)

* **Verify APT Mirrors:** Check if the sources list is using the selected Iranian mirror.
```bash
cat /etc/apt/sources.list

```


* **Verify Docker & Mirrors:** Check the Docker version and ensure the registry mirrors are applied.
```bash
docker --version
docker info | grep "Registry Mirrors" -A 2

```


* **Verify Proxychains:** Test internet connectivity through your configured proxy.
```bash
proxychains4 curl ifconfig.me

```



### 2. Developer Tools

* **Verify Node.js & NPM:** Check their versions and verify the NPM registry is set to the Iranian mirror.
```bash
node -v
npm -v
npm config get registry

```


* **Verify React CLI:**
```bash
create-react-app --version

```


* **Verify Go (Golang):** Check the Go version and verify the GOPROXY configuration.
```bash
go version
go env GOPROXY

```



### 3. Databases

* **Verify MongoDB:** Check the service status and version.
```bash
systemctl status mongodb
mongod --version

```


* **Verify Redis:** Check the service status and ping the server (it should reply with PONG if no password is set, or require authentication if you set one).
```bash
systemctl status redis-server
redis-cli ping

```



## Security Note

If you use the database configuration tools, your passwords will be saved in plain text at `/root/db_credentials.txt`. Because this file is located in the root directory, it is protected from standard users, but you should delete it or move it to a secure password manager once your setup is complete.

## License

This project is open-source and available under the [MIT License](https://www.google.com/search?q=LICENSE).

