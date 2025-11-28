# İlk AWS Lambda Fonksiyonunuzu Oluşturun ve Deploy Edin

Serverless mimariler, günümüz yazılım geliştirme dünyasında giderek daha popüler hale geliyor. Bu yazıda, Go programlama dili kullanarak AWS Lambda ile gerçek bir alert sistemi oluşturacağız ve bunu production ortamına deploy edeceğiz.

## Neden AWS Lambda?

AWS Lambda, sunucu yönetimi gerektirmeyen, event-driven bir computing servisidir. Lambda'nın getirdiği avantajlar:

- **Maliyet Optimizasyonu**: Sadece kodunuz çalıştığında ödeme yaparsınız
- **Otomatik Ölçeklendirme**: AWS, trafiğe göre otomatik scale eder
- **Yüksek Erişilebilirlik**: Multi-AZ deployment ile yüksek uptime
- **Kolay Entegrasyon**: AWS servisleriyle native entegrasyon

## Proje: SQS Tabanlı Alert Sistemi

Bu projede, Amazon SQS (Simple Queue Service) kuyruğundan mesaj dinleyen ve bu mesajları Slack gibi platformlara ileten bir Lambda fonksiyonu geliştireceğiz. Bu sistem, gerçek hayatta birçok use case için kullanılabilir:

- Uygulama hatalarını Slack'e göndermek
- Sistem metrikleri threshold'larını aştığında alert göndermek
- Log analizi sonuçlarını bildirmek
- Scheduled task'ları çalıştırmak

## Gereksinimler

Başlamadan önce şunlara ihtiyacınız var:

- Go 1.21 veya üzeri
- AWS hesabı
- AWS CLI (konfigüre edilmiş)
- Git
- Temel Go ve AWS bilgisi

## Adım 1: Proje Yapısını Oluşturma

İlk olarak, projemizin klasör yapısını oluşturalım:

```bash
mkdir lambda-blog-project && cd lambda-blog-project
go mod init github.com/USERNAME/lambda-blog-project
```

Proje yapımız şu şekilde olacak:

```
lambda-blog-project/
├── cmd/
│   └── lambda/
│       └── main.go           # Lambda handler
├── internal/
│   ├── sqs/
│   │   └── consumer.go       # SQS mesaj işleme
│   └── alerting/
│       └── notifier.go       # Bildirim sistemi
├── scripts/
│   ├── build.sh              # Build scripti
│   ├── test.sh               # Test scripti
│   └── deploy.sh             # Deploy scripti
└── .github/
    └── workflows/
        └── deploy.yml        # CI/CD pipeline
```

## Adım 2: Lambda Handler Geliştirme

Lambda fonksiyonumuzun kalbi olan handler'ı oluşturalım. `cmd/lambda/main.go`:

```go
package main

import (
	"context"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/emregulustan/lambda-blog-project/internal/alerting"
	"github.com/emregulustan/lambda-blog-project/internal/sqs"
)

var notifier alerting.Notifier

func init() {
	slackWebhookURL := os.Getenv("SLACK_WEBHOOK_URL")
	if slackWebhookURL == "" {
		notifier = alerting.NewConsoleNotifier()
	} else {
		notifier = alerting.NewSlackNotifier(slackWebhookURL)
	}
}

func HandleRequest(ctx context.Context, sqsEvent events.SQSEvent) error {
	log.Printf("Received %d SQS messages", len(sqsEvent.Records))

	for _, record := range sqsEvent.Records {
		alertMessage, err := sqs.ParseSQSMessage(record)
		if err != nil {
			log.Printf("ERROR: %v", err)
			return err
		}

		if err := notifier.SendAlert(ctx, alertMessage); err != nil {
			log.Printf("ERROR: Failed to send alert: %v", err)
			return err
		}
	}

	return nil
}

func main() {
	lambda.Start(HandleRequest)
}
```

### Lambda Handler'ın Anatomisi

1. **Init Function**: Lambda container başladığında bir kez çalışır. Burada Slack notifier'ı initialize ediyoruz.
2. **HandleRequest**: Her SQS event'i için çağrılır.
3. **Error Handling**: Hata durumunda mesaj DLQ'ya (Dead Letter Queue) gider.

## Adım 3: SQS Consumer Geliştirme

