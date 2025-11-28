# 🚀 GitHub Repository Kurulumu

Git commit'i hazır! Şimdi GitHub'da repository oluşturup push edelim.

---

## Adım 1: GitHub'da Repository Oluşturma

### 1.1 GitHub'a Giriş Yapın

1. Tarayıcınızı açın
2. [https://github.com](https://github.com) adresine gidin
3. Giriş yapın (veya hesap oluşturun)

### 1.2 Yeni Repository Oluşturun

1. Sağ üst köşede **"+"** butonuna tıklayın
2. **"New repository"** seçin

### 1.3 Repository Ayarları

**Repository bilgileri:**

- **Repository name:** `lambda-blog-project`
- **Description:** `AWS Lambda alert system with SQS and Slack integration - Go implementation`
- **Visibility:** 
  - ✅ **Public** (önerilir - blog yazısında link verebilirsiniz)
  - ❌ Private (sadece siz görürsünüz)

**⚠️ ÖNEMLİ:** Şunları **YAPMAYIN:**
- ❌ "Add a README file" - Zaten var
- ❌ "Add .gitignore" - Zaten var
- ❌ "Choose a license" - Zaten var

**Repository'yi boş oluşturun!**

3. **"Create repository"** butonuna tıklayın

### 1.4 Repository URL'ini Kopyalayın

Repository oluşturulduktan sonra şöyle bir sayfa göreceksiniz:

```
Quick setup — if you've done this kind of thing before
https://github.com/emregulustan/lambda-blog-project.git
```

Bu URL'yi kopyalayın! (Kullanıcı adınız farklı olabilir)

---

## Adım 2: Git Remote Ekleme ve Push

### 2.1 Remote URL'i Ayarlayın

**Repository URL'inizi buraya yazın:**

```bash
cd ~/Desktop/lambda-blog-project

# Repository URL'inizi buraya yazın (emregulustan kısmını kendi GitHub kullanıcı adınızla değiştirin)
REPO_URL="https://github.com/emregulustan/lambda-blog-project.git"

# Remote ekle
git remote add origin $REPO_URL

# Kontrol et
git remote -v
```

**Örnek çıktı:**
```
origin  https://github.com/emregulustan/lambda-blog-project.git (fetch)
origin  https://github.com/emregulustan/lambda-blog-project.git (push)
```

### 2.2 Push İşlemi

```bash
# Main branch'e push et
git push -u origin main
```

**İlk kez push ediyorsanız:**
- GitHub kullanıcı adı ve şifre sorabilir
- Veya Personal Access Token isteyebilir

**Personal Access Token oluşturmak için:**
1. GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic)
2. "Generate new token" > "Generate new token (classic)"
3. İsim: `lambda-blog-project`
4. Scopes: `repo` seçin
5. "Generate token" - Token'ı kopyalayın (bir daha gösterilmez!)
6. Push yaparken şifre yerine bu token'ı kullanın

### 2.3 Başarı Kontrolü

GitHub'da repository sayfanızı yenileyin. Tüm dosyalar görünmeli!

✅ **Başarılı!** Repository hazır!

---

## Adım 3: GitHub Secrets Ayarlama

GitHub Actions'ın çalışması için AWS bilgilerini Secrets olarak ekleyelim.

### 3.1 Secrets Sayfasına Gidin

1. GitHub repository sayfasında
2. **"Settings"** sekmesine tıklayın
3. Sol menüden **"Secrets and variables"** > **"Actions"** seçin
4. **"New repository secret"** butonuna tıklayın

### 3.2 Gerekli Secrets'ları Ekleyin

Şu secrets'ları tek tek ekleyin:

#### Secret 1: AWS_ACCESS_KEY_ID

