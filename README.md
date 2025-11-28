# AWS Lambda Alert System

Go ile geliştirilmiş, SQS mesajlarını dinleyen ve Slack/Email gibi platformlara alert gönderen serverless bir alert sistemi.

## 🚀 Özellikler

- **Serverless Mimari**: AWS Lambda ile maliyet-efektif çalışma
- **SQS Entegrasyonu**: Amazon SQS ile güvenilir mesaj kuyruğu
- **Esnek Bildirim**: Slack, Email ve daha fazlası için genişletilebilir interface
- **CI/CD Pipeline**: GitHub Actions ile otomatik deployment
- **Infrastructure as Code**: Terraform ile altyapı yönetimi
- **Production-Ready**: Error handling, retry mekanizması ve DLQ desteği

## 📋 Ön Gereksinimler

- Go 1.21 veya üzeri
- AWS CLI (konfigüre edilmiş)
- AWS hesabı ve gerekli IAM izinleri
- (Opsiyonel) Terraform 1.0+
- (Opsiyonel) Slack Webhook URL'i

## 🏗️ Proje Yapısı

```
lambda-blog-project/
├── cmd/
│   └── lambda/
│       └── main.go           # Lambda handler
├── internal/
│   ├── sqs/
│   │   └── consumer.go       # SQS mesaj işleme
│   └── alerting/
│       └── notifier.go       # Slack/Email notifier
├── scripts/
│   ├── build.sh              # Build scripti
│   ├── test.sh               # Test scripti
│   └── deploy.sh             # Deploy scripti
├── .github/
│   └── workflows/
│       └── deploy.yml        # GitHub Actions
├── terraform/                # IaC dosyaları
│   ├── lambda.tf
│   └── README.md
├── go.mod
├── README.md
└── .env.example
```

## 🚦 Hızlı Başlangıç

### 1. Projeyi Klonlayın veya İndirin

```bash
git clone https://github.com/emregulustan/lambda-blog-project.git
cd lambda-blog-project
```

### 2. Dependencies'i Yükleyin

```bash
go mod download
```

### 3. Environment Variables'ı Ayarlayın

```bash
cp .env.example .env
# .env dosyasını düzenleyin
source .env
```

### 4. Build Edin

```bash
./scripts/build.sh
```

### 5. Test Edin

```bash
./scripts/test.sh
```

### 6. AWS'ye Deploy Edin

#### Manuel Deployment

```bash
./scripts/deploy.sh
```

#### Terraform ile Deployment

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## 📝 Kullanım

### SQS'e Mesaj Gönderin

Deployment sonrası Lambda'nızı test etmek için SQS kuyruğuna mesaj gönderin:

```bash
aws sqs send-message \
  --queue-url "YOUR_SQS_QUEUE_URL" \
  --message-body '{
    "level": "error",
    "service": "api-gateway",
    "message": "High latency detected",
    "timestamp": "2025-11-28T10:00:00Z",
    "metadata": {
      "latency_ms": 5000,
      "endpoint": "/api/users"
    }
  }'
```

### Mesaj Formatı

SQS mesajları aşağıdaki JSON formatında olmalıdır:

```json
{
  "level": "info|warning|error|critical",
  "service": "service-name",
  "message": "Alert message",
  "timestamp": "2025-11-28T10:00:00Z",
  "metadata": {
    "key": "value"
  }
}
```

### Alert Seviyeleri

- **info**: Bilgilendirme mesajları (🟢 Yeşil)
- **warning**: Uyarı mesajları (🟠 Turuncu)
- **error**: Hata mesajları (🔴 Kırmızı)
- **critical**: Kritik hatalar (🟣 Mor)

## 🔧 Konfigürasyon

### Environment Variables

