# Ubuntu IR Init 🚀

A comprehensive, modular Bash script designed for automated server provisioning in restricted network environments. Built specifically for developers dealing with "Iran-Access" networks, heavy filtering, and international sanctions (403 errors). 

This tool ensures that dependencies, databases, and developer environments are pulled from functional internal mirrors or correctly routed through bypass proxies without needing manual interventions.

## ✨ Core Features

### 1. 🛡️ Network & Bypass Capabilities
* **Local APT Mirrors:** Instantly swap default Ubuntu repos for high-speed local mirrors (IranServer, ArvanCloud).
* **Proxychains Integration:** Dynamically configure `proxychains4` via the terminal to tunnel specific commands.
* **Docker Registry Injection:** Installs Docker and auto-injects unblocked local registry mirrors into `daemon.json` to bypass Docker Hub restrictions.

### 2. 💻 Developer Tools Auto-Setup
Instead of fighting 403 errors from official sources, this script safely installs tools using local networks:
* **Node.js & NPM:** Installs Node and auto-configures the NPM registry to use functional Iranian mirrors (`registry.npmjs.ir`).
* **React CLI:** Sets up `create-react-app` globally.
* **Go (Golang):** Installs Go and configures `GOPROXY` to bypass module download restrictions.

### 3. 🗄️ Database Provisioning
* **MongoDB:** Installs the database, configures the service, and prompts for an admin username/password.
* **Redis:** Installs Redis server and optionally allows you to secure it with a custom password.
* **Credential Management:** All generated or inputted passwords are automatically and securely appended to `/root/db_credentials.txt` so you never lose them.

### 4. 🚨 Smart Error Handling
Every major installation step includes a status check. If a download fails, the script will halt and provide actionable hints, explaining whether the failure was due to network filtering, sanctions (403), or DNS poisoning.

## 📋 Prerequisites
* **OS:** Ubuntu 20.04 / 22.04 LTS
* **Access:** Root privileges required

## 🚀 Usage Guide

1. **Clone the repository:**
```bash
   git clone [https://github.com/mahanmntz/ubuntu-ir-init.git](https://github.com/mahanmntz/ubuntu-ir-init.git)
   cd ubuntu-ir-init

```

2. **Make the script executable:**

```bash
   chmod +x setup.sh

```

3. **Run the script as root:**

```bash
   sudo ./setup.sh

```

4. **Navigate the Menus:**
The script is fully interactive and modular. You can enter the **Initial Setup** menu, the **Developer Tools** menu, or the **Databases** menu to pick and choose your stack. Alternatively, select **Run EVERYTHING** for a complete zero-to-hero server setup.

## 🔒 Security Note

If you use the database configuration tools, your passwords will be saved in plain text at `/root/db_credentials.txt`. Because this file is located in the root directory, it is protected from standard users, but you should delete it or move it to a secure password manager once your setup is complete.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://www.google.com/search?q=https://github.com/mahanmntz/ubuntu-ir-init/issues). Found a new working mirror? Want to add another language (like Python) or a database (like PostgreSQL)? Pull requests are highly appreciated.

## 📝 License

This project is open-source and available under the [MIT License](https://www.google.com/search?q=LICENSE).

```
