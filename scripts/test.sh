#!/bin/bash

# Test script for Lambda function
# Bu script unit testleri çalıştırır ve code coverage raporu oluşturur

set -e

# Renkli output için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting test process...${NC}"

# Proje root dizinine git
cd "$(dirname "$0")/.."

# Test coverage dizinini oluştur
mkdir -p coverage

# Unit testleri çalıştır
echo -e "${YELLOW}Running unit tests...${NC}"
go test -v -race -coverprofile=coverage/coverage.out ./...

# Coverage sonuçlarını göster
echo -e "\n${YELLOW}Test Coverage:${NC}"
go tool cover -func=coverage/coverage.out | grep total

# HTML coverage raporu oluştur
echo -e "\n${YELLOW}Generating HTML coverage report...${NC}"
go tool cover -html=coverage/coverage.out -o coverage/coverage.html
echo -e "${GREEN}HTML coverage report: coverage/coverage.html${NC}"

# Opsiyonel: golangci-lint varsa linting yap
if command -v golangci-lint &> /dev/null; then
    echo -e "\n${YELLOW}Running linters...${NC}"
    golangci-lint run ./...
    echo -e "${GREEN}Linting passed!${NC}"
else
    echo -e "\n${YELLOW}golangci-lint not found, skipping linting${NC}"
    echo -e "Install it with: curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b \$(go env GOPATH)/bin"
fi

# go vet ile static analysis
echo -e "\n${YELLOW}Running go vet...${NC}"
go vet ./...
echo -e "${GREEN}go vet passed!${NC}"

echo -e "\n${GREEN}All tests passed successfully!${NC}"