| Değişken | Açıklama | Gerekli | Varsayılan |
|----------|----------|---------|------------|
| `AWS_REGION` | AWS bölgesi | ✅ | - |
| `LAMBDA_FUNCTION_NAME` | Lambda fonksiyon adı | ✅ | - |
| `LAMBDA_ROLE_ARN` | Lambda IAM role ARN | ✅ | - |
| `SQS_QUEUE_NAME` | SQS kuyruk adı | ✅ | alert-queue |
| `SLACK_WEBHOOK_URL` | Slack webhook URL | ❌ | - |
| `LAMBDA_MEMORY` | Lambda bellek (MB) | ❌ | 128 |
| `LAMBDA_TIMEOUT` | Lambda timeout (saniye) | ❌ | 30 |
| `LAMBDA_ARCHITECTURE` | Lambda mimari (arm64/amd64) | ❌ | arm64 |

## 🔄 CI/CD Pipeline

GitHub Actions ile otomatik deployment:

### 1. GitHub Secrets Ayarlayın

Repository Settings > Secrets and variables > Actions:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `LAMBDA_FUNCTION_NAME`
- `LAMBDA_ROLE_ARN`
- `SQS_QUEUE_NAME`
- `SLACK_WEBHOOK_URL` (opsiyonel)

### 2. Main Branch'e Push Edin

```bash
git push origin main
```

Pipeline otomatik olarak:
1. Testleri çalıştırır
2. Build eder
3. AWS'ye deploy eder
4. Smoke test yapar

## 📊 Monitoring ve Logging

### CloudWatch Logs

```bash
aws logs tail /aws/lambda/alert-lambda --follow
```

### CloudWatch Metrics

Lambda Console'da şu metrikleri izleyebilirsiniz:
- Invocation count
- Duration
- Error rate
- Throttles

### SQS Metrics

- Messages available
- Messages in flight
- Dead letter queue messages

## 🧪 Test

### Unit Tests

```bash
go test -v ./...
```

### Coverage Report

```bash
./scripts/test.sh
# HTML raporu: coverage/coverage.html
```

### Manuel Lambda Test

```bash
aws lambda invoke \
  --function-name alert-lambda \
  --payload '{
    "Records": [{
      "messageId": "test-id",
      "body": "{\"level\":\"info\",\"service\":\"test\",\"message\":\"Test alert\"}"
    }]
  }' \
  response.json
```

## 🎯 Gelecek Geliştirmeler

- [ ] Email notifier implementasyonu
- [ ] PagerDuty entegrasyonu
- [ ] Webhook desteği
- [ ] Alert filtreleme ve routing
- [ ] Rate limiting
- [ ] Alert aggregation
- [ ] Dashboard ve reporting

## 🐛 Troubleshooting

### Lambda timeout oluyor

`LAMBDA_TIMEOUT` değerini artırın veya işlem süresini optimize edin.

### SQS mesajları işlenmiyor

1. Event source mapping'in enabled olduğunu kontrol edin
2. Lambda IAM role'ünün SQS okuma izinlerine sahip olduğunu kontrol edin
3. SQS visibility timeout'unun Lambda timeout'undan büyük olduğunu kontrol edin

### Slack bildirimleri gitmiyor

1. `SLACK_WEBHOOK_URL` environment variable'ının doğru set edildiğini kontrol edin
2. Webhook URL'inin geçerli olduğunu test edin
3. Lambda CloudWatch logs'unda hata mesajlarını kontrol edin

## 📚 Daha Fazla Bilgi

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Amazon SQS Documentation](https://docs.aws.amazon.com/sqs/)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 📄 Lisans

MIT License - Detaylar için LICENSE dosyasına bakın.

## 👤 Yazar

**Emre Gülüstan**

- Blog: [Medium](https://medium.com/@emregulustan)
- GitHub: [@emregulustan](https://github.com/emregulustan)

## 🤝 Katkıda Bulunma

Pull request'ler kabul edilir! Büyük değişiklikler için önce bir issue açarak ne değiştirmek istediğinizi tartışın.

## ⭐ Destek

Bu projeyi faydalı bulduysanız, bir ⭐ vererek destek olabilirsiniz!


<!-- Last updated: Fri Nov 28 16:41:44 +03 2025 -->
