# Homelab AI Backend

A containerized local intelligence backend hosting **Ollama** and **Open WebUI** to power the **Atmosphere IDE** VS Code extension.

---

## 🚀 Quick Start

To spin up the services and download the default model (`qwen2.5-coder:7b`) in one command:

```bash
make start
```

This will:
1. Load environment variables from `.env`.
2. Start the Ollama container and Open WebUI.
3. Wait for the Ollama API to be ready.
4. Execute `ollama pull` inside the container to fetch the default model (with progress indicator).

Once booted, you can access:
- **Ollama API**: `http://localhost:11434`
- **Open WebUI**: `http://localhost:3000`

---

## ⚙️ Configuration & Environment

The configurations are stored in the [.env](./.env) file:

- **`OLLAMA_PORT`**: Exposes the Ollama API port (Defaults to `11434`).
- **`WEBUI_PORT`**: Exposes the Open WebUI frontend port (Defaults to `3000`).
- **`DEFAULT_MODEL`**: The model to automatically pull on start (Defaults to `qwen2.5-coder:7b`).

---

## ⚡ Hardware Acceleration (GPU support)

Running LLMs on CPUs can be slow. To enable GPU acceleration:

### NVIDIA GPUs (Linux Host)

1. Make sure you have installed the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) on your host.
2. Edit [docker-compose.yml](./docker-compose.yml) and uncomment the `deploy` configuration block under the `ollama` service:
   ```yaml
   deploy:
     resources:
       reservations:
         devices:
           - driver: nvidia
             count: all
             capabilities: [gpu]
   ```
3. Restart the stack:
   ```bash
   make down && make start
   ```

### Apple Silicon (Mac Host)
- If you run Docker Desktop on macOS, GPU support for Ollama inside containers is currently not directly supported through Docker container virtualization. 
- **Recommendation**: For maximum performance on Apple Silicon, run Ollama *natively* on your host mac (download from [ollama.com](https://ollama.com)), and point Open WebUI and Atmosphere to your native Ollama port (`http://localhost:11434`).

---

## 🛠️ Management Commands

All operations are automated through the root [Makefile](./Makefile):

- **`make start`**: Starts the containers and pulls the default model.
- **`make up`**: Runs containers in the background without pulling models.
- **`make pull`**: Pulls the default model configured in `.env`.
- **`make down`**: Stops and removes running containers (data remains safe).
- **`make logs`**: Tails Docker container logs.
- **`make clean`**: Stops the stack and **purges all persistent data volumes** (deletes all models and UI data).