SQS mesajlarını parse eden modülümüzü oluşturalım. `internal/sqs/consumer.go`:

```go
package sqs

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/emregulustan/lambda-blog-project/internal/alerting"
)

type AlertPayload struct {
	Level     string                 `json:"level"`
	Service   string                 `json:"service"`
	Message   string                 `json:"message"`
	Timestamp string                 `json:"timestamp"`
	Metadata  map[string]interface{} `json:"metadata"`
}

func ParseSQSMessage(record events.SQSMessage) (*alerting.AlertMessage, error) {
	var payload AlertPayload

	if err := json.Unmarshal([]byte(record.Body), &payload); err != nil {
		return nil, fmt.Errorf("failed to unmarshal: %w", err)
	}

	// Validasyonlar
	if payload.Level == "" {
		return nil, fmt.Errorf("alert level is required")
	}

	var timestamp time.Time
	if payload.Timestamp != "" {
		timestamp, _ = time.Parse(time.RFC3339, payload.Timestamp)
	} else {
		timestamp = time.Now()
	}

	return &alerting.AlertMessage{
		Level:     payload.Level,
		Service:   payload.Service,
		Message:   payload.Message,
		Timestamp: timestamp,
		MessageID: record.MessageId,
		Metadata:  payload.Metadata,
	}, nil
}
```

### SQS Mesaj Formatı

Sistemimiz şu formatta JSON mesajlar bekliyor:

```json
{
  "level": "error",
  "service": "api-gateway",
  "message": "High latency detected",
  "timestamp": "2025-11-28T10:00:00Z",
  "metadata": {
    "latency_ms": 5000,
    "endpoint": "/api/users"
  }
}
```

## Adım 4: Alert Notification Sistemi

Genişletilebilir bir notification sistemi oluşturalım. `internal/alerting/notifier.go`:

```go
package alerting

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

type AlertMessage struct {
	Level     string
	Service   string
	Message   string
	Timestamp time.Time
	MessageID string
	Metadata  map[string]interface{}
}

// Notifier interface - farklı platformlar için extend edilebilir
type Notifier interface {
	SendAlert(ctx context.Context, alert *AlertMessage) error
}

// Slack implementasyonu
type SlackNotifier struct {
	webhookURL string
	httpClient *http.Client
}

func NewSlackNotifier(webhookURL string) *SlackNotifier {
	return &SlackNotifier{
		webhookURL: webhookURL,
		httpClient: &http.Client{Timeout: 10 * time.Second},
	}
}

func (s *SlackNotifier) SendAlert(ctx context.Context, alert *AlertMessage) error {
	// Slack mesaj formatı
	message := map[string]interface{}{
		"text": fmt.Sprintf("🔔 *%s Alert from %s*", alert.Level, alert.Service),
		"attachments": []map[string]interface{}{
			{
				"color": s.getLevelColor(alert.Level),
				"text":  alert.Message,
				"fields": []map[string]interface{}{
					{"title": "Service", "value": alert.Service, "short": true},
					{"title": "Level", "value": alert.Level, "short": true},
				},
				"ts": alert.Timestamp.Unix(),
			},
		},
	}

	payload, _ := json.Marshal(message)
	req, _ := http.NewRequestWithContext(ctx, "POST", s.webhookURL, bytes.NewBuffer(payload))
	req.Header.Set("Content-Type", "application/json")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("slack returned status: %d", resp.StatusCode)
	}

	return nil
}

func (s *SlackNotifier) getLevelColor(level string) string {
	colors := map[string]string{
		"info":     "#36a64f",
		"warning":  "#ff9800",
		"error":    "#f44336",
		"critical": "#9c27b0",
	}
	return colors[level]
}
```

### Interface Pattern'ın Gücü

`Notifier` interface sayesinde, sisteme kolayca yeni notification channel'ları ekleyebiliriz:

- Email notifier
- PagerDuty notifier
- SMS notifier
- Custom webhook notifier

## Adım 5: Build Script Oluşturma

Lambda için Go binary'sini build eden script. `scripts/build.sh`:

```bash
#!/bin/bash

set -e

echo "Building Lambda function..."

# Lambda için Linux binary oluştur
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build \
  -ldflags="-s -w" \
  -o build/bootstrap \
  cmd/lambda/main.go

# ZIP paketi oluştur
cd build
zip alert-lambda.zip bootstrap
cd ..

echo "Build completed: build/alert-lambda.zip"
```

