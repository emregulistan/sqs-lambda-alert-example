# 🏗️ Terraform ile Deployment Rehberi

Terraform kullanarak Infrastructure as Code (IaC) yaklaşımıyla Lambda fonksiyonunu deploy edelim.

---

## Ön Gereksinimler

### Terraform Kurulumu

**macOS için:**

```bash
# Homebrew ile kurulum (önerilen)
brew install terraform

# Kurulumu doğrulayın
terraform --version
```

**Manuel kurulum:**
1. [Terraform download sayfasına](https://www.terraform.io/downloads) gidin
2. macOS için binary'i indirin
3. `/usr/local/bin/` klasörüne kopyalayın
4. `terraform --version` ile kontrol edin

---

## Adım 1: Terraform Konfigürasyonu Hazırlama

### 1.1 Terraform Variables Dosyası

```bash
cd ~/Desktop/lambda-blog-project/terraform

# Örnek dosyayı kopyala
cp terraform.tfvars.example terraform.tfvars
```

### 1.2 terraform.tfvars Dosyasını Düzenleyin

`terraform/terraform.tfvars` dosyasını açın ve düzenleyin:

```hcl
# AWS Configuration
aws_region = "us-east-1"

# Lambda Configuration
lambda_function_name = "alert-lambda"
lambda_memory        = 128
lambda_timeout       = 30
lambda_architecture  = "arm64"  # or "x86_64"

# SQS Configuration
sqs_queue_name = "alert-queue"

# Slack Configuration
slack_webhook_url = "YOUR_SLACK_WEBHOOK_URL_HERE"
```

**⚠️ ÖNEMLİ:** 
- `terraform.tfvars` dosyası hassas bilgiler içerir
- Bu dosya `.gitignore`'da olmalı (zaten var)
- GitHub'a push etmeyin!

---

## Adım 2: Build Paketini Hazırlama

Terraform, Lambda için build edilmiş ZIP dosyasına ihtiyaç duyar:

```bash
cd ~/Desktop/lambda-blog-project

# Lambda paketini build et
./scripts/build.sh

# ZIP dosyasının var olduğunu kontrol et
ls -lh build/alert-lambda.zip
```

**✅ `build/alert-lambda.zip` dosyası hazır olmalı!**

---

## Adım 3: Terraform Initialize

```bash
cd ~/Desktop/lambda-blog-project/terraform

# Terraform'u başlat
terraform init
```

**Beklenen çıktı:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
Terraform has been successfully initialized!
```

---

## Adım 4: Terraform Plan (Önizleme)

Değişiklikleri görmek için plan çalıştırın:

```bash
terraform plan
```

**Beklenen çıktı:**
```
Plan: X to add, 0 to change, 0 to destroy.
```

**Önemli notlar:**
- Eğer Lambda zaten varsa, Terraform mevcut kaynakları güncelleyecek
- Yeni kaynaklar eklenecek (Lambda, SQS, IAM, vb.)
- Değişikliklerin özetini göreceksiniz

---

## Adım 5: Terraform Apply (Deploy)

Değişiklikleri uygulamak için:

```bash
terraform apply
```

**Onay istediğinde:**
- `yes` yazın ve Enter'a basın

**⏳ Deploy süresi:** 2-5 dakika

**Beklenen çıktı:**
```
Apply complete! Resources: X added, 0 changed, 0 destroyed.

Outputs:

lambda_function_arn = "arn:aws:lambda:us-east-1:533420169013:function:alert-lambda"
lambda_function_name = "alert-lambda"
sqs_queue_url = "https://sqs.us-east-1.amazonaws.com/533420169013/alert-queue"
...
```

---

## Adım 6: Terraform State Kontrolü

Terraform oluşturduğu kaynakları takip eder:

```bash
# State listesi
terraform state list

# Belirli bir kaynağı detaylı göster
terraform state show aws_lambda_function.alert_lambda
```

---

## Adım 7: Test Etme

Lambda'nın çalıştığını test edin:

```bash
# SQS Queue URL'ini al (Terraform output'tan)
SQS_URL=$(terraform output -raw sqs_queue_url)

# Test mesajı gönder
aws sqs send-message \
  --queue-url "$SQS_URL" \
  --region us-east-1 \
  --message-body '{
    "level": "info",
    "service": "terraform-test",
    "message": "Terraform deployment successful!",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }'

