#!/bin/bash

# Deploy script for AWS Lambda function
# Bu script Lambda fonksiyonunu AWS'ye deploy eder, SQS kuyruğu oluşturur ve gerekli konfigürasyonları yapar

set -e

# Renkli output için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting deployment process...${NC}"

# Proje root dizinine git
cd "$(dirname "$0")/.."

# Environment variables kontrolü
REQUIRED_VARS=("AWS_REGION" "LAMBDA_FUNCTION_NAME" "LAMBDA_ROLE_ARN")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}Error: $var environment variable is not set${NC}"
        echo -e "${YELLOW}Please set it in .env file or export it${NC}"
        exit 1
    fi
done

# Opsiyonel değişkenler
SQS_QUEUE_NAME="${SQS_QUEUE_NAME:-alert-queue}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
LAMBDA_MEMORY="${LAMBDA_MEMORY:-128}"
LAMBDA_TIMEOUT="${LAMBDA_TIMEOUT:-30}"
LAMBDA_ARCHITECTURE="${LAMBDA_ARCHITECTURE:-arm64}"

echo -e "${BLUE}Deployment Configuration:${NC}"
echo -e "  Region: ${YELLOW}${AWS_REGION}${NC}"
echo -e "  Function: ${YELLOW}${LAMBDA_FUNCTION_NAME}${NC}"
echo -e "  Role: ${YELLOW}${LAMBDA_ROLE_ARN}${NC}"
echo -e "  SQS Queue: ${YELLOW}${SQS_QUEUE_NAME}${NC}"
echo -e "  Memory: ${YELLOW}${LAMBDA_MEMORY}MB${NC}"
echo -e "  Timeout: ${YELLOW}${LAMBDA_TIMEOUT}s${NC}"
echo -e "  Architecture: ${YELLOW}${LAMBDA_ARCHITECTURE}${NC}"

# Build işlemi
echo -e "\n${YELLOW}Building Lambda function...${NC}"
ARCH=$LAMBDA_ARCHITECTURE ./scripts/build.sh

# SQS kuyruğu oluştur veya al
echo -e "\n${YELLOW}Creating/Getting SQS queue...${NC}"
SQS_QUEUE_URL=$(aws sqs get-queue-url --queue-name "$SQS_QUEUE_NAME" --region "$AWS_REGION" --query 'QueueUrl' --output text 2>/dev/null || true)

if [ -z "$SQS_QUEUE_URL" ]; then
    echo -e "${YELLOW}Creating new SQS queue: ${SQS_QUEUE_NAME}${NC}"
    SQS_QUEUE_URL=$(aws sqs create-queue \
        --queue-name "$SQS_QUEUE_NAME" \
        --region "$AWS_REGION" \
        --attributes VisibilityTimeout=60,MessageRetentionPeriod=345600 \
        --query 'QueueUrl' \
        --output text)
    echo -e "${GREEN}SQS queue created: ${SQS_QUEUE_URL}${NC}"
else
    echo -e "${GREEN}SQS queue already exists: ${SQS_QUEUE_URL}${NC}"
fi

# SQS Queue ARN'ini al
SQS_QUEUE_ARN=$(aws sqs get-queue-attributes \
    --queue-url "$SQS_QUEUE_URL" \
    --attribute-names QueueArn \
    --region "$AWS_REGION" \
    --query 'Attributes.QueueArn' \
    --output text)
echo -e "SQS Queue ARN: ${YELLOW}${SQS_QUEUE_ARN}${NC}"

# Lambda fonksiyonunu kontrol et
echo -e "\n${YELLOW}Checking if Lambda function exists...${NC}"
FUNCTION_EXISTS=$(aws lambda get-function --function-name "$LAMBDA_FUNCTION_NAME" --region "$AWS_REGION" 2>/dev/null || echo "false")

if [ "$FUNCTION_EXISTS" = "false" ]; then
    # Lambda fonksiyonunu oluştur
    echo -e "${YELLOW}Creating new Lambda function...${NC}"
    
    ENV_VARS="Variables={}"
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        ENV_VARS="Variables={SLACK_WEBHOOK_URL=$SLACK_WEBHOOK_URL}"
    fi
    
    aws lambda create-function \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --runtime provided.al2023 \
        --role "$LAMBDA_ROLE_ARN" \
        --handler bootstrap \
        --zip-file fileb://build/alert-lambda.zip \
        --timeout "$LAMBDA_TIMEOUT" \
        --memory-size "$LAMBDA_MEMORY" \
        --architectures "$LAMBDA_ARCHITECTURE" \
        --environment "$ENV_VARS" \
        --region "$AWS_REGION" \
        > /dev/null
    
    echo -e "${GREEN}Lambda function created successfully!${NC}"
else
    # Lambda fonksiyonunu güncelle
    echo -e "${YELLOW}Updating existing Lambda function...${NC}"
    
    aws lambda update-function-code \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --zip-file fileb://build/alert-lambda.zip \
        --region "$AWS_REGION" \
        > /dev/null
    
    # Environment variables güncelle
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        aws lambda update-function-configuration \
            --function-name "$LAMBDA_FUNCTION_NAME" \
            --environment "Variables={SLACK_WEBHOOK_URL=$SLACK_WEBHOOK_URL}" \
            --region "$AWS_REGION" \
            > /dev/null
    fi
    
    echo -e "${GREEN}Lambda function updated successfully!${NC}"
fi

# Lambda fonksiyonun hazır olmasını bekle
echo -e "\n${YELLOW}Waiting for Lambda function to be ready...${NC}"
aws lambda wait function-updated \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --region "$AWS_REGION"

# Event source mapping kontrolü
echo -e "\n${YELLOW}Setting up SQS event source mapping...${NC}"
MAPPING_UUID=$(aws lambda list-event-source-mappings \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --region "$AWS_REGION" \
    --query "EventSourceMappings[?EventSourceArn=='$SQS_QUEUE_ARN'].UUID" \
    --output text)

if [ -z "$MAPPING_UUID" ]; then
    echo -e "${YELLOW}Creating event source mapping...${NC}"
    aws lambda create-event-source-mapping \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --event-source-arn "$SQS_QUEUE_ARN" \
        --batch-size 10 \
        --region "$AWS_REGION" \
        > /dev/null
    echo -e "${GREEN}Event source mapping created!${NC}"
else
    echo -e "${GREEN}Event source mapping already exists: ${MAPPING_UUID}${NC}"
fi

# Deployment bilgilerini göster
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Lambda Function:${NC} ${YELLOW}${LAMBDA_FUNCTION_NAME}${NC}"
echo -e "${BLUE}SQS Queue URL:${NC} ${YELLOW}${SQS_QUEUE_URL}${NC}"
echo -e "${BLUE}Region:${NC} ${YELLOW}${AWS_REGION}${NC}"
echo -e "\n${YELLOW}Test your function by sending a message to SQS:${NC}"
echo -e "${BLUE}aws sqs send-message --queue-url \"${SQS_QUEUE_URL}\" --message-body '{\"level\":\"info\",\"service\":\"test\",\"message\":\"Hello from SQS!\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}'${NC}"

