# Homelab AI Decoupled Stack

A split-architecture containerized AI environment separating the high-compute **Ollama Backend** from the user-facing **Open WebUI Frontend** to optimize performance, hardware acceleration, and horizontal scaling in the homelab.

- **Ollama Backend**: Intended to be deployed locally on a dedicated AI-capable machine with hardware acceleration (e.g. Mac Mini / GPU Host).
- **Open WebUI Frontend**: Intended to be provisioned and deployed inside an unprivileged LXC container on the Proxmox stack via `homelab-factory`, proxying queries back to the Ollama backend.

---

## 🚀 Split Deployment Quick Start

### 1. Backend Setup (AI-Capable Machine / Mac Mini)
To deploy the backend database, run the Ollama engine, and pre-download the default code-assistant LLM (`qwen2.5-coder:7b`) in one command:

```bash
make start-backend
```

This will:
1. Load configurations from `.env`.
2. Start the Ollama engine inside Docker.
3. Poll the API until it's responsive.
4. Auto-execute `ollama pull qwen2.5-coder:7b` to fetch the model.

- **Ollama API Port**: Exposes port `11434` (configurable via `OLLAMA_PORT` in `.env`).

### 2. Frontend Setup (Proxmox LXC Container via `homelab-factory`)
The frontend is deployed automatically onto Proxmox using Ansible playbooks. The deployment clones this repository and spins up the Open WebUI frontend, configuring it to talk to the backend IP.

- **Open WebUI Dashboard Port**: Exposes port `3000` (configurable via `WEBUI_PORT` in `.env`).
- **First Sign In**: The first account registered on the fresh Open WebUI database will be automatically granted Admin rights.

---

## ⚙️ Configuration & Environment

Configuration is managed via the [.env](./.env) file:

- **`OLLAMA_PORT`**: Exposes the Ollama API engine port (Default: `11434`).
- **`WEBUI_PORT`**: Exposes the Open WebUI panel port (Default: `3000`).
- **`DEFAULT_MODEL`**: The LLM model to pull on start (Default: `qwen2.5-coder:7b`).
- **`OLLAMA_BASE_URL`**: The API target endpoint that Open WebUI contacts (Default: `http://192.168.20.11:11434` pointing to the Mac Mini).

---

## 🛠️ Management Commands

All operations are automated using the root [Makefile](./Makefile):

### Combined Stack Controls
- **`make up`**: Spins up both Frontend and Backend containers.
- **`make down`**: Stops both Frontend and Backend containers.
- **`make logs`**: Tails logs from all active services in both compose stacks.
- **`make clean`**: Shuts down the stack and **purges all persistent database volumes** (clears all user profiles and models).

### Dedicated Backend Controls
- **`make backend-up`**: Runs the Ollama container only.
- **`make backend-down`**: Stops the Ollama container.
- **`make backend-logs`**: Tails the Ollama engine logs.
- **`make start-backend`**: Starts Ollama and pulls the configured default model.
- **`make pull-model`**: Manually pull a model (Usage: `make pull-model NAME=llama3`).

### Dedicated Frontend Controls
- **`make frontend-up`**: Runs the Open WebUI container only.
- **`make frontend-down`**: Stops the Open WebUI container.
- **`make frontend-logs`**: Tails the Open WebUI UI logs.

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

### Apple Silicon (Mac Mini)
Ollama runs natively on Apple Silicon with full GPU support. If running Docker on macOS, container-to-host metal access is restricted.
*Recommendation*: For maximum performance on Mac hosts, install Ollama natively on macOS and configure the frontend to talk to your native instance port.