### Build Optimizasyonları

- `-ldflags="-s -w"`: Debug bilgilerini kaldırarak binary boyutunu küçültür
- `GOARCH=arm64`: ARM64 architecture kullanarak maliyet düşürür (x86_64'e göre %20 daha ucuz)
- `CGO_ENABLED=0`: Static binary oluşturur, dependency sorunlarını önler

Script'i çalıştırılabilir hale getirin:

```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

## Adım 6: AWS'de Lambda Fonksiyonu Oluşturma

Şimdi AWS Console'da Lambda fonksiyonumuzu oluşturalım.

**[GIF-1: AWS Console'da Lambda Oluşturma Adımları]**
*Bu GIF'te şunları gösterin:*
- AWS Console > Lambda > Create Function
- Function name: "alert-lambda"
- Runtime: "Provide your own bootstrap on Amazon Linux 2023"
- Architecture: ARM64 seçimi
- Create function butonuna tıklama

### Lambda Fonksiyonu Oluşturma Adımları

1. AWS Console'da Lambda servisine gidin
2. "Create function" butonuna tıklayın
3. "Author from scratch" seçin
4. Function name: `alert-lambda`
5. Runtime: "Provide your own bootstrap on Amazon Linux 2023"
6. Architecture: `arm64`
7. "Create function"

**[SCREENSHOT-1: Lambda Function Created]**

## Adım 7: SQS Kuyruğu Oluşturma ve Bağlama

SQS kuyruğumuzu oluşturalım:

**[GIF-2: SQS Queue Oluşturma]**
*Bu GIF'te şunları gösterin:*
- AWS Console > SQS > Create Queue
- Queue name: "alert-queue"
- Configuration settings
- Dead Letter Queue ayarları
- Create queue

### AWS CLI ile SQS Oluşturma

Alternatif olarak, AWS CLI ile:

```bash
# SQS kuyruğu oluştur
aws sqs create-queue \
  --queue-name alert-queue \
  --region us-east-1

# Queue URL'ini al
SQS_URL=$(aws sqs get-queue-url \
  --queue-name alert-queue \
  --query 'QueueUrl' \
  --output text)

echo "SQS Queue URL: $SQS_URL"
```

### Lambda'ya SQS Trigger Ekleme

**[GIF-3: Lambda Trigger Configuration]**
*Bu GIF'te şunları gösterin:*
- Lambda function sayfasında "Add trigger"
- SQS seçimi
- Queue seçimi
- Batch size: 10
- "Add" butonuna tıklama

Lambda fonksiyonunda:
1. "Add trigger" butonuna tıklayın
2. "SQS" seçin
3. Oluşturduğunuz `alert-queue`'yu seçin
4. Batch size: `10`
5. "Add" butonuna tıklayın

## Adım 8: Environment Variables Ayarlama

Lambda'da Slack webhook URL'ini ayarlayalım:

**[SCREENSHOT-2: Environment Variables Configuration]**

1. Lambda function > Configuration > Environment variables
2. "Edit" butonuna tıklayın
3. "Add environment variable"
   - Key: `SLACK_WEBHOOK_URL`
   - Value: `your-slack-webhook-url`
4. "Save"

### Slack Webhook URL Alma

Slack webhook URL'i almak için:

1. [Slack API](https://api.slack.com/messaging/webhooks) sayfasına gidin
2. "Create your Slack app" butonuna tıklayın
3. "From scratch" seçin
4. App ismi ve workspace seçin
5. "Incoming Webhooks" sekmesine gidin
6. "Activate Incoming Webhooks"
7. "Add New Webhook to Workspace"
8. Kanal seçin ve authorize edin
9. Webhook URL'i kopyalayın

## Adım 9: Deploy Script ile Otomatik Deployment

Manuel adımları otomatikleştiren deploy script'imiz. `scripts/deploy.sh`:

```bash
#!/bin/bash

set -e

echo "Starting deployment..."

# Environment variables kontrolü
: ${AWS_REGION:?}
: ${LAMBDA_FUNCTION_NAME:?}
: ${LAMBDA_ROLE_ARN:?}

# Build
./scripts/build.sh

# SQS kuyruğu oluştur (varsa skip et)
SQS_QUEUE_URL=$(aws sqs get-queue-url \
  --queue-name alert-queue \
  --region $AWS_REGION \
  --query 'QueueUrl' \
  --output text 2>/dev/null || \
  aws sqs create-queue \
    --queue-name alert-queue \
    --region $AWS_REGION \
    --query 'QueueUrl' \
    --output text)

# Lambda fonksiyonu var mı kontrol et
if aws lambda get-function \
  --function-name $LAMBDA_FUNCTION_NAME \
  --region $AWS_REGION &>/dev/null; then
  # Güncelle
  aws lambda update-function-code \
    --function-name $LAMBDA_FUNCTION_NAME \
    --zip-file fileb://build/alert-lambda.zip \
    --region $AWS_REGION
else
  # Oluştur
  aws lambda create-function \
    --function-name $LAMBDA_FUNCTION_NAME \
    --runtime provided.al2023 \
    --role $LAMBDA_ROLE_ARN \
    --handler bootstrap \
    --zip-file fileb://build/alert-lambda.zip \
    --architectures arm64 \
    --region $AWS_REGION
fi

echo "Deployment completed!"
```

### Environment Variables Dosyası

`.env` dosyası oluşturun:

```bash
AWS_REGION=us-east-1
LAMBDA_FUNCTION_NAME=alert-lambda
LAMBDA_ROLE_ARN=arn:aws:iam::YOUR_ACCOUNT:role/lambda-execution-role
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

Deployment:

```bash
source .env
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## Adım 10: GitHub Actions ile CI/CD

Otomatik deployment için GitHub Actions workflow'u. `.github/workflows/deploy.yml`:

```yaml
name: Deploy Lambda Function

on:
  push:
    branches:
      - main

env:
  GO_VERSION: '1.21'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: ${{ env.GO_VERSION }}
      
      - name: Run tests
        run: go test -v ./...

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: ${{ env.GO_VERSION }}
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
      
      - name: Deploy
        env:
          LAMBDA_FUNCTION_NAME: ${{ secrets.LAMBDA_FUNCTION_NAME }}
          LAMBDA_ROLE_ARN: ${{ secrets.LAMBDA_ROLE_ARN }}
        run: |
          chmod +x scripts/deploy.sh
          ./scripts/deploy.sh
```

### GitHub Secrets Ayarlama

**[SCREENSHOT-3: GitHub Secrets Configuration]**

Repository Settings > Secrets and variables > Actions:

1. `AWS_ACCESS_KEY_ID`
2. `AWS_SECRET_ACCESS_KEY`
3. `AWS_REGION`
4. `LAMBDA_FUNCTION_NAME`
5. `LAMBDA_ROLE_ARN`
6. `SLACK_WEBHOOK_URL`

### CI/CD Pipeline Akışı

```
Push to main → Test → Build → Deploy → Verify
```

**[SCREENSHOT-4: GitHub Actions Pipeline Success]**

## Adım 11: Test Etme

Lambda fonksiyonumuzu test edelim:

### 1. SQS'e Mesaj Gönderme

```bash
aws sqs send-message \
  --queue-url "YOUR_SQS_QUEUE_URL" \
  --message-body '{
    "level": "error",
    "service": "api-gateway",
    "message": "High latency detected on /api/users endpoint",
    "timestamp": "2025-11-28T10:00:00Z",
    "metadata": {
      "latency_ms": 5000,
      "endpoint": "/api/users",
      "method": "GET"
    }
  }'
