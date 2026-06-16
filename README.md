# Ubuntu IR Init

A comprehensive, modular Bash script designed for automated server provisioning in restricted network environments. Built specifically for developers dealing with "Iran-Access" networks, heavy filtering, and international sanctions (403 errors).

This tool ensures that dependencies, databases, and developer environments are pulled from functional internal mirrors or correctly routed through bypass proxies without needing manual interventions.

## How It Works (Core Features)

### 1. Network & Bypass Capabilities
* **Local APT Mirrors:** The script replaces the default Ubuntu archive URLs in `/etc/apt/sources.list` and `ubuntu.sources` with high-speed local mirrors. It also cleans up invalid `.backup` files to prevent APT warnings.
* **Proxychains Integration:** Installs `proxychains4` and modifies its configuration file dynamically based on user terminal input to tunnel specific commands.
* **Docker Registry Injection:** Installs Docker via the local APT mirrors. To bypass Docker Hub restrictions, it updates `/etc/docker/daemon.json` to inject unblocked local registry mirrors.

### 2. Developer Tools Auto-Setup
Instead of fetching from official, restricted sources, the script safely installs tools using local networks:
* **Node.js & NPM:** Installs a base Node.js from local APT mirrors, sets the NPM registry to an Iranian mirror, installs the `n` package manager, and prompts the user to select their desired Node version (defaulting to v22). It fetches the binary using an unblocked mirror (Aliyun).
* **React CLI:** Installs `create-react-app` globally using the configured local NPM registry.
* **Go (Golang):** Installs Go via the local APT mirrors. It then configures the Go proxy (`GOPROXY`) to bypass module download restrictions.

### 3. Database Provisioning
* **MongoDB & Redis (via Docker):** To bypass complex APT dependencies and missing universe repository issues, both databases are deployed as Docker containers. They use the injected local registry mirrors, ensuring fast and reliable downloads.
* **Credential Management:** Upon installation, the script configures the databases and prompts for authentication details. Usernames, Passwords, and direct connection URIs are automatically and securely appended to `/root/db_credentials.txt`.

## Prerequisites
* **OS:** Ubuntu 20.04 / 22.04 / 24.04 LTS
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

1. Create a new file using nano:
```bash
nano setup.sh

```


2. Copy the entire contents of the `setup.sh` script and paste it into the terminal.
3. Save and exit (Press `Ctrl + O`, `Enter`, then `Ctrl + X`).
4. Make the script executable and run it:
```bash
chmod +x setup.sh
sudo ./setup.sh

```



## Installation Test Commands

After running the script, verify the successful setup using these commands:

### 1. Initial Setup (Mirrors, Proxy, Docker)

* **Verify APT Mirrors:**
```bash
cat /etc/apt/sources.list
cat /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null

```


* **Verify Docker & Mirrors:**
```bash
docker --version
docker info | grep "Registry Mirrors" -A 2

```


* **Verify Proxychains:**
```bash
proxychains4 curl ifconfig.me

```



### 2. Developer Tools

* **Verify Node.js & NPM:**
```bash
node -v
npm -v
npm config get registry

```


* **Verify Go (Golang):**
```bash
go version
go env GOPROXY

```



### 3. Databases

* **Verify MongoDB & Redis Docker Containers:**
```bash
docker ps

```


* **Check Databases Inside MongoDB:**
To see if your MongoDB was initialized correctly and check for existing databases, execute into the container using the mongosh shell:
```bash
docker exec -it mongodb mongosh -u YOUR_USERNAME -p YOUR_PASSWORD --authenticationDatabase admin

```


Once inside the shell (`test>`), run the following command to list all databases:
```javascript
show dbs;

```


*(By default, you should see `admin`, `config`, and `local`. If it's a fresh installation, there will be no other databases).*
* **Test Redis Connection:**
```bash
docker exec -it redis redis-cli ping

```



## Security Note

If you use the database configuration tools, your passwords and connection URIs will be saved in plain text at `/root/db_credentials.txt`. Because this file is located in the root directory, it is protected from standard users, but you should delete it or move it to a secure password manager once your setup is complete.

## License

This project is open-source and available under the [MIT License](https://www.google.com/search?q=LICENSE).