- **Name:** `AWS_ACCESS_KEY_ID`
- **Secret:** `YOUR_AWS_ACCESS_KEY_ID` (AWS Console'dan alın)
- **"Add secret"** butonuna tıklayın

#### Secret 2: AWS_SECRET_ACCESS_KEY

- **Name:** `AWS_SECRET_ACCESS_KEY`
- **Secret:** `YOUR_AWS_SECRET_ACCESS_KEY` (AWS Console'dan alın)
- **"Add secret"** butonuna tıklayın

#### Secret 3: AWS_REGION

- **Name:** `AWS_REGION`
- **Secret:** `us-east-1`
- **"Add secret"** butonuna tıklayın

#### Secret 4: LAMBDA_FUNCTION_NAME

- **Name:** `LAMBDA_FUNCTION_NAME`
- **Secret:** `alert-lambda`
- **"Add secret"** butonuna tıklayın

#### Secret 5: LAMBDA_ROLE_ARN

- **Name:** `LAMBDA_ROLE_ARN`
- **Secret:** `arn:aws:iam::533420169013:role/lambda-execution-role`
- **"Add secret"** butonuna tıklayın

#### Secret 6: SQS_QUEUE_NAME

- **Name:** `SQS_QUEUE_NAME`
- **Secret:** `alert-queue`
- **"Add secret"** butonuna tıklayın

#### Secret 7: SLACK_WEBHOOK_URL

- **Name:** `SLACK_WEBHOOK_URL`
- **Secret:** `YOUR_SLACK_WEBHOOK_URL` (Slack API'den alın)
- **"Add secret"** butonuna tıklayın

**✅ Tüm secrets eklendi!**

---

## Adım 4: GitHub Actions Test

### 4.1 Actions Sekmesine Gidin

1. Repository sayfasında **"Actions"** sekmesine tıklayın
2. Sol menüden **"Deploy Lambda Function"** workflow'unu görmelisiniz

### 4.2 Workflow'u Tetikleme

**Yöntem 1: Manuel Tetikleme**

1. **"Actions"** sekmesine gidin
2. Sol menüden **"Deploy Lambda Function"** seçin
3. Sağ üstte **"Run workflow"** butonuna tıklayın
4. **"Run workflow"** butonuna tekrar tıklayın

**Yöntem 2: Kod Değişikliği ile Tetikleme**

Herhangi bir dosyada küçük bir değişiklik yapıp push edin:

```bash
cd ~/Desktop/lambda-blog-project

# README'ye bir satır ekle
echo "" >> README.md
echo "Last updated: $(date)" >> README.md

# Commit ve push
git add README.md
git commit -m "chore: Update README timestamp"
git push origin main
```

### 4.3 Workflow'u İzleme

1. **"Actions"** sekmesinde workflow çalışırken görebilirsiniz
2. Her adımı tıklayıp logları görüntüleyebilirsiniz:
   - ✅ Test adımı
   - ✅ Build adımı
   - ✅ Deploy adımı

**Beklenen süre:** 2-5 dakika

### 4.4 Başarı Kontrolü

✅ **Workflow başarılı olduğunda:**
- Yeşil tik işareti görürsünüz
- Lambda fonksiyonu otomatik güncellenir
- Deployment summary görünür

❌ **Hata durumunda:**
- Kırmızı X işareti görürsünüz
- Hata mesajını loglardan kontrol edin
- Secrets'ları doğrulayın

---

## ✅ TAMAMLANDI!

GitHub repository ve Actions kurulumu tamamlandı!

### Yapılanlar:

- [x] Git repository başlatıldı
- [x] İlk commit yapıldı
- [x] GitHub'da repository oluşturuldu
- [x] Kod push edildi
- [x] GitHub Secrets ayarlandı
- [x] GitHub Actions workflow test edildi

### Sonraki Adımlar:

1. **Workflow'u test edin** - Actions sekmesinden
2. **Blog yazısında repository linkini ekleyin**
3. **Terraform deploy test** - Sonraki adım

---

## 📝 NOTLAR

- **Repository URL'i:** `https://github.com/emregulustan/lambda-blog-project`
- **Blog yazısında kullanabilirsiniz:** Repository linkini blog yazısına ekleyin
- **Secrets güvenli:** Secrets GitHub'da şifrelenmiş saklanır, sadece Actions erişebilir

---

**Sorularınız varsa:** Hata mesajlarını paylaşın, birlikte çözelim! 🚀

