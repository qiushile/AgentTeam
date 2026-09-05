.PHONY: run build test migrate seed docker-up docker-down clean

# Build the binary
build:
	go build -o bin/gpu-platform ./cmd/server

# Run the server
run:
	go run ./cmd/server

# Run tests
test:
	go test -v ./...

# Format code
fmt:
	go fmt ./...

# Start Docker services (PostgreSQL + Redis)
docker-up:
	docker-compose up -d postgres redis

# Stop Docker services
docker-down:
	docker-compose down

# Start everything (services + app)
docker-all:
	docker-compose up -d

# Clean build artifacts
clean:
	rm -rf bin/
	go clean

# Install dependencies
deps:
	go mod download
	go mod tidy
