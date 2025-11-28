# 🎓 Adım Adım Rehber: İlk Lambda Fonksiyonunuzu Oluşturun

Bu rehber, hiç Go, Terraform veya AWS bilginiz olmasa bile projeyi çalıştırmanız için hazırlanmıştır. Her adımı tek tek birlikte ilerleyeceğiz.

---

## 📋 İÇİNDEKİLER

1. [Gereksinimleri Kontrol Etme](#1-gereksinimleri-kontrol-etme)
2. [Go Kurulumu (macOS)](#2-go-kurulumu-macos)
3. [Projeyi Hazırlama](#3-projeyi-hazırlama)
4. [Kodu Anlama (Temel Seviye)](#4-kodu-anlama-temel-seviye)
5. [Local'de Test Etme](#5-localde-test-etme)
6. [AWS Hesabı Oluşturma](#6-aws-hesabı-oluşturma)
7. [AWS CLI Kurulumu](#7-aws-cli-kurulumu)
8. [AWS'de Lambda Oluşturma](#8-awsde-lambda-oluşturma)
9. [SQS Kuyruğu Oluşturma](#9-sqs-kuyruğu-oluşturma)
10. [Lambda'yı Deploy Etme](#10-lambdayı-deploy-etme)
11. [Test Etme](#11-test-etme)
12. [Sorun Giderme](#12-sorun-giderme)

---

## 1. GEREKSİNİMLERİ KONTROL ETME

Önce bilgisayarınızda hangi araçların kurulu olduğunu kontrol edelim.

### Adım 1.1: Terminal'i Açın

macOS'te Terminal'i açmak için:
- `Command + Space` tuşlarına basın
- "Terminal" yazın
- Enter'a basın

### Adım 1.2: Go Kurulu mu Kontrol Edelim

Terminal'de şu komutu yazın:

```bash
go version
```

**Eğer şöyle bir çıktı görüyorsanız:**
```
go version go1.21.0 darwin/arm64
```
✅ Go kurulu! Bir sonraki bölüme geçebilirsiniz.

**Eğer şunu görüyorsanız:**
```
command not found: go
```
❌ Go kurulu değil. Adım 2'ye geçelim ve Go'yu kuralım.

### Adım 1.3: Git Kurulu mu Kontrol Edelim

```bash
git --version
```

**Beklenen çıktı:**
```
git version 2.x.x
```

Git yoksa macOS'te otomatik kurulur, endişelenmeyin.

---

## 2. GO KURULUMU (macOS)

### Yöntem 1: Homebrew ile Kurulum (Önerilen)

#### Adım 2.1: Homebrew Kurulu mu Kontrol Edin

```bash
brew --version
```

Eğer "command not found" görüyorsanız, Homebrew'i kurmamız gerekiyor.

#### Adım 2.2: Homebrew Kurulumu

Terminal'de şu komutu çalıştırın:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Not:** Bu işlem birkaç dakika sürebilir. Şifreniz sorulabilir.

#### Adım 2.3: Go Kurulumu

Homebrew kurulduktan sonra:

```bash
brew install go
```

**Kurulum süresi:** 2-5 dakika

#### Adım 2.4: Kurulumu Doğrulayın

```bash
go version
```

Şöyle bir çıktı görmelisiniz:
```
go version go1.21.x darwin/arm64
```

### Yöntem 2: Resmi Go Sitesinden Kurulum

Eğer Homebrew çalışmazsa:

1. [https://go.dev/dl/](https://go.dev/dl/) adresine gidin
2. macOS için `.pkg` dosyasını indirin (ARM64 veya AMD64, bilgisayarınıza göre)
3. İndirilen `.pkg` dosyasına çift tıklayın
4. Kurulum sihirbazını takip edin
5. Terminal'i yeniden açın
6. `go version` ile kontrol edin

### Adım 2.5: Go Ortam Değişkenlerini Ayarlayın

Terminal'de şu komutları çalıştırın:

```bash
echo 'export GOPATH=$HOME/go' >> ~/.zshrc
echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.zshrc
source ~/.zshrc
```

**Kontrol edin:**
```bash
echo $GOPATH
```
`/Users/emregulustan/go` gibi bir yol görmelisiniz.

---

## 3. PROJEYI HAZIRLAMA

### Adım 3.1: Proje Klasörüne Gidin

Terminal'de şu komutu yazın:

```bash
cd ~/Desktop/lambda-blog-project
```

Eğer hata alırsanız, önce masaüstüne gidin:

```bash
cd ~/Desktop
ls -la
```

`lambda-blog-project` klasörünü görmelisiniz.

### Adım 3.2: Proje İçeriğini Görelim

```bash
ls -la
```

Şunları görmelisiniz:
- `cmd/` klasörü
- `internal/` klasörü
- `scripts/` klasörü
- `go.mod` dosyası
- `README.md` dosyası
- vs.

### Adım 3.3: Go Dependencies'leri İndirin

```bash
go mod download
```

**İlk kez çalıştırıyorsanız:** Bu komut birkaç saniye sürebilir. İndirme işlemlerini göreceksiniz.

**Beklenen çıktı:** Hiçbir hata mesajı yoksa, başarılı! ✅

### Adım 3.4: Dependencies'leri Kontrol Edin

```bash
go mod tidy
```

Bu komut, gereksiz paketleri temizler ve eksikleri indirir.

---

## 4. KODU ANLAMA (Temel Seviye)

Projeyi anlamak için en önemli dosyaları açıklayayım:

### Dosya Yapısı (Basit Açıklama)

```
lambda-blog-project/
├── cmd/lambda/main.go          ← Lambda'nın başlangıç noktası (BURAYA DİKKAT!)
├── internal/
│   ├── sqs/consumer.go         ← SQS mesajlarını okur
│   └── alerting/notifier.go    ← Slack'e mesaj gönderir
└── scripts/
    ├── build.sh                ← Kodu derler (ZIP yapar)
    ├── test.sh                 ← Testleri çalıştırır
    └── deploy.sh               ← AWS'ye gönderir
```

### main.go Nedir? (Çok Basit)

`cmd/lambda/main.go` dosyası programımızın **giriş noktası**dır. İşte ne yapar:

1. ✅ SQS'den mesaj alır
2. ✅ Mesajı okur
3. ✅ Slack'e gönderir

**Kod örneği (anlamak için):**

```go
// Bu fonksiyon her SQS mesajı geldiğinde çalışır
func HandleRequest(ctx context.Context, sqsEvent events.SQSEvent) error {
    // Her mesajı işle
    for _, record := range sqsEvent.Records {
        // Mesajı parse et
        alertMessage, err := sqs.ParseSQSMessage(record)
        
        // Slack'e gönder
        notifier.SendAlert(ctx, alertMessage)
    }
    return nil
}
```

**Şimdilik bu kadar yeterli!** Kodun detaylarını sonra öğrenebilirsiniz.

---

## 5. LOCAL'DE TEST ETME

AWS'ye göndermeden önce, kodu local'de test edelim.

### Adım 5.1: Testleri Çalıştırma

```bash
chmod +x scripts/test.sh
./scripts/test.sh
```

**İlk çalıştırmada:** Test dosyaları çalışacak ve sonuçları göreceksiniz.

**Beklenen çıktı:**
```
=== RUN   TestParseSQSMessage
=== RUN   TestParseSQSMessage/Valid_message
--- PASS: TestParseSQSMessage (0.00s)
...
PASS
```

✅ **Eğer "PASS" görüyorsanız:** Testler başarılı!

❌ **Eğer hata varsa:** Hata mesajını bana gönderin, birlikte çözelim.

### Adım 5.2: Kodu Derleme (Build)

```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

**Ne oluyor?**
1. Go kodu derlenir (Linux için)
2. `build/bootstrap` adında bir dosya oluşur
3. Bu dosya ZIP'lenir

**Beklenen çıktı:**
```
Building Go binary...
Binary created: 8.5M
Creating deployment package...
Deployment package created: 2.8M
Build completed successfully!
Deployment package: build/alert-lambda.zip
```

✅ **`build/alert-lambda.zip` dosyası oluştu mu?**

Kontrol edelim:

```bash
ls -lh build/
```

`alert-lambda.zip` dosyasını görmelisiniz!

---

## 6. AWS HESABI OLUŞTURMA

AWS hesabınız yoksa, ücretsiz hesap açalım.

### Adım 6.1: AWS Web Sitesine Gidin

1. Tarayıcınızı açın
2. [https://aws.amazon.com](https://aws.amazon.com) adresine gidin
3. Sağ üst köşede **"Create an AWS Account"** butonuna tıklayın

### Adım 6.2: Hesap Bilgilerini Doldurun

**Gerekli bilgiler:**
- Email adresiniz
- Şifre (güçlü bir şifre seçin)
- AWS hesap adı (örn: "emregulustan-personal")

**Ekran görüntüsü almayı unutmayın!** Blog yazısı için kullanabilirsiniz.

### Adım 6.3: İletişim Bilgileri

- Tam adınız
- Telefon numaranız
- Ülke/Adres bilgileri

### Adım 6.4: Ödeme Bilgileri

⚠️ **ÖNEMLİ:** AWS Free Tier sayesinde:
- İlk 12 ay **ücretsiz**
- Lambda: 1 milyon request/ay ücretsiz
- SQS: 1 milyon request/ay ücretsiz

Kredi kartı istemesi normal, ancak ücretsiz limitler içinde ücret alınmaz.

### Adım 6.5: Telefon Doğrulaması

- Telefon numaranıza SMS gönderilir
- Doğrulama kodunu girin

### Adım 6.6: Destek Planı Seçimi

**"Basic Plan"** seçin (ücretsiz).

### Adım 6.7: Hesap Aktivasyonu

Email'inize gelen doğrulama linkine tıklayın.

**⏳ Bekleme süresi:** Hesap aktivasyonu 1-2 saat sürebilir. Email'inizi kontrol edin.

### Adım 6.8: AWS Console'a Giriş Yapın

1. [https://console.aws.amazon.com](https://console.aws.amazon.com) adresine gidin
2. "Root user" ile giriş yapın
3. Email ve şifrenizi girin

**✅ İlk kez girdiğinizde:** Hoş geldiniz ekranını göreceksiniz!

---

## 7. AWS CLI KURULUMU

AWS CLI, komut satırından AWS servislerini yönetmemizi sağlar.

### Adım 7.1: AWS CLI Kurulumu (Homebrew ile)

```bash
brew install awscli
```

**Kurulum süresi:** 2-3 dakika

### Adım 7.2: Kurulumu Doğrulayın

```bash
aws --version
```

**Beklenen çıktı:**
```
aws-cli/2.x.x Python/3.x.x Darwin/xx.x.x source/arm64
```

### Adım 7.3: AWS Kimlik Bilgilerini Ayarlama

AWS CLI'yi kullanmak için kimlik bilgilerinizi yapılandırmalısınız.

#### Yöntem 1: IAM User Oluşturma (Önerilen)

**Neden IAM User?** Güvenlik için root kullanıcı yerine özel bir kullanıcı oluşturuyoruz.

1. **AWS Console'a gidin:** [https://console.aws.amazon.com](https://console.aws.amazon.com)

2. **IAM servisini açın:**
   - Üst arama çubuğuna "IAM" yazın
   - "IAM" servisine tıklayın

3. **Yeni kullanıcı oluşturun:**
   - Sol menüden "Users" (Kullanıcılar) seçin
   - "Add users" (Kullanıcı ekle) butonuna tıklayın
   - **User name:** `lambda-admin` yazın
   - **Access type:** "Programmatic access" seçin ✅

4. **İzinleri ekleyin:**
   - "Attach policies directly" seçin
   - "AdministratorAccess" seçin (✅ yanına tik koyun)
   - **Not:** Production için daha kısıtlı izinler kullanın!

5. **Kullanıcıyı oluşturun:**
   - "Next" butonlarına tıklayın
   - "Create user" butonuna tıklayın

6. **Access Key'i kaydedin:**
   - ⚠️ **ÖNEMLİ:** Bu ekran sadece bir kez gösterilir!
   - **Access Key ID:** (örnek: `AKIAIOSFODNN7EXAMPLE`)
   - **Secret Access Key:** (örnek: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)
   
   **Bu bilgileri güvenli bir yere kaydedin!** Şimdi kullanacağız.

#### Yöntem 2: AWS CLI ile Yapılandırma

Terminal'de şu komutu çalıştırın:

```bash
aws configure
```

**Sorular sırasıyla gelecek:**

1. **AWS Access Key ID:** 
   ```
   AKIAIOSFODNN7EXAMPLE
   ```
   (Yukarıda kaydettiğiniz Access Key ID'yi yapıştırın)

2. **AWS Secret Access Key:**
   ```
   wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   ```
   (Yukarıda kaydettiğiniz Secret Access Key'i yapıştırın)

3. **Default region name:**
   ```
   us-east-1
   ```
   (veya size yakın bir bölge: `eu-central-1`, `eu-west-1`, vb.)

4. **Default output format:**
   ```
   json
   ```
   (Enter'a basın)

**✅ Başarılı oldu mu?**

Kontrol edelim:

```bash
aws sts get-caller-identity
```

**Beklenen çıktı:**
```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/lambda-admin"
}
```

**✅ Account numarasını görüyorsanız:** AWS CLI başarıyla yapılandırıldı!

---

## 8. AWS'DE LAMBDA OLUŞTURMA

Şimdi AWS Console'dan Lambda fonksiyonumuzu oluşturalım.

### Adım 8.1: Lambda Servisine Gidin

1. AWS Console'da üst arama çubuğuna "Lambda" yazın
2. "Lambda" servisine tıklayın

### Adım 8.2: Lambda Fonksiyonu Oluşturma

1. **"Create function"** (Fonksiyon oluştur) butonuna tıklayın

2. **Fonksiyon yapılandırması:**
   - **"Author from scratch"** seçin (en üstte)
   - **Function name:** `alert-lambda` yazın
   - **Runtime:** Dropdown'dan **"Provide your own bootstrap on Amazon Linux 2023"** seçin
   - **Architecture:** **arm64** seçin (daha ucuz)
   
   **[SCREENSHOT YERİ: Lambda oluşturma ekranı]**

3. **"Create function"** butonuna tıklayın

### Adım 8.3: Lambda Fonksiyon Sayfası

✅ Lambda fonksiyonunuz oluşturuldu!

**Sayfada şunları göreceksiniz:**
- Function overview
- Code source
- Test
- Configuration
- Monitoring

### Adım 8.4: IAM Role Oluşturma (Gerekli)

Lambda fonksiyonunun SQS'den mesaj okuması için izin gerekir.

1. Lambda sayfasında **"Configuration"** sekmesine tıklayın
2. Sol menüden **"Permissions"** (İzinler) seçin
3. **"Execution role"** altında bir role göreceksiniz

**Eğer role yoksa veya yeterli izinler yoksa:**

#### Manuel Role Oluşturma:

1. **IAM Console'a gidin:**
   - Üst arama: "IAM" yazın
   - "IAM" servisine tıklayın

2. **Role oluşturun:**
   - Sol menüden "Roles" (Roller) seçin
   - "Create role" (Rol oluştur) butonuna tıklayın

3. **Trust entity:**
   - "AWS service" seçin
   - "Lambda" seçin
   - "Next" butonuna tıklayın

4. **Permissions:**
   - Policy eklemek için "Add permissions" butonuna tıklayın
   - Arama kutusuna şunları yazın ve ekleyin:
     - ✅ `AWSLambdaBasicExecutionRole` (CloudWatch logs için)
     - ✅ `AmazonSQSFullAccess` (SQS okuma/yazma için)
   - "Next" butonuna tıklayın

5. **Role adı:**
   - **Role name:** `lambda-sqs-execution-role` yazın
   - **Description:** "Lambda execution role for SQS" yazın
   - "Create role" butonuna tıklayın

6. **Role ARN'ini kopyalayın:**
   - Oluşturulan role'ü açın
   - "ARN" değerini kopyalayın (örn: `arn:aws:iam::123456789012:role/lambda-sqs-execution-role`)
   - Bu ARN'i bir yere kaydedin, deploy script'inde kullanacağız!

### Adım 8.5: Lambda'ya Role Atama

1. Lambda fonksiyon sayfasına geri dönün
2. **Configuration > Permissions**
3. **"Edit"** butonuna tıklayın
4. **"Use an existing role"** seçin
5. Dropdown'dan `lambda-sqs-execution-role` seçin
6. **"Save"** butonuna tıklayın

**✅ Lambda fonksiyonunuz hazır!**

---

## 9. SQS KUYRUĞU OLUŞTURMA

SQS, mesajların bekletildiği bir kuyruktur.

### Adım 9.1: SQS Console'a Gidin

1. AWS Console'da üst arama: "SQS" yazın
2. "Simple Queue Service" servisine tıklayın

### Adım 9.2: Queue Oluşturma

1. **"Create queue"** (Kuyruk oluştur) butonuna tıklayın

2. **Queue yapılandırması:**
   - **Queue type:** "Standard" seçin
   - **Name:** `alert-queue` yazın
   
   **[SCREENSHOT YERİ: SQS queue oluşturma ekranı]**

3. **Configuration (Ayarlar):**
   - **Visibility timeout:** `60` saniye (Lambda timeout'undan büyük olmalı)
   - **Message retention period:** `4 days` (345600 saniye)
   
   Diğer ayarları şimdilik varsayılan bırakabilirsiniz.

4. **"Create queue"** butonuna tıklayın

### Adım 9.3: Queue URL'ini Kaydedin

✅ Queue oluşturuldu!

**Queue sayfasında:**
- **URL** sütununda bir URL göreceksiniz (örn: `https://sqs.us-east-1.amazonaws.com/123456789012/alert-queue`)
- Bu URL'yi kopyalayın ve kaydedin!

### Adım 9.4: Dead Letter Queue (Opsiyonel ama Önerilen)

Başarısız mesajlar için DLQ oluşturalım:

1. **"Create queue"** butonuna tekrar tıklayın
2. **Name:** `alert-queue-dlq` yazın
3. **"Create queue"** butonuna tıklayın

**✅ DLQ hazır!**

---

## 10. LAMBDAYI DEPLOY ETME

Şimdi kodumuzu Lambda'ya yükleyelim.

### Adım 10.1: Environment Variables Hazırlama

Proje klasöründe `.env` dosyası oluşturalım:

```bash
cd ~/Desktop/lambda-blog-project
cp .env.example .env
```

`.env` dosyasını düzenleyin:

```bash
nano .env
```

**Veya TextEdit ile açın:**

```bash
open -a TextEdit .env
```

**.env dosyasını şu şekilde düzenleyin:**

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Lambda Configuration
LAMBDA_FUNCTION_NAME=alert-lambda
LAMBDA_ROLE_ARN=arn:aws:iam::123456789012:role/lambda-sqs-execution-role
LAMBDA_MEMORY=128
LAMBDA_TIMEOUT=30
LAMBDA_ARCHITECTURE=arm64

# SQS Configuration
SQS_QUEUE_NAME=alert-queue

# Slack Configuration (Opsiyonel - şimdilik boş bırakabilirsiniz)
SLACK_WEBHOOK_URL=
```

**Değiştirmeniz gerekenler:**
- `AWS_REGION`: Bölgenizi yazın (örn: `us-east-1`, `eu-central-1`)
- `AWS_ACCESS_KEY_ID`: AWS CLI'ye girdiğiniz Access Key ID
- `AWS_SECRET_ACCESS_KEY`: AWS CLI'ye girdiğiniz Secret Access Key
- `LAMBDA_ROLE_ARN`: Adım 8.4'te oluşturduğunuz role ARN'i
- `SQS_QUEUE_NAME`: `alert-queue`

**Dosyayı kaydedin ve kapatın.**

### Adım 10.2: Environment Variables'ı Yükleme

```bash
source .env
```

**Kontrol edin:**
```bash
echo $LAMBDA_FUNCTION_NAME
```

`alert-lambda` yazması gerekir.

### Adım 10.3: Lambda ZIP Dosyasını Build Etme

```bash
./scripts/build.sh
```

**✅ `build/alert-lambda.zip` dosyası oluştu mu?**

```bash
ls -lh build/
```

### Adım 10.4: Lambda'ya Kod Yükleme

#### Yöntem 1: AWS Console ile (Kolay)

1. **Lambda Console'a gidin:**
   - AWS Console > Lambda > Functions > `alert-lambda`

2. **Code sekmesine gidin:**
   - Sayfanın üst kısmında "Code" sekmesine tıklayın

3. **Upload from .zip file:**
   - "Upload from" dropdown'ına tıklayın
   - ".zip file" seçin
   - "Upload" butonuna tıklayın
   - Bilgisayarınızdan `build/alert-lambda.zip` dosyasını seçin
   - "Save" butonuna tıklayın

**⏳ Yükleme süresi:** 10-30 saniye

#### Yöntem 2: AWS CLI ile (Hızlı)

```bash
aws lambda update-function-code \
  --function-name alert-lambda \
  --zip-file fileb://build/alert-lambda.zip \
  --region us-east-1
```

**Beklenen çıktı:**
```json
{
    "FunctionName": "alert-lambda",
    "LastUpdateStatus": "InProgress",
    ...
}
```

### Adım 10.5: Environment Variables Ayarlama

1. Lambda sayfasında **"Configuration"** sekmesine tıklayın
2. Sol menüden **"Environment variables"** seçin
3. **"Edit"** butonuna tıklayın
4. **"Add environment variable"** butonuna tıklayın:
   - **Key:** `SLACK_WEBHOOK_URL`
   - **Value:** (şimdilik boş bırakabilirsiniz veya Slack webhook URL'inizi yazın)
5. **"Save"** butonuna tıklayın

### Adım 10.6: Lambda Handler Ayarlama

1. **Configuration > General configuration**
2. **"Edit"** butonuna tıklayın
3. **Handler:** `bootstrap` yazın (zaten yazılı olmalı)
4. **"Save"** butonuna tıklayın

### Adım 10.7: SQS Trigger Ekleme

Lambda'ya SQS'den mesaj geldiğinde tetiklenmesini söyleyelim:

1. Lambda sayfasında **"Add trigger"** butonuna tıklayın

2. **Trigger configuration:**
   - **SQS** seçin
   - **SQS queue:** `alert-queue` seçin
   - **Batch size:** `10` (varsayılan)
   - **"Add"** butonuna tıklayın

**✅ Trigger eklendi!**

**[SCREENSHOT YERİ: Lambda trigger ekranı]**

---

## 11. TEST ETME

### Adım 11.1: SQS'e Test Mesajı Gönderme

Terminal'de:

```bash
# Önce SQS Queue URL'ini alın
SQS_URL=$(aws sqs get-queue-url \
  --queue-name alert-queue \
  --query 'QueueUrl' \
  --output text)

echo "Queue URL: $SQS_URL"
```

**Queue URL'i görüyor musunuz?** (örn: `https://sqs.us-east-1.amazonaws.com/123456789012/alert-queue`)

Şimdi test mesajı gönderelim:

```bash
aws sqs send-message \
  --queue-url "$SQS_URL" \
  --message-body '{
    "level": "info",
    "service": "test-service",
    "message": "Merhaba Lambda! Bu bir test mesajıdır.",
    "timestamp": "2025-11-28T10:00:00Z"
  }'
```

**Beklenen çıktı:**
```json
{
    "MD5OfMessageBody": "...",
    "MessageId": "..."
}
```

**✅ Mesaj gönderildi!**

### Adım 11.2: Lambda Loglarını Kontrol Etme

Lambda fonksiyonumuz mesajı aldı mı? Logları kontrol edelim:

```bash
aws logs tail /aws/lambda/alert-lambda --follow
```

**Beklenen log çıktısı:**
```
2025-11-28T10:00:00.000Z	[INFO] Received 1 SQS messages
2025-11-28T10:00:00.100Z	[INFO] Processing message test-message-1
2025-11-28T10:00:00.200Z	[INFO] Parsed alert: Level=info, Service=test-service
2025-11-28T10:00:00.300Z	[INFO] Successfully processed message
```

**✅ Logları görüyorsanız:** Lambda çalışıyor!

**Logları durdurmak için:** `Ctrl + C` tuşlarına basın.

### Adım 11.3: CloudWatch Console'dan Kontrol

1. AWS Console'da **CloudWatch** servisine gidin
2. Sol menüden **"Log groups"** seçin
3. `/aws/lambda/alert-lambda` log group'unu bulun ve tıklayın
4. En son log stream'ini açın
5. Logları görüntüleyin

**[SCREENSHOT YERİ: CloudWatch Logs]**

### Adım 11.4: Lambda Metriklerini Kontrol

1. Lambda sayfasında **"Monitoring"** sekmesine tıklayın
2. Grafikleri görüntüleyin:
   - **Invocations:** Kaç kez çağrıldı
   - **Duration:** Ne kadar sürdü
   - **Errors:** Hata var mı

**✅ Her şey yeşil ise:** Başarılı! 🎉

---

## 12. SORUN GİDERME

### Sorun 1: "command not found: go"

**Çözüm:**
```bash
# Go'nun kurulu olup olmadığını kontrol edin
which go

# Eğer bulunamazsa, PATH'e ekleyin
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
source ~/.zshrc
```

### Sorun 2: "aws: command not found"

**Çözüm:**
```bash
# Homebrew ile kurun
brew install awscli

# veya pip ile
pip3 install awscli
```

### Sorun 3: "Access Denied" hatası

**Çözüm:**
- AWS CLI kimlik bilgilerinizi kontrol edin: `aws configure list`
- IAM user'ın yeterli izinleri olduğundan emin olun
- Role ARN'inin doğru olduğunu kontrol edin

### Sorun 4: Lambda timeout oluyor

**Çözüm:**
1. Lambda sayfasında **Configuration > General configuration**
2. **Timeout** değerini artırın (örn: 60 saniye)

### Sorun 5: SQS mesajları işlenmiyor

**Çözüm:**
1. Event source mapping'in enabled olduğunu kontrol edin
2. Lambda IAM role'ünün SQS okuma izinleri olduğundan emin olun
3. SQS visibility timeout'unun Lambda timeout'undan büyük olduğunu kontrol edin

### Sorun 6: Build hatası

**Çözüm:**
```bash
# Dependencies'i temizleyip yeniden indirin
rm go.sum
go mod tidy
go mod download

# Build'i tekrar deneyin
./scripts/build.sh
```

---

## 🎉 TEBRİKLER!

Lambda fonksiyonunuz başarıyla çalışıyor! 

### Sonraki Adımlar:

1. ✅ **Slack Entegrasyonu:** Slack webhook URL ekleyin
2. ✅ **GitHub Actions:** CI/CD pipeline kurun
3. ✅ **Monitoring:** CloudWatch alarmları ekleyin
4. ✅ **Blog Yazısı:** Ekran görüntülerini alın ve yayınlayın

### Yardıma mı İhtiyacınız Var?

Herhangi bir adımda takıldığınızda:
- Hata mesajını kopyalayın
- Hangi adımda olduğunuzu belirtin
- Benimle paylaşın, birlikte çözelim!

---

## 📝 NOTLAR

- **AWS Free Tier:** İlk 12 ay ücretsiz kullanım
- **Lambda Limitleri:** 1 milyon request/ay ücretsiz
- **SQS Limitleri:** 1 milyon request/ay ücretsiz
- **CloudWatch:** İlk 5GB log ücretsiz

**Maliyet endişesi:** Free Tier limitleri içinde kalırsanız ücret alınmaz! 💰

---

**Son güncelleme:** 28 Kasım 2025

