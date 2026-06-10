ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.PHONY: help up down logs clean backend-up backend-down backend-logs backend-clean frontend-up frontend-down frontend-logs frontend-clean pull-model start-backend

.DEFAULT_GOAL := help

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
	@echo "  frontend-up    Launch Open WebUI frontend container"
	@echo "  frontend-down  Stop Open WebUI frontend container"
	@echo "  frontend-logs  Tail Open WebUI service logs"
	@echo "  frontend-clean Stop Open WebUI frontend container and delete its database volume"

# --- Combined Stack ---

up: backend-up frontend-up

down: frontend-down backend-down

logs:
	docker compose -f docker-compose.backend.yml -f docker-compose.yml logs -f

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
	docker compose -f docker-compose.yml up -d

frontend-down:
	docker compose -f docker-compose.yml down

frontend-logs:
	docker compose -f docker-compose.yml logs -f

frontend-clean:
	docker compose -f docker-compose.yml down -v
