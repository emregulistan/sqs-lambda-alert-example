# 🚀 Sonraki Adımlar - Detaylı Rehber

Lambda fonksiyonunuz çalışıyor! Şimdi sistemi daha da geliştirelim ve blog yazısı için gerekli ekran görüntülerini alalım.

---

## 📋 İÇİNDEKİLER

1. [AWS Console'da Kaynakları İnceleme](#1-aws-consoleda-kaynakları-inceleme)
2. [Slack Entegrasyonu (Opsiyonel)](#2-slack-entegrasyonu-opsiyonel)
3. [Daha Fazla Test Mesajı Gönderme](#3-daha-fazla-test-mesajı-gönderme)
4. [CloudWatch Metrics ve Monitoring](#4-cloudwatch-metrics-ve-monitoring)
5. [Blog Yazısı için Ekran Görüntüleri](#5-blog-yazısı-için-ekran-görüntüleri)
6. [GitHub Actions CI/CD (Opsiyonel)](#6-github-actions-cicd-opsiyonel)
7. [Kod Güncelleme ve Yeniden Deploy](#7-kod-güncelleme-ve-yeniden-deploy)

---

## 1. AWS Console'da Kaynakları İnceleme

AWS Console'da Lambda, SQS ve CloudWatch'ı görsel olarak inceleyelim.

### Adım 1.1: Lambda Console'a Giriş

1. **Tarayıcınızı açın** (Chrome, Safari, Firefox)
2. **AWS Console'a giriş yapın:**
   - [https://console.aws.amazon.com](https://console.aws.amazon.com) adresine gidin
   - Email ve şifrenizle giriş yapın

3. **Lambda servisine gidin:**
   - Üst arama çubuğuna **"Lambda"** yazın
   - "Lambda" servisine tıklayın

4. **Fonksiyonunuzu bulun:**
   - Sol menüden **"Functions"** (Fonksiyonlar) seçin
   - **`alert-lambda`** fonksiyonuna tıklayın

### Adım 1.2: Lambda Sayfasını İnceleme

**Sayfada şunları göreceksiniz:**

- **Configuration (Yapılandırma):** 
  - General configuration: Memory, Timeout, Handler
  - Environment variables: SLACK_WEBHOOK_URL (şimdilik boş)
  - Permissions: IAM role bilgisi
  
- **Code (Kod):**
  - Lambda kodunuzu gösterir
  - "Upload from" ile kod güncelleyebilirsiniz
  
- **Test (Test):**
  - Test event oluşturup Lambda'yı manuel test edebilirsiniz
  
- **Monitoring (İzleme):**
  - Invocations (Çağrı sayısı)
  - Duration (Çalışma süresi)
  - Errors (Hata sayısı)
  - Throttles (Rate limit aşımları)

**[SCREENSHOT ALACAĞINIZ YER: Lambda fonksiyon sayfası - Genel görünüm]**

### Adım 1.3: SQS Console'a Giriş

1. **AWS Console'da üst arama:** **"SQS"** yazın
2. **"Simple Queue Service"** servisine tıklayın
3. **`alert-queue`** kuyruğuna tıklayın

**Sayfada şunları göreceksiniz:**

- **Queue details:** Queue URL, ARN bilgileri
- **Monitoring:** Mesaj istatistikleri
- **Access policy:** İzin politikaları
- **Dead-letter queue settings:** DLQ ayarları (opsiyonel)

**[SCREENSHOT ALACAĞINIZ YER: SQS queue sayfası]**

### Adım 1.4: CloudWatch Logs İnceleme

1. **AWS Console'da üst arama:** **"CloudWatch"** yazın
2. **"CloudWatch"** servisine tıklayın
3. **Sol menüden "Log groups"** seçin
4. **`/aws/lambda/alert-lambda`** log group'una tıklayın
5. **En son log stream'i açın**

**Burada Lambda'nın tüm loglarını göreceksiniz:**
- Mesaj işleme logları
- Hata mesajları (varsa)
- Timestamp'ler

**[SCREENSHOT ALACAĞINIZ YER: CloudWatch Logs - Lambda log çıktısı]**

---

## 2. Slack Entegrasyonu (Opsiyonel)

Slack'e bildirim göndermek istiyorsanız, önce bir Slack webhook URL'i oluşturmanız gerekir.

### Adım 2.1: Slack Webhook URL Oluşturma

1. **Slack Workspace'inize giriş yapın:**
   - [https://slack.com](https://slack.com) adresine gidin
   - Workspace'inize giriş yapın

2. **Slack API sayfasına gidin:**
   - [https://api.slack.com/apps](https://api.slack.com/apps) adresine gidin
   - **"Create New App"** (Yeni Uygulama Oluştur) butonuna tıklayın

3. **"From scratch" seçin:**
   - App name: `lambda-alert-bot` (veya istediğiniz bir isim)
   - Pick a workspace: Workspace'inizi seçin
   - **"Create App"** butonuna tıklayın

4. **Incoming Webhooks'u aktif edin:**
   - Sol menüden **"Incoming Webhooks"** seçin
   - **"Activate Incoming Webhooks"** toggle'ını açın (ON yapın)

5. **Webhook ekleyin:**
   - Aşağıya scroll edin
   - **"Add New Webhook to Workspace"** butonuna tıklayın
   - Kanal seçin (örn: `#alerts`, `#general`, `#test`)
   - **"Allow"** butonuna tıklayın

6. **Webhook URL'i kopyalayın:**
   - **"Webhook URL"** kısmında bir URL göreceksiniz:
     ```
     https://hooks.slack.com/services/YOUR/WEBHOOK/URL
     ```
   - Bu URL'i kopyalayın ve güvenli bir yere kaydedin!

**⚠️ ÖNEMLİ:** Bu URL hassas bir bilgi! Kimseyle paylaşmayın.

### Adım 2.2: Lambda'ya Slack Webhook URL Ekleme

**Yöntem 1: AWS CLI ile (Kolay)**

Terminal'de şu komutu çalıştırın:

```bash
# Webhook URL'inizi buraya yapıştırın
WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

aws lambda update-function-configuration \
  --function-name alert-lambda \
  --environment "Variables={SLACK_WEBHOOK_URL=$WEBHOOK_URL}" \
  --region us-east-1
```

**Örnek:**
```bash
aws lambda update-function-configuration \
  --function-name alert-lambda \
  --environment "Variables={SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL}" \
  --region us-east-1
```

**Yöntem 2: AWS Console ile**

1. Lambda Console > `alert-lambda` fonksiyonuna gidin
2. **"Configuration"** sekmesine tıklayın
3. Sol menüden **"Environment variables"** seçin
4. **"Edit"** butonuna tıklayın
5. **"Add environment variable"** butonuna tıklayın:
   - **Key:** `SLACK_WEBHOOK_URL`
   - **Value:** Webhook URL'inizi yapıştırın
6. **"Save"** butonuna tıklayın

**[SCREENSHOT ALACAĞINIZ YER: Lambda Environment Variables ekranı]**

### Adım 2.3: Slack Entegrasyonunu Test Etme

Şimdi bir test mesajı gönderin:

```bash
aws sqs send-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/533420169013/alert-queue \
  --message-body '{
    "level": "error",
    "service": "payment-service",
    "message": "Payment gateway connection failed!",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "metadata": {
      "gateway": "stripe",
      "error_code": "CONNECTION_TIMEOUT"
    }
  }'
```

**Birkaç saniye bekleyin ve Slack kanalınızı kontrol edin!**

Slack'te şöyle bir mesaj görmelisiniz:

```
🔔 error Alert from payment-service
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Payment gateway connection failed!

Service: payment-service
Level: error
Message ID: ...
```

**[SCREENSHOT ALACAĞINIZ YER: Slack'te gelen alert mesajı]**

---

## 3. Daha Fazla Test Mesajı Gönderme

Farklı alert seviyeleriyle test mesajları gönderelim.

### Adım 3.1: Info Seviyesi Alert

```bash
aws sqs send-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/533420169013/alert-queue \
  --message-body '{
    "level": "info",
    "service": "user-service",
    "message": "New user registered successfully",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "metadata": {
      "user_id": "12345",
      "email": "user@example.com"
    }
  }'
```

### Adım 3.2: Warning Seviyesi Alert

```bash
aws sqs send-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/533420169013/alert-queue \
  --message-body '{
    "level": "warning",
    "service": "api-server",
    "message": "High response time detected",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "metadata": {
      "response_time_ms": 3500,
      "endpoint": "/api/users",
      "threshold_ms": 2000
    }
  }'
```

### Adım 3.3: Critical Seviyesi Alert

```bash
aws sqs send-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/533420169013/alert-queue \
  --message-body '{
    "level": "critical",
    "service": "database",
    "message": "Database connection pool exhausted!",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "metadata": {
      "active_connections": 100,
      "max_connections": 100,
      "queue_length": 50
    }
  }'
```

### Adım 3.4: Batch Mesaj Gönderme

Aynı anda birden fazla mesaj göndermek için:

```bash
for i in {1..5}; do
  aws sqs send-message \
    --queue-url https://sqs.us-east-1.amazonaws.com/533420169013/alert-queue \
    --message-body "{
      \"level\": \"info\",
      \"service\": \"test-service\",
      \"message\": \"Test message number $i\",
      \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
    }"
  echo "Message $i sent"
  sleep 1
done
```

**Logları izlemek için:**

```bash
aws logs tail /aws/lambda/alert-lambda --follow --region us-east-1
```

---

## 4. CloudWatch Metrics ve Monitoring

Lambda'nın performansını ve sağlığını izleyelim.

### Adım 4.1: Lambda Monitoring Dashboard

1. **Lambda Console > `alert-lambda` fonksiyonuna gidin**
2. **"Monitoring"** sekmesine tıklayın

**Grafiklerde şunları göreceksiniz:**

- **Invocations:** Kaç kez çağrıldı
- **Duration:** Ortalama çalışma süresi
- **Errors:** Hata sayısı
- **Throttles:** Rate limit aşımları
- **Concurrent executions:** Eşzamanlı çalışan instance sayısı

**[SCREENSHOT ALACAĞINIZ YER: Lambda Monitoring Dashboard]**

### Adım 4.2: CloudWatch Metrics

1. **CloudWatch Console'a gidin**
2. **Sol menüden "Metrics" > "All metrics" seçin**
3. **"AWS/Lambda" namespace'ine tıklayın**
4. **"By Function Name" seçin**
5. **`alert-lambda` fonksiyonunu seçin**

**Farklı metrikleri görüntüleyebilirsiniz:**
- Duration (ortalama, maksimum, minimum)
- Errors (toplam, oran)
- Invocations (toplam, rate)
- Throttles

**[SCREENSHOT ALACAĞINIZ YER: CloudWatch Metrics grafikleri]**

### Adım 4.3: CloudWatch Alarm Oluşturma

Lambda'da hata olduğunda uyarı almak için:

**Terminal ile:**

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name lambda-alert-errors \
  --alarm-description "Alert when Lambda has errors" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=FunctionName,Value=alert-lambda \
  --region us-east-1
```

**AWS Console ile:**

1. **CloudWatch Console > "Alarms" > "All alarms"**
2. **"Create alarm"** butonuna tıklayın
3. **"Select metric"** butonuna tıklayın
4. **"AWS/Lambda" > "By Function Name" > `alert-lambda`**
5. **"Errors" metrik'ini seçin**
6. **Alarm ayarlarını yapın:**
   - Statistic: Sum
   - Period: 5 minutes
   - Threshold: 5
   - Comparison: Greater than
7. **Notification ayarları (opsiyonel):**
   - SNS topic oluşturup email/SMS bildirimi ekleyebilirsiniz
8. **"Next" > "Create alarm"**

---

## 5. Blog Yazısı için Ekran Görüntüleri

Blog yazınız için gerekli ekran görüntülerini alalım.

### Adım 5.1: Ekran Görüntüsü Alma (macOS)

**macOS'te ekran görüntüsü alma:**

1. **Tüm ekran:** `Command + Shift + 3`
2. **Seçilen alan:** `Command + Shift + 4` (sonra alan seçin)
3. **Pencere:** `Command + Shift + 4` + `Space` (sonra pencereye tıklayın)

**Ekran görüntüleri masaüstüne kaydedilir:** `Screenshot 2025-11-28 at 13.45.30.png`

### Adım 5.2: GIF Kaydı (Opsiyonel)

**GIF kaydı için araçlar:**

- **Kap:** [getkap.co](https://getkap.co) - Ücretsiz, macOS için
- **CleanShot X:** Ücretli ama profesyonel
- **QuickTime Player:** Video kaydı yapıp GIF'e dönüştürebilirsiniz

### Adım 5.3: Alınacak Ekran Görüntüleri Listesi

#### 1. Lambda Fonksiyonu Oluşturma

**Ne zaman alınacak:** Yeni bir Lambda fonksiyonu oluştururken

**Nerede:**
- AWS Console > Lambda > Create function
- "Author from scratch" seçili
- Function name: `alert-lambda`
- Runtime: "Provide your own bootstrap on Amazon Linux 2023"
- Architecture: `arm64`

**Görüntü:** Create function sayfasının tamamı

**[SCREENSHOT-1: Lambda oluşturma ekranı]**

#### 2. Lambda Fonksiyon Sayfası (Genel Görünüm)

**Ne zaman alınacak:** Lambda fonksiyonuna tıkladıktan sonra

**Nerede:**
- Lambda Console > `alert-lambda`
- Code, Configuration, Test, Monitoring sekmeleri görünür olmalı

**[SCREENSHOT-2: Lambda fonksiyon sayfası]**

#### 3. Environment Variables

**Ne zaman alınacak:** Environment variables sayfası açıkken

**Nerede:**
- Lambda > Configuration > Environment variables
- SLACK_WEBHOOK_URL variable'ı görünür olmalı

**[SCREENSHOT-3: Environment variables ekranı]**

#### 4. SQS Queue Oluşturma

**Ne zaman alınacak:** Yeni SQS queue oluştururken

**Nerede:**
- SQS Console > Create queue
- Queue name: `alert-queue`
- Queue type: Standard

**[SCREENSHOT-4: SQS queue oluşturma ekranı]**

#### 5. SQS Queue Sayfası

**Ne zaman alınacak:** Queue'ya tıkladıktan sonra

**Nerede:**
- SQS Console > `alert-queue`
- Queue details ve monitoring bilgileri görünür

**[SCREENSHOT-5: SQS queue sayfası]**

#### 6. Lambda Trigger (Event Source Mapping)

**Ne zaman alınacak:** Lambda'ya SQS trigger eklerken

**Nerede:**
- Lambda > Configuration > Triggers
- SQS trigger görünür
- Event source mapping detayları

**[SCREENSHOT-6: Lambda trigger configuration]**

#### 7. CloudWatch Logs

**Ne zaman alınacak:** Log'ları görüntülerken

**Nerede:**
- CloudWatch > Log groups > `/aws/lambda/alert-lambda`
- Log stream açık
- Lambda çıktıları görünür

**[SCREENSHOT-7: CloudWatch Logs çıktısı]**

#### 8. Lambda Monitoring Dashboard

**Ne zaman alınacak:** Monitoring sekmesinde

**Nerede:**
- Lambda > Monitoring
- Invocations, Duration, Errors grafikleri görünür

**[SCREENSHOT-8: Lambda monitoring dashboard]**

#### 9. Slack Alert Mesajı

**Ne zaman alınacak:** Slack'e mesaj geldikten sonra

**Nerede:**
- Slack workspace'inizde seçtiğiniz kanal
- Alert mesajı görünür (renkli, formatlanmış)

**[SCREENSHOT-9: Slack'te alert mesajı]**

#### 10. GitHub Actions Pipeline (Opsiyonel)

**Ne zaman alınacak:** GitHub Actions workflow çalıştıktan sonra

**Nerede:**
- GitHub repository > Actions sekmesi
- Başarılı deployment pipeline görünür

**[SCREENSHOT-10: GitHub Actions pipeline]**

### Adım 5.4: Ekran Görüntülerini Düzenleme

**Önerilen araçlar:**

1. **macOS Preview:** Basit düzenlemeler için
   - Ekran görüntüsünü açın
   - Tools > Annotate ile işaretleme yapabilirsiniz

2. **Canva:** Ücretsiz, online
   - [canva.com](https://canva.com)
   - Ekran görüntüsü üzerine ok, metin ekleyebilirsiniz

3. **Skitch:** Ücretsiz, basit
   - Evernote'un eski araçlarından

**Düzenleme ipuçları:**
- Önemli kısımları kırmızı ok ile işaretleyin
- Açıklayıcı metinler ekleyin
- Gereksiz kısımları crop edin (kesin)
- Tutarlı bir stil kullanın

---

## 6. GitHub Actions CI/CD (Opsiyonel)

Kodunuzu GitHub'a push ettiğinizde otomatik deploy yapmak istiyorsanız.

### Adım 6.1: GitHub Repository Oluşturma

1. **GitHub'a gidin:** [https://github.com](https://github.com)
2. **Giriş yapın** (yoksa hesap oluşturun)
3. **Sağ üst köşede "+" > "New repository"**
4. **Repository bilgileri:**
   - Repository name: `lambda-blog-project`
   - Description: "AWS Lambda alert system with SQS and Slack"
   - Public veya Private seçin
   - **"Create repository"** butonuna tıklayın

### Adım 6.2: Projeyi GitHub'a Push Etme

**Terminal'de:**

```bash
cd ~/Desktop/lambda-blog-project

# Git repository başlat (eğer yapılmadıysa)
git init

# .env dosyasını .gitignore'a ekle (zaten ekli olmalı)
echo ".env" >> .gitignore

# Tüm dosyaları ekle
git add .

# İlk commit
git commit -m "Initial commit: Lambda alert system"

# GitHub repository'nizi ekleyin (URL'i kendi repository'nizle değiştirin)
git remote add origin https://github.com/KULLANICI_ADI/lambda-blog-project.git

# Main branch'e push
git branch -M main
git push -u origin main
```

**⚠️ NOT:** `.env` dosyasını asla GitHub'a push etmeyin! Hassas bilgiler içerir.

### Adım 6.3: GitHub Secrets Ayarlama

1. **GitHub repository'nize gidin**
2. **Settings > Secrets and variables > Actions**
3. **"New repository secret"** butonuna tıklayın
4. **Şu secret'ları ekleyin:**

**Secret 1: AWS_ACCESS_KEY_ID**
- Name: `AWS_ACCESS_KEY_ID`
- Value: `YOUR_AWS_ACCESS_KEY_ID` (AWS Console'dan alacağınız access key)

**Secret 2: AWS_SECRET_ACCESS_KEY**
- Name: `AWS_SECRET_ACCESS_KEY`
- Value: `YOUR_AWS_SECRET_ACCESS_KEY` (AWS Console'dan alacağınız secret key)

**Secret 3: AWS_REGION**
- Name: `AWS_REGION`
- Value: `us-east-1`

**Secret 4: LAMBDA_FUNCTION_NAME**
- Name: `LAMBDA_FUNCTION_NAME`
- Value: `alert-lambda`

**Secret 5: LAMBDA_ROLE_ARN**
- Name: `LAMBDA_ROLE_ARN`
- Value: `arn:aws:iam::533420169013:role/lambda-execution-role`

**Secret 6: SQS_QUEUE_NAME**
- Name: `SQS_QUEUE_NAME`
- Value: `alert-queue`

**Secret 7: SLACK_WEBHOOK_URL (Opsiyonel)**
- Name: `SLACK_WEBHOOK_URL`
- Value: Webhook URL'iniz

**[SCREENSHOT ALACAĞINIZ YER: GitHub Secrets sayfası]**

### Adım 6.4: GitHub Actions Workflow Test Etme

1. **Kodda küçük bir değişiklik yapın:**
   ```bash
   # README.md dosyasına bir satır ekleyin
   echo "" >> README.md
   echo "Last updated: $(date)" >> README.md
   ```

2. **Commit ve push edin:**
   ```bash
   git add README.md
   git commit -m "Update README"
   git push
   ```

3. **GitHub Actions sekmesine gidin:**
   - Repository > Actions sekmesi
   - Workflow'un çalıştığını göreceksiniz

4. **Workflow'u izleyin:**
   - Test adımı
   - Build adımı
   - Deploy adımı

**Başarılı olursa:** Lambda otomatik olarak güncellenecek!

**[SCREENSHOT ALACAĞINIZ YER: GitHub Actions başarılı pipeline]**

---

## 7. Kod Güncelleme ve Yeniden Deploy

Kodunuzu değiştirdikten sonra yeniden deploy etmek.

### Adım 7.1: Kodu Güncelleme

Örnek: Lambda handler'da bir log mesajı ekleyelim.

**Dosyayı düzenleyin:**
```bash
nano ~/Desktop/lambda-blog-project/cmd/lambda/main.go
```

**Örnek değişiklik:**
```go
func HandleRequest(ctx context.Context, sqsEvent events.SQSEvent) error {
	log.Printf("🚀 Lambda function started - Received %d SQS messages", len(sqsEvent.Records))
	// ... geri kalan kod
}
```

### Adım 7.2: Test Etme

```bash
cd ~/Desktop/lambda-blog-project
./scripts/test.sh
```

### Adım 7.3: Yeniden Build

```bash
./scripts/build.sh
```

### Adım 7.4: Lambda'yı Güncelleme

**Yöntem 1: Deploy Script ile**

```bash
source .env
./scripts/deploy.sh
```

**Yöntem 2: AWS CLI ile (Hızlı)**

```bash
aws lambda update-function-code \
  --function-name alert-lambda \
  --zip-file fileb://build/alert-lambda.zip \
  --region us-east-1
```

**Yöntem 3: AWS Console ile**

1. Lambda Console > `alert-lambda`
2. Code sekmesi
3. "Upload from" > ".zip file"
4. `build/alert-lambda.zip` dosyasını seçin
5. Upload

### Adım 7.5: Yeni Versiyonu Test Etme

```bash
aws sqs send-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/533420169013/alert-queue \
  --message-body '{
    "level": "info",
    "service": "test",
    "message": "Testing updated Lambda function",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }'
```

**Logları kontrol edin:**
```bash
aws logs tail /aws/lambda/alert-lambda --follow --region us-east-1
```

Yeni log mesajınızı görmelisiniz: `🚀 Lambda function started...`

---

## 📊 İlerleme Kontrol Listesi

Tüm adımları tamamladınız mı? İşte kontrol listesi:

### ✅ AWS Console İnceleme
- [ ] Lambda fonksiyon sayfasını inceledim
- [ ] SQS queue sayfasını inceledim
- [ ] CloudWatch logs'u görüntüledim

### ✅ Slack Entegrasyonu (Opsiyonel)
- [ ] Slack webhook URL oluşturdum
- [ ] Lambda'ya webhook URL ekledim
- [ ] Slack'te test mesajı aldım

### ✅ Test Mesajları
- [ ] Farklı seviyelerde alert gönderdim (info, warning, error, critical)
- [ ] Batch mesaj gönderdim
- [ ] Logları kontrol ettim

### ✅ Monitoring
- [ ] Lambda monitoring dashboard'u inceledim
- [ ] CloudWatch metrics'e baktım
- [ ] CloudWatch alarm oluşturdum (opsiyonel)

### ✅ Blog Yazısı için Ekran Görüntüleri
- [ ] Lambda oluşturma ekranı
- [ ] Lambda fonksiyon sayfası
- [ ] Environment variables
- [ ] SQS queue oluşturma
- [ ] SQS queue sayfası
- [ ] Lambda trigger
- [ ] CloudWatch logs
- [ ] Lambda monitoring
- [ ] Slack alert mesajı
- [ ] GitHub Actions (opsiyonel)

### ✅ GitHub Actions CI/CD (Opsiyonel)
- [ ] GitHub repository oluşturdum
- [ ] Kodu push ettim
- [ ] Secrets ekledim
- [ ] Workflow'u test ettim

### ✅ Kod Güncelleme
- [ ] Kodu güncelledim
- [ ] Test ettim
- [ ] Build ettim
- [ ] Deploy ettim
- [ ] Yeni versiyonu test ettim

---

## 🎉 Tebrikler!

Artık AWS Lambda ile tam bir alert sistemi kurmuş durumdasınız! 

### Ne Öğrendiniz?

✅ AWS Lambda fonksiyonu oluşturma  
✅ SQS queue oluşturma ve bağlama  
✅ Go ile Lambda geliştirme  
✅ Slack entegrasyonu  
✅ CloudWatch monitoring  
✅ CI/CD pipeline kurulumu  

### Sonraki Adımlar

1. **Blog yazınızı yayınlayın:** `blog-yazisi.md` dosyasını Medium'a kopyalayın
2. **Ekran görüntülerini ekleyin:** Yukarıdaki listeden alınan görüntüleri yerleştirin
3. **Projeyi geliştirin:** Email notifier, PagerDuty entegrasyonu ekleyin
4. **Paylaşın:** GitHub'da projenizi paylaşın, başkalarının katkıda bulunmasına izin verin

---

## ❓ Yardıma mı İhtiyacınız Var?

Herhangi bir adımda takıldıysanız:
- Hata mesajını bana gönderin
- Hangi adımda olduğunuzu belirtin
- Birlikte çözelim!

**İyi çalışmalar! 🚀**

