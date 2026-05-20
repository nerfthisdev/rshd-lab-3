DB_URL := "postgres://mainuser:mypassword@localhost:5432/mydb?sslmode=disable"
MIGRATION_DIR := migrations

BUILD_DIR := bin
BINARY_NAME := db-app

GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod

.PHONY: migrate-up migrate-down build run clean

migrate-up:
	migrate -database $(DB_URL) -path $(MIGRATION_DIR) up

migrate-down:
	migrate -database $(DB_URL) -path $(MIGRATION_DIR) down

build:
	@echo "Building..."
	$(GOBUILD) -o $(BUILD_DIR)/$(BINARY_NAME) -v

run: build
	@echo "Running $(BINARY_NAME)..."
	$(BUILD_DIR)/$(BINARY_NAME)

clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	rm -rf $(BUILD_DIR)