```

### 2. CloudWatch Logs İnceleme

**[SCREENSHOT-5: CloudWatch Logs]**

```bash
aws logs tail /aws/lambda/alert-lambda --follow
```

### 3. Slack'te Alert Görme

**[SCREENSHOT-6: Slack Alert Message]**

Slack'te şöyle bir mesaj görmelisiniz:

```
🔔 error Alert from api-gateway
━━━━━━━━━━━━━━━━━━━━━━━━
High latency detected on /api/users endpoint

Service: api-gateway
Level: error
Message ID: abc-123-xyz
```

## Adım 12: Monitoring ve Logging

### CloudWatch Metrics

Lambda fonksiyonunuz için otomatik olarak şu metrikler toplanır:

- **Invocations**: Çağrı sayısı
- **Duration**: Ortalama çalışma süresi
- **Errors**: Hata sayısı
- **Throttles**: Rate limit aşımları
- **Concurrent Executions**: Eşzamanlı çalışan instance sayısı

**[SCREENSHOT-7: CloudWatch Metrics Dashboard]**

### Custom Alarms

CloudWatch alarm oluşturun:

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name lambda-errors \
  --alarm-description "Alert when Lambda has errors" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=alert-lambda
```

### X-Ray ile Tracing

Lambda fonksiyonunda X-Ray'i aktif edin:

