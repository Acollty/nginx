# Nginx with Certbot - Makefile
#
# Usage:
#   make build    - Build Docker image locally
#   make deploy   - Build and push Docker image to registry
#   make up       - Start containers
#   make help     - Show this help message

.PHONY: help build deploy deploy-aliyun up down restart logs shell nginx-reload nginx-test cert-list cert-renew cert-test cert-logs clean init info login

# ============================================================================
# Configuration
# ============================================================================

# Version info
VERSION ?= $(shell git describe --tags --always 2>/dev/null || echo "1.0.0")
COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || powershell -Command "Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'")

# Docker image configuration
REGISTRY ?= docker.io
NAMESPACE ?= titantalk
IMAGE_NAME ?= nginx
FULL_IMAGE := $(REGISTRY)/$(NAMESPACE)/$(IMAGE_NAME)
CONTAINER_NAME := nginx

# Aliyun registry configuration
ALIYUN_REGISTRY ?= registry.cn-shenzhen.aliyuncs.com
ALIYUN_NAMESPACE ?= acoll
ALIYUN_REPO_API := $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/$(IMAGE_NAME)

# Build configuration
DOCKER_BUILDKIT ?= 1

# ============================================================================
# Help
# ============================================================================

help:
	@echo "=========================================="
	@echo "Nginx with Certbot - Makefile"
	@echo "=========================================="
	@echo ""
	@echo "Docker Commands:"
	@echo "  make build            Build Docker image locally"
	@echo "  make deploy           Build and push Docker image to Docker Hub"
	@echo "  make deploy-aliyun    Build and push Docker image to Aliyun registry"
	@echo "  make login            Login to Docker registry"
	@echo "  make clean            Clean local Docker images"
	@echo "  make info             Show build configuration"
	@echo ""
	@echo "Container Commands:"
	@echo "  make up               Start containers"
	@echo "  make down             Stop and remove containers"
	@echo "  make restart          Restart containers"
	@echo "  make logs             View container logs"
	@echo "  make shell            Enter container shell"
	@echo ""
	@echo "Nginx Commands:"
	@echo "  make nginx-reload     Reload Nginx configuration"
	@echo "  make nginx-test       Test Nginx configuration"
	@echo ""
	@echo "Certificate Commands:"
	@echo "  make cert-list        List all certificates"
	@echo "  make cert-renew       Manually renew certificates"
	@echo "  make cert-test        Test certificate renewal"
	@echo "  make cert-logs        View certificate renewal logs"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make init             Initialize data directories"
	@echo ""
	@echo "Configuration:"
	@echo "  REGISTRY   = $(REGISTRY)"
	@echo "  NAMESPACE  = $(NAMESPACE)"
	@echo "  VERSION    = $(VERSION)"
	@echo ""
	@echo "Image:"
	@echo "  $(FULL_IMAGE):$(VERSION)"
	@echo ""

# ============================================================================
# Build: Build Docker image locally
# ============================================================================

build:
	@echo "=========================================="
	@echo "Building Docker Image"
	@echo "=========================================="
	@echo "Version:    $(VERSION)"
	@echo "Commit:     $(COMMIT)"
	@echo "Build Time: $(BUILD_TIME)"
	@echo ""
	@docker build \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg BUILD_TIME=$(BUILD_TIME) \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(FULL_IMAGE):$(VERSION) \
		-t $(FULL_IMAGE):latest \
		.
	@echo ""
	@echo "=========================================="
	@echo "Build Complete!"
	@echo "=========================================="
	@echo "Images built:"
	@echo "  $(IMAGE_NAME):$(VERSION)"
	@echo "  $(FULL_IMAGE):$(VERSION)"
	@echo "  $(FULL_IMAGE):latest"
	@echo ""

# ============================================================================
# Deploy: Build and push Docker image to registry
# ============================================================================

deploy:
	@echo "=========================================="
	@echo "Building and Pushing Docker Image"
	@echo "=========================================="
	@echo "Version:    $(VERSION)"
	@echo "Commit:     $(COMMIT)"
	@echo "Build Time: $(BUILD_TIME)"
	@echo ""
	@echo "[1/3] Building image..."
	@docker build \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg BUILD_TIME=$(BUILD_TIME) \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(FULL_IMAGE):$(VERSION) \
		-t $(FULL_IMAGE):latest \
		.
	@echo ""
	@echo "[2/3] Pushing version tag..."
	@docker push $(FULL_IMAGE):$(VERSION)
	@echo ""
	@echo "[3/3] Pushing latest tag..."
	@docker push $(FULL_IMAGE):latest
	@echo ""
	@echo "=========================================="
	@echo "Deploy Complete!"
	@echo "=========================================="
	@echo "Images pushed:"
	@echo "  $(FULL_IMAGE):$(VERSION)"
	@echo "  $(FULL_IMAGE):latest"
	@echo ""

# ============================================================================
# Login: Login to Docker registry
# ============================================================================

login:
	@echo "Logging in to $(REGISTRY)..."
	@docker login $(REGISTRY)

