APP_NAME = rabbitmq
DOCKER_COMPOSE_FILE = ./docker-compose.yaml

# Auto-detect system architecture (amd64 for x86, arm64 for ARM-based systems)
ARCH = $(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')

.PHONY: all build docker-compose-up create-queue docker-compose-down logs clean test-rabbitmq

# Build the Go binary for the detected architecture
build:
	@rm -f $(APP_NAME)
	@echo "Building the Go application for $(ARCH) architecture..."
	GOOS=linux GOARCH=$(ARCH) go build -o $(APP_NAME) ./main.go

# Start services using Docker Compose
docker-compose-up: build
	@echo "Starting Docker Compose services..."
	env $(grep -v '^#' .env | xargs) docker-compose -f $(DOCKER_COMPOSE_FILE) up --build -d

# Create queues and wait for RabbitMQ to be ready
create-queue: docker-compose-up
	@echo "Waiting for RabbitMQ to be ready..."
	@until curl -s -o /dev/null -w "%{http_code}" http://localhost:15672/api/overview -u $${RABBITMQ_DEFAULT_USER}:$${RABBITMQ_DEFAULT_PASS} | grep -q 200; do \
		echo "RabbitMQ is not ready yet. Waiting..."; \
		sleep 5; \
	done
	@echo "RabbitMQ is ready. Creating queues..."
	@docker-compose -f $(DOCKER_COMPOSE_FILE) up --build -d go-app

# Stop services using Docker Compose
docker-compose-down:
	@echo "Stopping Docker Compose services..."
	docker-compose -f $(DOCKER_COMPOSE_FILE) down -v

# View logs from Docker Compose services
logs:
	@echo "Fetching logs from $(APP_NAME)..."
	docker-compose -f $(DOCKER_COMPOSE_FILE) logs -f $(APP_NAME)

# Clean up build artifacts
clean:
	@echo "Cleaning up..."
	rm -f $(APP_NAME)

test-rabbitmq:
	@echo "Running tests for the RabbitMQ..."
	bash test.sh