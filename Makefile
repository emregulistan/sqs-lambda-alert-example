.PHONY: help build test deploy clean deps fmt lint

# Default target
help:
	@echo "Lambda Blog Project - Makefile Commands"
	@echo ""
	@echo "Available targets:"
	@echo "  make deps      - Download Go dependencies"
	@echo "  make fmt       - Format Go code"
	@echo "  make lint      - Run linters"
	@echo "  make test      - Run tests with coverage"
	@echo "  make build     - Build Lambda deployment package"
	@echo "  make deploy    - Deploy to AWS"
	@echo "  make clean     - Clean build artifacts"
	@echo "  make all       - Run fmt, lint, test, build"
	@echo ""

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	go mod download
	go mod tidy

# Format code
fmt:
	@echo "Formatting code..."
	go fmt ./...
	@if command -v gofmt >/dev/null 2>&1; then \
		gofmt -s -w .; \
	fi

# Run linters
lint:
	@echo "Running linters..."
	go vet ./...
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run ./...; \
	else \
		echo "golangci-lint not found, skipping..."; \
	fi

# Run tests
test:
	@echo "Running tests..."
	chmod +x scripts/test.sh
	./scripts/test.sh

# Build
build:
	@echo "Building Lambda function..."
	chmod +x scripts/build.sh
	./scripts/build.sh

# Deploy
deploy:
	@echo "Deploying to AWS..."
	chmod +x scripts/deploy.sh
	./scripts/deploy.sh

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf build/
	rm -rf coverage/
	rm -f response.json
	@echo "Clean complete!"

# Run all checks
all: fmt lint test build
	@echo "All checks passed!"

# Quick build and test
quick: fmt test build
	@echo "Quick build complete!"

