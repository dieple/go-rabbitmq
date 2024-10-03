# RabbitMQ Service with Docker and Go

This repository sets up a RabbitMQ service using Docker Compose, and a Go application that interacts with RabbitMQ to create queues and perform health checks. It also includes a test script to verify the RabbitMQ connection.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Clone the Repository](#clone-the-repository)
  - [Configuration](#configuration)
  - [Build and Run](#build-and-run)
- [Testing RabbitMQ Connectivity](#testing-rabbitmq-connectivity)
- [Makefile Targets](#makefile-targets)
- [Useful Docker Commands](#useful-docker-commands)
- [Contributing](#contributing)

## Prerequisites

To run this project, you will need:

- [Go](https://golang.org/doc/install) (1.18 or later)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/dieple/go-rabbitmq
cd go-rabbitmq
```

### Configuration

1. Create a `.env` file at the root of your project to define your environment variables. Here's a sample:

    ```bash
    RABBITMQ_DEFAULT_USER=guest
    RABBITMQ_DEFAULT_PASS=guest
    RABBITMQ_PORT=5672
    RABBITMQ_MGMT_PORT=15672
    RABBITMQ_QUEUE=queue1,queue2,queue3
    ```

2. Update any variables as necessary to match your environment.

### Build and Run

To build and run the RabbitMQ service and the Go application:

1. Build and run the Go application and RabbitMQ service using Docker Compose:

    ```bash
    make docker-compose-up
    ```

2. This command builds the Go binary for your architecture, starts RabbitMQ, and exposes the necessary ports (5672 for RabbitMQ and 15672 for the management UI).

3. To verify RabbitMQ is running, open your browser and navigate to [http://localhost:15672](http://localhost:15672). You can log in using the credentials in the `.env` file (default: `guest` / `guest`).

### Testing RabbitMQ Connectivity

You can test RabbitMQ connectivity using the provided `test.sh` script:

```bash
make test-rabbitmq
```

This script checks if RabbitMQ is running by querying its management API. It uses the credentials from the `.env` file to perform the check.

## Makefile Targets

- `build`: Builds the Go binary.
- `docker-compose-up`: Builds the Go application and starts RabbitMQ and other services via Docker Compose.
- `docker-compose-down`: Stops and removes Docker Compose services and volumes.
- `logs`: Fetches logs from the RabbitMQ service.
- `clean`: Cleans up the Go build artifacts.
- `test-services`: Runs the RabbitMQ connectivity test.

## Useful Docker Commands

- View RabbitMQ logs:

    ```bash
    docker-compose logs -f rabbitmq
    ```

- Stop the services:

    ```bash
    make docker-compose-down
    ```

- Check the RabbitMQ service status:

    ```bash
    docker-compose ps
    ```

- Connect to the RabbitMQ management UI:

    Go to [http://localhost:15672](http://localhost:15672) and log in with the credentials from your `.env` file.

## Contributing

Feel free to contribute to this project by submitting issues or pull requests. Please follow the standard [GitHub Flow](https://guides.github.com/introduction/flow/) for contributions.

---
