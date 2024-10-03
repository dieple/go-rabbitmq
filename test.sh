#!/bin/bash

# Load environment variables from .env file if present
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Define variables
RABBITMQ_URL="http://localhost:15672"  # Modify this if necessary
RETRY_INTERVAL=5  # Retry every 5 seconds
RETRIES=10        # Maximum number of retries

# Parse RABBITMQ_QUEUE as an array by splitting on commas
IFS=',' read -r -a QUEUES <<< "$RABBITMQ_QUEUE"

# Function to check RabbitMQ connection
check_rabbitmq() {
    echo "Checking RabbitMQ connection..."

    for ((i=1; i<=RETRIES; i++)); do
        # Check if the RabbitMQ API is accessible
        if curl -s "$RABBITMQ_URL/api/overview" -u $RABBITMQ_DEFAULT_USER:$RABBITMQ_DEFAULT_PASS | grep -q '"message_stats"'; then
            echo "RabbitMQ is reachable."
            return 0
        else
            echo "RabbitMQ is not reachable, attempt $i of $RETRIES. Retrying in $RETRY_INTERVAL seconds..."
            sleep $RETRY_INTERVAL
        fi
    done

    echo "RabbitMQ is not reachable after $RETRIES attempts!"
    return 1
}

# Function to check if the required queues exist
check_queues() {
    echo "Checking if required queues have been created..."

    for queue in "${QUEUES[@]}"; do
        if curl -s "$RABBITMQ_URL/api/queues" -u $RABBITMQ_DEFAULT_USER:$RABBITMQ_DEFAULT_PASS | grep -q "\"name\":\"$queue\""; then
            echo "Queue '$queue' exists."
        else
            echo "Queue '$queue' does NOT exist!"
            return 1
        fi
    done

    return 0
}

###
# Main
###
if check_rabbitmq; then
    check_queues
else
    echo "Skipping queue check because RabbitMQ is not reachable."
    exit 1
fi