# Logları kontrol et
aws logs tail /aws/lambda/alert-lambda --follow --region us-east-1
```

---

## Adım 8: Terraform ile Güncelleme

Kod değişikliği yaptıktan sonra:

### 8.1 Yeniden Build

```bash
cd ~/Desktop/lambda-blog-project
./scripts/build.sh
```

### 8.2 Terraform Apply

```bash
cd terraform
terraform apply
```

Terraform ZIP dosyasının değiştiğini algılayacak ve Lambda'yı güncelleyecek!

---

## Adım 9: Terraform Destroy (Kaynakları Silme)

**⚠️ DİKKAT:** Bu komut tüm kaynakları siler!

```bash
terraform destroy
```

**Onay istediğinde:**
- `yes` yazın

**Silinecekler:**
- Lambda fonksiyonu
- SQS queue
- IAM role
- CloudWatch log groups
- Event source mapping

**Kullanım senaryoları:**
- Test ortamını temizlemek için
- Maliyetleri sıfırlamak için
- Tekrar baştan başlamak için

---

## Terraform State Yönetimi

### State Dosyası

Terraform `terraform.tfstate` dosyasında kaynakların durumunu saklar.

**⚠️ ÖNEMLİ:**
- Bu dosya hassas bilgiler içerir
- `.gitignore`'da olmalı (zaten var)
- GitHub'a push etmeyin!

### Remote State (Production için Önerilir)

Production ortamlarında state'i S3'te saklayın:

**`backend.tf` dosyası oluşturun:**

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "lambda-blog-project/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**Avantajları:**
- State güvenli saklanır
- Ekip üyeleri state'i paylaşabilir
- State locking (DynamoDB ile)

---

## Troubleshooting

### Hata: "Resource already exists"

**Sebep:** Lambda veya SQS zaten manuel olarak oluşturulmuş.

**Çözüm:**

```bash
# Mevcut kaynağı Terraform state'ine import et
terraform import aws_lambda_function.alert_lambda alert-lambda
terraform import aws_sqs_queue.alert_queue https://sqs.us-east-1.amazonaws.com/533420169013/alert-queue
```

### Hata: "Invalid function code"

**Sebep:** ZIP dosyası bulunamadı veya geçersiz.

**Çözüm:**

```bash
# Yeniden build et
cd ~/Desktop/lambda-blog-project
./scripts/build.sh

# ZIP dosyasının var olduğunu kontrol et
ls -lh build/alert-lambda.zip

# Terraform apply'ı tekrar çalıştır
cd terraform
terraform apply
```

### Hata: "Access denied"

**Sebep:** IAM permissions yetersiz.

**Çözüm:**

- AWS CLI credentials'ları kontrol edin: `aws sts get-caller-identity`
- IAM user'ın yeterli izinleri olduğundan emin olun

---

## Terraform vs Manuel Deploy

### Terraform Avantajları:

✅ **Infrastructure as Code:** Altyapı kod ile yönetilir  
✅ **Version Control:** Değişiklikler Git'te takip edilir  
✅ **Tekrarlanabilir:** Aynı altyapıyı tekrar oluşturabilirsiniz  
✅ **State Management:** Kaynak durumunu otomatik takip eder  
✅ **Plan Önizleme:** Değişiklikleri uygulamadan önce görürsünüz  

### Manuel Deploy Avantajları:

✅ **Hızlı:** Tek seferlik işlemler için daha hızlı  
✅ **Basit:** Küçük projeler için yeterli  
✅ **Esnek:** AWS Console'dan kolay değişiklik  

**Öneri:** 
- **Geliştirme/Test:** Manuel deploy yeterli
- **Production:** Terraform kullanın

---

## ✅ TAMAMLANDI!

Terraform ile deployment başarıyla tamamlandı!

### Yapılanlar:

- [x] Terraform kurulumu
- [x] Konfigürasyon hazırlandı
- [x] Terraform init
- [x] Terraform plan
- [x] Terraform apply (deploy)
- [x] Test edildi

### Sonraki Adımlar:

1. **Terraform state'i remote'a taşı** (production için)
2. **Terraform modules oluştur** (yeniden kullanım için)
3. **Terraform workspace kullan** (dev/staging/prod için)

---

## 📝 NOTLAR

- **State dosyası:** `.gitignore`'da olmalı ✅
- **tfvars dosyası:** Hassas bilgiler içerir, GitHub'a push etmeyin ✅
- **Remote state:** Production için S3 backend kullanın
- **Destroy dikkatli kullanın:** Tüm kaynakları siler!

---

**Sorularınız varsa:** Hata mesajlarını paylaşın, birlikte çözelim! 🚀

