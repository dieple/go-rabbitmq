# Stage 1: Build the Go app
FROM golang:1.23-alpine AS builder

# Set working directory inside the container
WORKDIR /app

# Copy go.mod and go.sum and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the entire source code and build the application binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o add_rabbitmq_queue ./main.go

# Stage 2: Create a minimal image to run the Go app as a non-root user
FROM alpine:latest

# Create a non-root user and group
RUN addgroup -S voxgroup && adduser -S voxuser -G voxgroup

# Set working directory
WORKDIR /app

# Copy only the binary from the builder stage
COPY --from=builder /app/add_rabbitmq_queue .
COPY config.json .

# Create logs directory and set permissions
RUN mkdir -p logs && chown -R voxuser:voxgroup /app/logs

# Switch to the non-root user
USER voxuser

# Run the Go app
ENTRYPOINT ["/app/add_rabbitmq_queue"]