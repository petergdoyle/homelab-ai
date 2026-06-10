ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.PHONY: help up down logs clean backend-up backend-down backend-logs backend-clean frontend-up frontend-down frontend-logs frontend-clean pull-model start-backend mac-install mac-start mac-stop mac-pull

.DEFAULT_GOAL := help

# Resolve default Ollama URL: check env first, fallback to host.docker.internal
DEFAULT_URL = $(if $(OLLAMA_BASE_URL),$(OLLAMA_BASE_URL),http://host.docker.internal:11434)

# Resolve model name: Command line NAME= takes precedence over DEFAULT_MODEL
MODEL_NAME = $(if $(NAME),$(NAME),$(DEFAULT_MODEL))

help:
	@echo "Homelab AI Control Interface"
	@echo "----------------------------"
	@echo "Manage your local AI stack (Ollama Backend & Open WebUI Frontend)."
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Combined Stack Targets:"
	@echo "  up             Launch both Frontend and Backend stacks"
	@echo "  down           Stop both Frontend and Backend stacks"
	@echo "  logs           Tail logs for both stacks"
	@echo "  clean          Stop both stacks and delete all persistent volumes"
	@echo ""
	@echo "Backend Stack (Ollama) Targets:"
	@echo "  backend-up     Launch Ollama backend container"
	@echo "  backend-down   Stop Ollama backend container"
	@echo "  backend-logs   Tail Ollama service logs"
	@echo "  backend-clean  Stop Ollama backend container and delete its database volume"
	@echo "  start-backend  Launch Ollama backend and pull the default model ($(DEFAULT_MODEL))"
	@echo "  pull-model     Pull a model (Usage: make pull-model [NAME=model_name])"
	@echo ""
	@echo "Frontend Stack (Open WebUI) Targets:"
	@echo "  frontend-up    Launch Open WebUI frontend container (Interactive prompt for Backend URL)"
	@echo "  frontend-down  Stop Open WebUI frontend container"
	@echo "  frontend-logs  Tail Open WebUI service logs"
	@echo "  frontend-clean Stop Open WebUI frontend container and delete its database volume"
	@echo ""
	@echo "Native macOS (Non-Dockerized Backend) Targets:"
	@echo "  mac-install    Install Ollama natively via Homebrew Cask"
	@echo "  mac-start      Start native Ollama app/daemon and pull default model"
	@echo "  mac-stop       Quit native Ollama app and stop CLI daemon"
	@echo "  mac-pull       Pull model natively (Usage: make mac-pull [NAME=model_name])"

# --- Combined Stack ---

up: backend-up frontend-up

down: frontend-down backend-down

logs:
	@docker compose -f docker-compose.backend.yml logs -f & docker compose -f docker-compose.yml logs -f; wait

clean: frontend-clean backend-clean

# --- Backend Stack ---

backend-up:
	docker compose -f docker-compose.backend.yml up -d

backend-down:
	docker compose -f docker-compose.backend.yml down

backend-logs:
	docker compose -f docker-compose.backend.yml logs -f

backend-clean:
	docker compose -f docker-compose.backend.yml down -v

pull-model:
	@echo "Pulling model: $(MODEL_NAME)..."
	docker exec -it ollama ollama pull $(MODEL_NAME)

start-backend: backend-up
	@echo "Waiting for Ollama to become ready..."
	@until docker exec ollama ollama list >/dev/null 2>&1; do \
		sleep 1; \
	done
	@$(MAKE) pull-model
	@echo ""
	@echo "Ollama API is ready!"
	@echo "Ollama API URL: http://localhost:$${OLLAMA_PORT:-11434}"

# --- Frontend Stack ---

frontend-up:
	@printf "Enter Ollama Backend URL [default: $(DEFAULT_URL)]: "; \
	read url; \
	url=$${url:-$(DEFAULT_URL)}; \
	echo "Starting Frontend using OLLAMA_BASE_URL=$$url..."; \
	OLLAMA_BASE_URL=$$url docker compose -f docker-compose.yml up -d

frontend-down:
	docker compose -f docker-compose.yml down

frontend-logs:
	docker compose -f docker-compose.yml logs -f

frontend-clean:
	docker compose -f docker-compose.yml down -v

# --- Native macOS Controls ---

mac-install:
	@echo "Installing Ollama natively on macOS via Homebrew..."
	@if command -v brew >/dev/null 2>&1; then \
		brew install --cask ollama; \
	else \
		echo "Error: Homebrew is not installed. Please install it from https://brew.sh/"; \
		exit 1; \
	fi

mac-start:
	@echo "Starting native macOS Ollama..."
	@if [ -d "/Applications/Ollama.app" ] || [ -d "$(HOME)/Applications/Ollama.app" ]; then \
		open -a Ollama; \
	else \
		echo "Ollama.app not found in Applications. Starting background CLI daemon (ollama serve)..."; \
		ollama serve >/dev/null 2>&1 & \
	fi
	@echo "Waiting for native Ollama API to become ready..."
	@until curl -s http://localhost:11434 >/dev/null 2>&1; do \
		sleep 1; \
	done
	@$(MAKE) mac-pull
	@echo ""
	@echo "Native macOS Ollama is ready at http://localhost:11434"

mac-stop:
	@echo "Stopping native macOS Ollama..."
	@osascript -e 'quit app "Ollama"' >/dev/null 2>&1 || true
	@pkill -f "ollama serve" >/dev/null 2>&1 || true
	@pkill -f "ollama" >/dev/null 2>&1 || true
	@echo "Native Ollama stopped."

mac-pull:
	@echo "Pulling model natively: $(MODEL_NAME)..."
	@ollama pull $(MODEL_NAME)
