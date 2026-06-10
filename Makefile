ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.PHONY: help up down pull-model start logs clean

.DEFAULT_GOAL := help

# Resolve model name: Command line NAME= takes precedence over DEFAULT_MODEL
MODEL_NAME = $(if $(NAME),$(NAME),$(DEFAULT_MODEL))

help:
	@echo "Homelab AI Backend Control"
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  start       Launch the Ollama backend container and pull the default model"
	@echo "  up          Launch the Ollama backend container in detached mode"
	@echo "  pull-model  Pull a model (Usage: make pull-model [NAME=model_name] - default: $(DEFAULT_MODEL))"
	@echo "  down        Stop and remove the Ollama backend container"
	@echo "  logs        Tail Ollama service logs"
	@echo "  clean       Stop container and delete persistent volumes"
	@echo "  help        Display this help message"

up:
	docker compose -f docker-compose.backend.yml up -d

pull-model:
	@echo "Pulling model: $(MODEL_NAME)..."
	docker exec -it ollama ollama pull $(MODEL_NAME)

start: up
	@echo "Waiting for Ollama to become ready..."
	@until docker exec ollama ollama list >/dev/null 2>&1; do \
		sleep 1; \
	done
	@$(MAKE) pull-model
	@echo ""
	@echo "Ollama API is ready!"
	@echo "Ollama API: http://localhost:$${OLLAMA_PORT:-11434}"

down:
	docker compose -f docker-compose.backend.yml down

logs:
	docker compose -f docker-compose.backend.yml logs -f

clean:
	docker compose -f docker-compose.backend.yml down -v
