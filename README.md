# ubuntu-ir-init

A simple, interactive Bash script designed to automate the initial configuration of fresh Ubuntu servers, specifically optimized for users and servers located in Iran. 

Dealing with network restrictions and slow download speeds can be a hassle when setting up a new server. This script provides a quick menu-driven interface to set up fast local mirrors, install Docker with functional registry mirrors, and configure Proxychains for restricted access.

## ✨ Features

- **Interactive Menu:** Run tasks individually or execute them all at once.
- **APT Mirrors Setup:** Replaces default Ubuntu archives with fast, reliable Iranian mirrors (IranServer, ArvanCloud, Radin).
- **Docker & Docker Compose:** Installs Docker and automatically configures `daemon.json` to use Iranian registry mirrors (IranServer) to bypass Docker Hub restrictions.
- **Proxychains Configuration:** Installs `proxychains4` and allows you to dynamically set up your custom proxy (e.g., SOCKS5) right from the terminal.

## 📋 Prerequisites

- A machine running **Ubuntu** (Tested on 20.04 LTS and 22.04 LTS).
- **Root** privileges (The script must be run with `sudo` or as root).

## 🚀 Usage

1. **Clone the repository:**
```bash
   git clone [https://github.com/YOUR_USERNAME/ir-server-bootstrap.git](https://github.com/YOUR_USERNAME/ir-server-bootstrap.git)
   cd ir-server-bootstrap
