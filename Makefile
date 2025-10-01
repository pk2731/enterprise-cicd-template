# Enterprise CI/CD Template Makefile
# Version: 1.0.0

.PHONY: help install build test lint security docker clean setup dev prod monitoring sonar

# Default target
.DEFAULT_GOAL := help

# Variables
NODE_VERSION := 18
PROJECT_NAME := enterprise-app
DOCKER_IMAGE := $(PROJECT_NAME)
DOCKER_TAG := latest
COMPOSE_FILE := docker-compose.yml

# Colors for output
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(GREEN)Enterprise CI/CD Template - Available Commands:$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(YELLOW)<target>$(NC)\n\nTargets:\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# =============================================================================
# SETUP & INSTALLATION
# =============================================================================

install: ## Install dependencies
	@echo "$(GREEN)Installing dependencies...$(NC)"
	npm ci
	@echo "$(GREEN)Dependencies installed successfully!$(NC)"

install-dev: ## Install development dependencies
	@echo "$(GREEN)Installing all dependencies (including dev)...$(NC)"
	npm ci --include=dev
	@echo "$(GREEN)All dependencies installed successfully!$(NC)"

setup: install ## Complete project setup
	@echo "$(GREEN)Setting up project...$(NC)"
	mkdir -p coverage logs tmp
	cp .env.example .env 2>/dev/null || true
	@echo "$(GREEN)Project setup complete!$(NC)"

# =============================================================================
# BUILD & DEVELOPMENT
# =============================================================================

build: ## Build the application
	@echo "$(GREEN)Building application...$(NC)"
	npm run build
	@echo "$(GREEN)Build completed successfully!$(NC)"

dev: ## Start development server
	@echo "$(GREEN)Starting development server...$(NC)"
	npm run dev

start: ## Start production server
	@echo "$(GREEN)Starting production server...$(NC)"
	npm start

# =============================================================================
# TESTING & QUALITY
# =============================================================================

test: ## Run all tests
	@echo "$(GREEN)Running tests...$(NC)"
	npm test

test-watch: ## Run tests in watch mode
	@echo "$(GREEN)Running tests in watch mode...$(NC)"
	npm run test:watch

test-coverage: ## Run tests with coverage
	@echo "$(GREEN)Running tests with coverage...$(NC)"
	npm run test:coverage

test-ci: ## Run tests for CI environment
	@echo "$(GREEN)Running CI tests...$(NC)"
	npm run test:ci

lint: ## Run linting
	@echo "$(GREEN)Running linter...$(NC)"
	npm run lint

lint-fix: ## Fix linting issues
	@echo "$(GREEN)Fixing linting issues...$(NC)"
	npm run lint:fix

format: ## Format code
	@echo "$(GREEN)Formatting code...$(NC)"
	npm run format

validate: lint test ## Run full validation (lint + test)
	@echo "$(GREEN)Validation completed successfully!$(NC)"

# =============================================================================
# SECURITY
# =============================================================================

security: ## Run security audit
	@echo "$(GREEN)Running security audit...$(NC)"
	npm audit
	npm run security

security-fix: ## Fix security vulnerabilities
	@echo "$(GREEN)Fixing security vulnerabilities...$(NC)"
	npm audit fix

# =============================================================================
# DOCKER OPERATIONS
# =============================================================================

docker-build: ## Build Docker image
	@echo "$(GREEN)Building Docker image...$(NC)"
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	@echo "$(GREEN)Docker image built successfully!$(NC)"

docker-build-dev: ## Build Docker image for development
	@echo "$(GREEN)Building development Docker image...$(NC)"
	docker build --target development -t $(DOCKER_IMAGE):dev .
	@echo "$(GREEN)Development Docker image built successfully!$(NC)"

docker-build-prod: ## Build Docker image for production
	@echo "$(GREEN)Building production Docker image...$(NC)"
	docker build --target production -t $(DOCKER_IMAGE):prod .
	@echo "$(GREEN)Production Docker image built successfully!$(NC)"

docker-run: ## Run Docker container
	@echo "$(GREEN)Running Docker container...$(NC)"
	docker run -d -p 3000:3000 --name $(PROJECT_NAME) $(DOCKER_IMAGE):$(DOCKER_TAG)

docker-stop: ## Stop Docker container
	@echo "$(GREEN)Stopping Docker container...$(NC)"
	docker stop $(PROJECT_NAME) || true
	docker rm $(PROJECT_NAME) || true

docker-logs: ## Show Docker container logs
	docker logs -f $(PROJECT_NAME)

# =============================================================================
# DOCKER COMPOSE OPERATIONS
# =============================================================================

up: ## Start all services with Docker Compose
	@echo "$(GREEN)Starting all services...$(NC)"
	docker-compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)Services started successfully!$(NC)"

down: ## Stop all services
	@echo "$(GREEN)Stopping all services...$(NC)"
	docker-compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)Services stopped successfully!$(NC)"

