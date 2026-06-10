# Homelab AI Decoupled Stack

A split-architecture containerized AI environment separating the high-compute **Ollama Backend** from the user-facing **Open WebUI Frontend** to optimize performance, hardware acceleration, and horizontal scaling in the homelab.

- **Ollama Backend**: Intended to be deployed locally on a dedicated AI-capable machine with hardware acceleration (e.g. Mac Mini / GPU Host).
- **Open WebUI Frontend**: Intended to be provisioned and deployed inside an unprivileged LXC container on the Proxmox stack via `homelab-factory`, proxying queries back to the Ollama backend.

For detailed network diagrams and deployment models, see the [Architecture & Deployment Guide](./docs/architecture.md).

---

## 🚀 Split Deployment Quick Start

### 1. Backend Setup

Choose one of the following methods to start your Ollama engine:

#### Option A: Dockerized Backend (Linux / General Hosts)
To run the Ollama engine inside a container and pull the default model (`qwen2.5-coder:7b`):
```bash
make start-backend
```

#### Option B: Native macOS Backend (Recommended for Apple Silicon Mac hosts)
Docker on macOS cannot access Apple's native GPU/Metal acceleration directly. For maximum performance (utilizing unified memory and Apple Silicon Neural Engine), run Ollama natively:
1. Install Ollama via Homebrew Cask:
   ```bash
   make mac-install
   ```
2. Start the native app/daemon and download the default model:
   ```bash
   make mac-start
   ```

- **Ollama API Port**: Exposes port `11434` (configurable via `OLLAMA_PORT` in `.env`).

### 2. Frontend Setup (Proxmox LXC Container / Local Dev)

#### Option A: Deploying via `homelab-factory` (Production)
The frontend is deployed automatically onto Proxmox using Ansible playbooks. The deployment clones this repository and spins up the Open WebUI frontend, configuring it to talk to the backend IP.

#### Option B: Running Frontend Locally for Testing
To spin up the Open WebUI frontend inside Docker on your development machine:
```bash
make frontend-up
```
*Note: The script will prompt you for the Ollama Backend URL. Press Enter to use the default `http://host.docker.internal:11434` (which connects to your native macOS Ollama or local dockerized backend).*

- **Open WebUI Dashboard Port**: Exposes port `3000` (configurable via `WEBUI_PORT` in `.env`).
- **First Sign In**: The first account registered on the fresh Open WebUI database will be automatically granted Admin rights.

---

## ⚙️ Configuration & Environment

Configuration is managed via the [.env](./.env) file:

- **`OLLAMA_PORT`**: Exposes the Ollama API engine port (Default: `11434`).
- **`WEBUI_PORT`**: Exposes the Open WebUI panel port (Default: `3000`).
- **`DEFAULT_MODEL`**: The LLM model to pull on start (Default: `qwen2.5-coder:7b`).
- **`OLLAMA_BASE_URL`**: The API target endpoint that Open WebUI contacts (Default: `http://host.docker.internal:11434`).

---

## 🛠️ Management Commands

All operations are automated using the root [Makefile](./Makefile):

### Combined Stack Controls (Dockerized)
- **`make up`**: Spins up both Frontend and Backend containers.
- **`make down`**: Stops both Frontend and Backend containers.
- **`make logs`**: Tails logs from all active services in both compose stacks.
- **`make clean`**: Shuts down the stack and **purges all persistent database volumes** (clears all user profiles and models).

### Dedicated Backend Controls (Dockerized)
- **`make backend-up`**: Runs the Ollama container only.
- **`make backend-down`**: Stops the Ollama container.
- **`make backend-logs`**: Tails the Ollama engine logs.
- **`make start-backend`**: Starts Ollama and pulls the configured default model.
- **`make pull-model`**: Manually pull a model (Usage: `make pull-model NAME=llama3`).

### Dedicated Frontend Controls (Dockerized)
- **`make frontend-up`**: Runs the Open WebUI container only (prompts for backend URL).
- **`make frontend-down`**: Stops the Open WebUI container.
- **`make frontend-logs`**: Tails the Open WebUI UI logs.

### Native macOS Controls (Non-Dockerized)
- **`make mac-install`**: Automatically install Ollama natively on macOS via Homebrew.
- **`make mac-start`**: Opens native `Ollama.app` (or starts CLI daemon) and pulls default model.
- **`make mac-stop`**: Gracefully quits native Ollama app and stops background CLI processes.
- **`make mac-pull`**: Manually pull a model natively (Usage: `make mac-pull NAME=model_name`).

---

## ⚡ Hardware Acceleration (GPU support)

To accelerate LLM inference speeds on the backend node:

### Linux with NVIDIA GPU
1. Ensure the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) is installed on the host.
2. Edit [docker-compose.backend.yml](./docker-compose.backend.yml) and uncomment the `deploy` block under the `ollama` service.
3. Reload the stack:
   ```bash
   make backend-down && make backend-up
   ```
