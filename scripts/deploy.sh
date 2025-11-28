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

# Lambda fonksiyonunun hazır olmasını bekleyen helper fonksiyon
wait_for_lambda_ready() {
    local function_name=$1
    local region=$2
    local max_retries=${3:-60}
    local retry_count=0
    
    echo -e "${BLUE}Waiting for Lambda function to be ready...${NC}"
    
    while [ $retry_count -lt $max_retries ]; do
        STATUS=$(aws lambda get-function \
            --function-name "$function_name" \
            --region "$region" \
            --query 'Configuration.LastUpdateStatus' \
            --output text 2>/dev/null || echo "Unknown")
        
        if [ "$STATUS" = "Successful" ]; then
            echo -e "${GREEN}Lambda function is ready!${NC}"
            return 0
        elif [ "$STATUS" = "Failed" ]; then
            echo -e "${RED}Lambda function update failed!${NC}"
            return 1
        else
            retry_count=$((retry_count + 1))
            if [ $((retry_count % 5)) -eq 0 ]; then
                echo -e "${YELLOW}Still waiting... ($retry_count/$max_retries) - Status: $STATUS${NC}"
            fi
            sleep 2
        fi
    done
    
    echo -e "${YELLOW}Warning: Lambda function did not become ready within timeout${NC}"
    return 1
}

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
    
    # Önce code'u güncelle
    echo -e "${BLUE}Updating function code...${NC}"
    aws lambda update-function-code \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --zip-file fileb://build/alert-lambda.zip \
        --region "$AWS_REGION" \
        > /dev/null
    
    # Code güncellemesinin tamamlanmasını bekle
    wait_for_lambda_ready "$LAMBDA_FUNCTION_NAME" "$AWS_REGION" 60
    
    # Environment variables güncelle (sadece değiştiyse)
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        echo -e "${BLUE}Updating function configuration...${NC}"
        
        # Retry mekanizması ile configuration update
        MAX_RETRIES=10
        RETRY_COUNT=0
        CONFIG_UPDATED=false
        
        while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$CONFIG_UPDATED" = false ]; do
            if aws lambda update-function-configuration \
                --function-name "$LAMBDA_FUNCTION_NAME" \
                --environment "Variables={SLACK_WEBHOOK_URL=$SLACK_WEBHOOK_URL}" \
                --region "$AWS_REGION" \
                > /dev/null 2>&1; then
                CONFIG_UPDATED=true
                echo -e "${GREEN}Function configuration update initiated!${NC}"
                
                # Configuration update'in tamamlanmasını bekle
                wait_for_lambda_ready "$LAMBDA_FUNCTION_NAME" "$AWS_REGION" 60
                break
            else
                RETRY_COUNT=$((RETRY_COUNT + 1))
                if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                    echo -e "${YELLOW}Configuration update failed, retrying in 3 seconds... ($RETRY_COUNT/$MAX_RETRIES)${NC}"
                    sleep 3
                fi
            fi
        done
        
        if [ "$CONFIG_UPDATED" = false ]; then
            echo -e "${YELLOW}Warning: Failed to update function configuration after $MAX_RETRIES retries${NC}"
            echo -e "${YELLOW}You may need to update it manually from AWS Console${NC}"
        fi
    fi
    
    echo -e "${GREEN}Lambda function updated successfully!${NC}"
fi

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