# ============================================================================
# Deploy Aliyun: Build and push Docker image to Aliyun registry
# ============================================================================

deploy-aliyun:
	@echo "=========================================="
	@echo "Building and Pushing to Aliyun Registry"
	@echo "=========================================="
	@echo "Version:    $(VERSION)"
	@echo "Commit:     $(COMMIT)"
	@echo "Build Time: $(BUILD_TIME)"
	@echo ""
	@echo "[1/3] Building image..."
	@docker build \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg BUILD_TIME=$(BUILD_TIME) \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(ALIYUN_REPO_API):$(VERSION) \
		-t $(ALIYUN_REPO_API):latest \
		.
	@echo ""
	@echo "[2/3] Pushing version tag (with retry)..."
	@for i in 1 2 3; do \
		echo "Attempt $$i of 3..."; \
		if docker push $(ALIYUN_REPO_API):$(VERSION); then \
			break; \
		else \
			if [ $$i -eq 3 ]; then \
				echo "Failed to push version tag after 3 attempts"; \
				exit 1; \
			fi; \
			echo "Push failed, retrying in 5 seconds..."; \
			sleep 5; \
		fi; \
	done
	@echo ""
	@echo "[3/3] Pushing latest tag (with retry)..."
	@for i in 1 2 3; do \
		echo "Attempt $$i of 3..."; \
		if docker push $(ALIYUN_REPO_API):latest; then \
			break; \
		else \
			if [ $$i -eq 3 ]; then \
				echo "Failed to push latest tag after 3 attempts"; \
				exit 1; \
			fi; \
			echo "Push failed, retrying in 5 seconds..."; \
			sleep 5; \
		fi; \
	done
	@echo ""
	@echo "=========================================="
	@echo "Deploy to Aliyun Complete!"
	@echo "=========================================="
	@echo "Images pushed:"
	@echo "  $(ALIYUN_REPO_API):$(VERSION)"
	@echo "  $(ALIYUN_REPO_API):latest"
	@echo ""

# ============================================================================
# Container Management
# ============================================================================

up:
	@echo "Starting containers..."
	@docker-compose up -d

down:
	@echo "Stopping containers..."
	@docker-compose down

restart:
	@echo "Restarting containers..."
	@docker-compose restart

logs:
	@docker-compose logs -f

shell:
	@docker exec -it $(CONTAINER_NAME) /bin/bash

# ============================================================================
# Nginx Management
# ============================================================================

nginx-reload:
	@echo "Reloading Nginx configuration..."
	@docker exec $(CONTAINER_NAME) nginx -s reload

nginx-test:
	@echo "Testing Nginx configuration..."
	@docker exec $(CONTAINER_NAME) nginx -t

# ============================================================================
# Certificate Management
# ============================================================================

cert-list:
	@docker exec $(CONTAINER_NAME) cert list

cert-renew:
	@echo "Renewing certificates..."
	@docker exec $(CONTAINER_NAME) cert renew

cert-test:
	@echo "Testing certificate renewal..."
	@docker exec $(CONTAINER_NAME) cert test

cert-logs:
	@docker exec $(CONTAINER_NAME) tail -f /var/log/certbot/renew.log

# ============================================================================
# Clean: Clean local Docker images
# ============================================================================

clean:
	@echo "=========================================="
	@echo "Cleaning Local Docker Images"
	@echo "=========================================="
	@echo "Stopping containers..."
	@docker-compose down -v 2>/dev/null || true
	@echo ""
	@echo "Removing images..."
	@docker rmi $(IMAGE_NAME):$(VERSION) 2>/dev/null || echo "  Image not found: $(IMAGE_NAME):$(VERSION)"
	@docker rmi $(FULL_IMAGE):$(VERSION) 2>/dev/null || echo "  Image not found: $(FULL_IMAGE):$(VERSION)"
	@docker rmi $(FULL_IMAGE):latest 2>/dev/null || echo "  Image not found: $(FULL_IMAGE):latest"
	@echo ""
	@echo "=========================================="
	@echo "Clean Complete!"
	@echo "=========================================="

# ============================================================================
# Init: Initialize data directories
# ============================================================================

init:
	@echo "Initializing data directories..."
	@mkdir -p data/letsencrypt data/html data/logs/nginx data/logs/certbot
	@chmod -R 755 data/
	@echo "Data directories created successfully!"

# ============================================================================
# Info: Show build configuration
# ============================================================================

info:
	@echo "=========================================="
	@echo "Build Configuration"
	@echo "=========================================="
	@echo "Registry:   $(REGISTRY)"
	@echo "Namespace:  $(NAMESPACE)"
	@echo "Image Name: $(IMAGE_NAME)"
	@echo ""
	@echo "Version:    $(VERSION)"
	@echo "Commit:     $(COMMIT)"
	@echo "Build Time: $(BUILD_TIME)"
	@echo ""
	@echo "Full Image:"
	@echo "  $(FULL_IMAGE):$(VERSION)"
	@echo "  $(FULL_IMAGE):latest"
	@echo "=========================================="

# ============================================================================
# Default target
# ============================================================================

.DEFAULT_GOAL := help