restart: down up ## Restart all services

logs: ## Show logs for all services
	docker-compose -f $(COMPOSE_FILE) logs -f

ps: ## Show running services
	docker-compose -f $(COMPOSE_FILE) ps

# =============================================================================
# ENVIRONMENT-SPECIFIC COMMANDS
# =============================================================================

dev-full: ## Start full development environment
	@echo "$(GREEN)Starting full development environment...$(NC)"
	docker-compose -f $(COMPOSE_FILE) --profile monitoring up -d
	@echo "$(GREEN)Full development environment started!$(NC)"

prod: ## Start production-like environment
	@echo "$(GREEN)Starting production-like environment...$(NC)"
	docker-compose -f $(COMPOSE_FILE) --profile production up -d
	@echo "$(GREEN)Production-like environment started!$(NC)"

monitoring: ## Start monitoring stack
	@echo "$(GREEN)Starting monitoring stack...$(NC)"
	docker-compose -f $(COMPOSE_FILE) --profile monitoring up -d prometheus grafana
	@echo "$(GREEN)Monitoring stack started!$(NC)"
	@echo "$(YELLOW)Grafana: http://localhost:3001 (admin/admin)$(NC)"
	@echo "$(YELLOW)Prometheus: http://localhost:9090$(NC)"

sonar: ## Start SonarQube for code analysis
	@echo "$(GREEN)Starting SonarQube...$(NC)"
	docker-compose -f $(COMPOSE_FILE) --profile sonar up -d sonarqube
	@echo "$(GREEN)SonarQube started!$(NC)"
	@echo "$(YELLOW)SonarQube: http://localhost:9000 (admin/admin)$(NC)"

# =============================================================================
# DATABASE OPERATIONS
# =============================================================================

db-migrate: ## Run database migrations
	@echo "$(GREEN)Running database migrations...$(NC)"
	npm run db:migrate

db-seed: ## Seed database with test data
	@echo "$(GREEN)Seeding database...$(NC)"
	npm run db:seed

db-reset: ## Reset database
	@echo "$(GREEN)Resetting database...$(NC)"
	npm run db:reset

# =============================================================================
# DEPLOYMENT
# =============================================================================

deploy-dev: ## Deploy to development environment
	@echo "$(GREEN)Deploying to development...$(NC)"
	./scripts/deploy-dev.sh

deploy-staging: ## Deploy to staging environment
	@echo "$(GREEN)Deploying to staging...$(NC)"
	./scripts/deploy-staging.sh

# =============================================================================
# MAINTENANCE & CLEANUP
# =============================================================================

clean: ## Clean temporary files and dependencies
	@echo "$(GREEN)Cleaning temporary files...$(NC)"
	rm -rf node_modules coverage .nyc_output dist build tmp logs/*.log
	docker system prune -f
	@echo "$(GREEN)Cleanup completed!$(NC)"

clean-docker: ## Clean Docker images and containers
	@echo "$(GREEN)Cleaning Docker resources...$(NC)"
	docker-compose -f $(COMPOSE_FILE) down -v --remove-orphans
	docker system prune -af --volumes
	@echo "$(GREEN)Docker cleanup completed!$(NC)"

health: ## Check application health
	@echo "$(GREEN)Checking application health...$(NC)"
	curl -f http://localhost:3000/health || echo "$(RED)Application is not healthy$(NC)"

status: ## Show project status
	@echo "$(GREEN)Project Status:$(NC)"
	@echo "Node.js version: $(shell node --version)"
	@echo "NPM version: $(shell npm --version)"
	@echo "Docker version: $(shell docker --version)"
	@echo "Docker Compose version: $(shell docker-compose --version)"
	@echo ""
	@echo "$(GREEN)Services Status:$(NC)"
	@docker-compose -f $(COMPOSE_FILE) ps 2>/dev/null || echo "No services running"

# =============================================================================
# CI/CD PIPELINE SIMULATION
# =============================================================================

ci: install lint security test-coverage build ## Run complete CI pipeline
	@echo "$(GREEN)CI Pipeline completed successfully!$(NC)"

cd: docker-build ## Run CD pipeline (build image)
	@echo "$(GREEN)CD Pipeline completed successfully!$(NC)"

pipeline: ci cd ## Run full CI/CD pipeline
	@echo "$(GREEN)Full CI/CD Pipeline completed successfully!$(NC)"

# =============================================================================
# UTILITIES
# =============================================================================

check-deps: ## Check for dependency updates
	@echo "$(GREEN)Checking for dependency updates...$(NC)"
	npm outdated

update-deps: ## Update dependencies
	@echo "$(GREEN)Updating dependencies...$(NC)"
	npm update
	@echo "$(GREEN)Dependencies updated!$(NC)"

docs: ## Generate documentation
	@echo "$(GREEN)Generating documentation...$(NC)"
	npm run docs || echo "$(YELLOW)Documentation generation not configured$(NC)"