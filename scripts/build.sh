#!/bin/bash

# Build script for AWS Lambda function
# Bu script Go kodunu Linux için derler ve Lambda için gerekli ZIP dosyasını oluşturur

set -e

# Renkli output için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting build process...${NC}"

# Proje root dizinine git
cd "$(dirname "$0")/.."

# Build dizinini temizle
echo -e "${YELLOW}Cleaning build directory...${NC}"
rm -rf build
mkdir -p build

# Lambda function ismi
FUNCTION_NAME="alert-lambda"

# Architecture seçimi (arm64 veya amd64)
# ARM64 daha ucuz ama bazı kütüphanelerle uyumsuz olabilir
ARCH="${ARCH:-arm64}"

echo -e "${YELLOW}Building for architecture: ${ARCH}${NC}"

# Go binary'sini build et
echo -e "${YELLOW}Building Go binary...${NC}"

if [ "$ARCH" = "arm64" ]; then
    GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -ldflags="-s -w" -o build/bootstrap cmd/lambda/main.go
else
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -o build/bootstrap cmd/lambda/main.go
fi

# Binary boyutunu göster
BINARY_SIZE=$(du -h build/bootstrap | cut -f1)
echo -e "${GREEN}Binary created: ${BINARY_SIZE}${NC}"

# ZIP dosyası oluştur
echo -e "${YELLOW}Creating deployment package...${NC}"
cd build
zip -q ${FUNCTION_NAME}.zip bootstrap

# ZIP boyutunu göster
ZIP_SIZE=$(du -h ${FUNCTION_NAME}.zip | cut -f1)
echo -e "${GREEN}Deployment package created: ${ZIP_SIZE}${NC}"

cd ..

echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "Deployment package: ${YELLOW}build/${FUNCTION_NAME}.zip${NC}"

