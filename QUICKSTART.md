# 🚀 Hızlı Başlangıç Rehberi

Bu rehber, projeyi 5 dakikada çalıştırmanızı sağlar.

## Ön Gereksinimler

✅ Go 1.21+  
✅ AWS CLI (configured)  
✅ AWS hesabı  
✅ (Opsiyonel) Slack Webhook URL  

## 1. Projeyi İndirin

```bash
git clone https://github.com/emregulustan/lambda-blog-project.git
cd lambda-blog-project
```

## 2. Dependencies'i Yükleyin

```bash
make deps
# veya
go mod download
```

## 3. Environment Variables Ayarlayın

```bash
cp .env.example .env
# .env dosyasını düzenleyin
```

Minimum gerekli değişkenler:
```bash
AWS_REGION=us-east-1
LAMBDA_FUNCTION_NAME=alert-lambda
LAMBDA_ROLE_ARN=arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role
```

## 4. Test Edin

```bash
make test
```

## 5. Build Edin

```bash
make build
```

## 6. AWS'ye Deploy Edin

### Opsiyonel A: Manuel Script ile

```bash
source .env
make deploy
```

### Opsiyonel B: Terraform ile

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars'ı düzenleyin

terraform init
terraform apply
```

## 7. Test Mesajı Gönderin

```bash
# SQS Queue URL'inizi alın
SQS_URL=$(aws sqs get-queue-url --queue-name alert-queue --query 'QueueUrl' --output text)

# Test mesajı gönderin
aws sqs send-message \
  --queue-url "$SQS_URL" \
  --message-body '{
    "level": "info",
    "service": "test",
    "message": "Hello from Lambda!",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }'
```

## 8. Logları Kontrol Edin

```bash
aws logs tail /aws/lambda/alert-lambda --follow
```

## 🎉 Tebrikler!

Lambda fonksiyonunuz çalışıyor! Şimdi:

1. **Slack Entegrasyonu**: Slack webhook URL ekleyin
2. **CI/CD**: GitHub Actions secrets'ı ayarlayın
3. **Monitoring**: CloudWatch alarmları oluşturun
4. **Customize**: Kendi use case'inize göre özelleştirin

## 📚 Daha Fazla Bilgi

- [README.md](README.md) - Detaylı dokümantasyon
- [blog-yazisi.md](blog-yazisi.md) - Türkçe tutorial
- [terraform/README.md](terraform/README.md) - Terraform rehberi

## 🆘 Sorun mu Yaşıyorsunuz?

Troubleshooting için [README.md](README.md#troubleshooting) bölümüne bakın.

## Makefile Komutları

```bash
make help      # Tüm komutları göster
make deps      # Dependencies indir
make fmt       # Kodu formatla
make lint      # Linter çalıştır
make test      # Testleri çalıştır
make build     # Build et
make deploy    # Deploy et
make clean     # Build artifacts temizle
make all       # Hepsini çalıştır
```

