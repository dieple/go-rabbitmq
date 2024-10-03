package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/streadway/amqp"
)

const (
	maxRetries   = 10              // Maximum number of retry attempts
	retryDelay   = 5 * time.Second  // Delay between retries
)

var (
	Cfg        *Config // Global variable for config
	once       sync.Once
	configPath string
)

// Config structure for the application
type Config struct {
	RabbitMQ RabbitMQConfig `json:"rabbitmq"`
}

// RabbitMQConfig structure for RabbitMQ settings
type RabbitMQConfig struct {
	URL       string        `json:"url"`
	User      string        `json:"rabbitmq_default_user"`
	Password  string        `json:"rabbitmq_default_pass"`
	Port      string        `json:"rabbitmq_port"`
	AdminPort string        `json:"rabbitmq_admin_port"`
	Queues    []QueueConfig `json:"queues"`
}

// QueueConfig defines the structure for queue configurations
type QueueConfig struct {
	Name       string `json:"name"`
	Durable    bool   `json:"durable"`
	AutoDelete bool   `json:"auto_delete"`
}

// LoadConfig loads the config from the given file path
func loadConfig(filePath string) (*Config, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var cfg Config
	decoder := json.NewDecoder(file)
	if err := decoder.Decode(&cfg); err != nil {
		return nil, err
	}

	// Override file-based config with environment variables
	overrideConfigWithEnv(&cfg)

	return &cfg, nil
}

// LoadConfigOrFatal loads the config or logs a fatal error if it fails
func loadConfigOrFatal() *Config {
	once.Do(func() {
		if envPath := os.Getenv("CONFIG_PATH"); envPath != "" {
			configPath = envPath
		}

		if configPath == "" {
			configPath = "config.json" // Default to config.json
		}

		// Get the absolute path of the config file
		absPath, err := filepath.Abs(configPath)
		if err != nil {
			log.Fatalf("Error resolving config path: %v", err)
		}

		cfg, err := loadConfig(absPath)
		if err != nil {
			log.Fatalf("Error loading config: %v", err)
		}

		Cfg = cfg // Assign loaded config to the global variable
	})

	return Cfg
}

// overrideConfigWithEnv overrides config values with environment variables
func overrideConfigWithEnv(cfg *Config) {
	cfg.RabbitMQ.URL = getEnv("RABBITMQ_URL", cfg.RabbitMQ.URL)
	cfg.RabbitMQ.User = getEnv("RABBITMQ_DEFAULT_USER", cfg.RabbitMQ.User)
	cfg.RabbitMQ.Password = getEnv("RABBITMQ_DEFAULT_PASS", cfg.RabbitMQ.Password)
	cfg.RabbitMQ.Port = getEnv("RABBITMQ_PORT", cfg.RabbitMQ.Port)
	cfg.RabbitMQ.AdminPort = getEnv("RABBITMQ_ADMIN_PORT", cfg.RabbitMQ.AdminPort)
}

// Helper function to get environment variable or default value
func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

// Function to initialize the RabbitMQ connection with retry logic
func initializeRabbitMQ(cfg *Config) (*amqp.Connection, error) {
	rabbitURL := fmt.Sprintf("amqp://%s:%s@%s:%s/",
		cfg.RabbitMQ.User, cfg.RabbitMQ.Password, cfg.RabbitMQ.URL, cfg.RabbitMQ.Port)

	var conn *amqp.Connection
	var err error

	// Retry loop
	for attempt := 1; attempt <= maxRetries; attempt++ {
		conn, err = amqp.Dial(rabbitURL)
		if err == nil {
			log.Printf("Connected to RabbitMQ at %s (attempt %d)", rabbitURL, attempt)
			return conn, nil
		}

		log.Printf("Failed to connect to RabbitMQ (attempt %d/%d): %v", attempt, maxRetries, err)
		
		if attempt < maxRetries {
			log.Printf("Retrying in %v...", retryDelay)
			time.Sleep(retryDelay)
		}
	}

	return nil, fmt.Errorf("failed to connect to RabbitMQ after %d attempts: %v", maxRetries, err)
}

// Function to create queues from the configuration
func createQueues(cfg *Config) error {
	// Establish connection to RabbitMQ
	conn, err := initializeRabbitMQ(cfg)
	if err != nil {
		return fmt.Errorf("failed to initialize RabbitMQ: %v", err)
	}
	defer conn.Close()

	// Create a channel for communication
	ch, err := conn.Channel()
	if err != nil {
		return fmt.Errorf("failed to open a channel: %v", err)
	}
	defer ch.Close()

	// Loop through each queue in the config and declare it
	for _, queue := range cfg.RabbitMQ.Queues {
		log.Printf("Creating queue: %s", queue.Name)
		_, err := ch.QueueDeclare(
			queue.Name,    // Queue name
			queue.Durable, // Durable
			queue.AutoDelete, // Auto-deleted when no consumers
			false,         // Exclusive
			false,         // No-wait
			nil,           // Arguments
		)

		if err != nil {
			return fmt.Errorf("failed to declare queue: %v", err)
		}
		log.Printf("Queue %s created successfully", queue.Name)
	}

	return nil
}

func main() {
	// Load configuration
	cfg := loadConfigOrFatal()

	// Create queues after establishing connection
	if err := createQueues(cfg); err != nil {
		log.Fatalf("Failed to create queues: %v", err)
	}

	log.Println("RabbitMQ queues successfully created")
}