**[SCREENSHOT-8: X-Ray Tracing Configuration]**

1. Lambda > Configuration > Monitoring and operations tools
2. "Edit" butonuna tıklayın
3. "AWS X-Ray" seçeneğini aktif edin
4. "Save"

## Terraform ile Infrastructure as Code

Tüm bu kaynakları Terraform ile yönetebilirsiniz. `terraform/lambda.tf`:

```hcl
resource "aws_lambda_function" "alert_lambda" {
  filename         = "../build/alert-lambda.zip"
  function_name    = "alert-lambda"
  role            = aws_iam_role.lambda_role.arn
  handler         = "bootstrap"
  runtime         = "provided.al2023"
  architectures   = ["arm64"]

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }
}

resource "aws_sqs_queue" "alert_queue" {
  name                      = "alert-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds = 345600
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.alert_queue.arn
  function_name    = aws_lambda_function.alert_lambda.arn
  batch_size       = 10
}
```

Terraform ile deploy:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Performance Optimizasyonu

### Cold Start Azaltma

1. **ARM64 Architecture**: %20 daha hızlı cold start
2. **Binary Size**: Minimum boyutta binary (5MB altı ideal)
3. **Provisioned Concurrency**: Kritik uygulamalar için

### Memory ve Timeout Tuning

```bash
aws lambda update-function-configuration \
  --function-name alert-lambda \
  --memory-size 256 \
  --timeout 60
```

### Batch Size Optimizasyonu

SQS batch size'ı optimize edin:
- **Küçük mesajlar**: Batch size 10
- **Büyük mesajlar**: Batch size 1-5
- **Hızlı işlem**: Daha büyük batch

## Maliyet Analizi

Örnek senaryo için maliyet hesabı:

```
Ayda 1 milyon request
Ortalama 100ms execution time
128MB memory

Lambda: $0.20
SQS: $0.40
CloudWatch Logs: $0.50
───────────────────
Toplam: ~$1.10/ay
```

Lambda'nın ilk 1 milyon request'i ücretsiz! (Free Tier)

## Production Best Practices

### 1. Dead Letter Queue (DLQ)

Başarısız mesajlar için DLQ kullanın:

```bash
aws sqs create-queue --queue-name alert-queue-dlq

aws sqs set-queue-attributes \
  --queue-url $QUEUE_URL \
  --attributes '{
    "RedrivePolicy": "{\"deadLetterTargetArn\":\"'$DLQ_ARN'\",\"maxReceiveCount\":\"3\"}"
  }'
```

### 2. Error Handling

```go
func HandleRequest(ctx context.Context, sqsEvent events.SQSEvent) (events.SQSEventResponse, error) {
    batchItemFailures := []events.SQSBatchItemFailure{}

    for _, record := range sqsEvent.Records {
        if err := processMessage(record); err != nil {
            batchItemFailures = append(batchItemFailures, events.SQSBatchItemFailure{
                ItemIdentifier: record.MessageId,
            })
        }
    }

    return events.SQSEventResponse{
        BatchItemFailures: batchItemFailures,
    }, nil
}
```

### 3. Secrets Management

Hassas bilgileri AWS Secrets Manager'da tutun:

```go
func getSlackWebhook() (string, error) {
    sess := session.Must(session.NewSession())
    svc := secretsmanager.New(sess)
    
    result, err := svc.GetSecretValue(&secretsmanager.GetSecretValueInput{
        SecretId: aws.String("slack-webhook-url"),
    })
    
    return *result.SecretString, err
}
```

### 4. Rate Limiting

Slack API rate limit'lerini aşmamak için:

