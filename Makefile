APP_NAME = add_rabbitmq_queue
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
	bash test.sh
	
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