```go
var rateLimiter = rate.NewLimiter(rate.Every(time.Second), 1)

func (s *SlackNotifier) SendAlert(ctx context.Context, alert *AlertMessage) error {
    if err := rateLimiter.Wait(ctx); err != nil {
        return err
    }
    // ... send alert
}
```

### 5. Idempotency

Aynı mesajı birden fazla işlememeyi garantileyin:

```go
var processedMessages sync.Map

func isProcessed(messageID string) bool {
    _, exists := processedMessages.Load(messageID)
    return exists
}

func markProcessed(messageID string) {
    processedMessages.Store(messageID, time.Now())
}
```

## Troubleshooting

### Problem: Lambda timeout oluyor

**Çözüm:**
- Timeout süresini artırın
- Batch size'ı azaltın
- HTTP client timeout'larını kontrol edin

### Problem: SQS mesajları işlenmiyor

**Çözüm:**
- Event source mapping'in enabled olduğunu kontrol edin
- IAM permissions'ları doğrulayın
- Visibility timeout > Lambda timeout olmalı

### Problem: Slack mesajları gitmiyor

**Çözüm:**
- Webhook URL'i doğrulayın
- Network connectivity kontrol edin
- CloudWatch logs'unda detaylı hata mesajlarını inceleyin

## Gelecek Geliştirmeler

Projeyi geliştirebileceğiniz alanlar:

1. **Email Notifier**: SES veya SendGrid entegrasyonu
2. **PagerDuty**: On-call engineer'lar için
3. **Alert Routing**: Severity'ye göre farklı kanallar
4. **Alert Aggregation**: Benzer alert'leri grupla
5. **Web Dashboard**: Alert history görüntüleme
6. **Alert Silencing**: Maintenance window'ları için

## Sonuç

Bu yazıda, sıfırdan production-ready bir AWS Lambda alert sistemi oluşturduk. Öğrendiklerimiz:

✅ Go ile Lambda fonksiyon geliştirme
✅ SQS ile event-driven architecture
✅ Slack entegrasyonu
✅ Infrastructure as Code (Terraform)
✅ CI/CD pipeline (GitHub Actions)
✅ Monitoring ve logging
✅ Production best practices

### Proje Kaynak Kodu

Tam kaynak koda GitHub'dan ulaşabilirsiniz:
👉 [github.com/emregulustan/lambda-blog-project](https://github.com/emregulustan/lambda-blog-project)

### Sonraki Adımlar

1. Projeyi klonlayın ve local'de çalıştırın
2. Kendi use case'inizle özelleştirin
3. Production'a deploy edin
4. Monitoring setup'ını yapın
5. İyileştirmeler ekleyin

## Sorular ve Geri Bildirim

Bu konuda sorunuz varsa veya geri bildirimde bulunmak istiyorsanız, yorumlarda benimle iletişime geçebilirsiniz!

---

*Bu yazı faydalı olduysa, 👏 alkışlamayı ve paylaşmayı unutmayın!*

**Etiketler:** #AWS #Lambda #Serverless #Go #DevOps #CloudComputing #SQS #Slack #Terraform #CICD

---

## Ekran Görüntüleri için Notlar

Blog yazısında placeholderlar yerine gerçek ekran görüntüleri eklemeniz gereken yerler:

1. **[GIF-1]**: AWS Console'da Lambda oluşturma adımları
2. **[GIF-2]**: SQS Queue oluşturma süreci
3. **[GIF-3]**: Lambda'ya trigger ekleme
4. **[SCREENSHOT-1]**: Lambda fonksiyon oluşturuldu ekranı
5. **[SCREENSHOT-2]**: Environment variables configuration
6. **[SCREENSHOT-3]**: GitHub Secrets ayarları
7. **[SCREENSHOT-4]**: GitHub Actions başarılı pipeline
8. **[SCREENSHOT-5]**: CloudWatch Logs çıktısı
9. **[SCREENSHOT-6]**: Slack'te gelen alert mesajı
10. **[SCREENSHOT-7]**: CloudWatch Metrics dashboard
11. **[SCREENSHOT-8]**: X-Ray tracing configuration

Bu görüntüleri kendi AWS hesabınızda projeyi deploy ederken alabilirsiniz. Medium'da görüntü eklemek için yazı düzenleyicisinde drag & drop veya "+" butonunu kullanabilirsiniz.

