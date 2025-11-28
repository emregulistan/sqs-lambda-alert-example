# 📸 Blog Yazısı Hazırlığı - Ekran Görüntüleri Rehberi

Slack entegrasyonu tamamlandı! Şimdi blog yazınız için gerekli ekran görüntülerini alalım.

---

## 🎯 ŞU AN DURUM

✅ Lambda fonksiyonu çalışıyor  
✅ SQS queue aktif  
✅ Slack entegrasyonu tamamlandı  
✅ Test mesajları başarılı  

**Sonraki adım:** Blog yazısı için ekran görüntüleri alma

---

## 📋 ALINACAK EKRAN GÖRÜNTÜLERİ LİSTESİ

### 1. Lambda Fonksiyon Sayfası (Genel Görünüm)

**Neden önemli:** Blog yazısında Lambda'nın nasıl göründüğünü göstermek için.

**Adımlar:**
1. AWS Console'a gidin: https://console.aws.amazon.com
2. Üst arama: **"Lambda"** yazın
3. **"Lambda"** servisine tıklayın
4. **"Functions"** (Fonksiyonlar) seçin
5. **`alert-lambda`** fonksiyonuna tıklayın

**Ekran görüntüsü alınacak:**
- Code, Configuration, Test, Monitoring sekmeleri görünür olmalı
- Function name: `alert-lambda`
- Runtime: `provided.al2023`
- Architecture: `arm64`

**[SCREENSHOT-1: Lambda fonksiyon genel görünüm]**

---

### 2. Lambda Configuration - Environment Variables

**Neden önemli:** Blog yazısında environment variables'ın nasıl ayarlandığını göstermek için.

**Adımlar:**
1. Lambda sayfasında **"Configuration"** sekmesine tıklayın
2. Sol menüden **"Environment variables"** seçin

**Ekran görüntüsü alınacak:**
- `SLACK_WEBHOOK_URL` variable'ı görünür olmalı
- Değer gizli gösterilmeli (***) ama var olduğu belli olmalı

**[SCREENSHOT-2: Lambda environment variables]**

---

### 3. Lambda Configuration - Permissions (IAM Role)

**Neden önemli:** Blog yazısında IAM role'ün önemini göstermek için.

**Adımlar:**
1. Lambda sayfasında **"Configuration"** sekmesinde
2. Sol menüden **"Permissions"** seçin

**Ekran görüntüsü alınacak:**
- Execution role: `lambda-execution-role`
- Role ARN görünür olmalı

**[SCREENSHOT-3: Lambda permissions/IAM role]**

---

### 4. Lambda Triggers (Event Source Mapping)

**Neden önemli:** Blog yazısında SQS trigger'ın nasıl eklendiğini göstermek için.

**Adımlar:**
1. Lambda sayfasında **"Configuration"** sekmesinde
2. Sol menüden **"Triggers"** (veya "Event source mappings") seçin

**Ekran görüntüsü alınacak:**
- SQS trigger görünür olmalı
- Event source: `alert-queue`
- Batch size: `10`
- State: `Enabled`

**[SCREENSHOT-4: Lambda triggers/SQS event source mapping]**

---

### 5. Lambda Monitoring Dashboard

**Neden önemli:** Blog yazısında monitoring'in önemini göstermek için.

**Adımlar:**
1. Lambda sayfasında **"Monitoring"** sekmesine tıklayın

**Ekran görüntüsü alınacak:**
- Invocations grafiği
- Duration grafiği
- Errors grafiği (varsa)
- Throttles grafiği

**[SCREENSHOT-5: Lambda monitoring dashboard]**

---

### 6. SQS Queue Sayfası

**Neden önemli:** Blog yazısında SQS queue'nun nasıl göründüğünü göstermek için.

**Adımlar:**
1. AWS Console'da üst arama: **"SQS"** yazın
2. **"Simple Queue Service"** servisine tıklayın
3. **`alert-queue`** kuyruğuna tıklayın

**Ekran görüntüsü alınacak:**
- Queue name: `alert-queue`
- Queue URL görünür
- Queue ARN görünür
- Monitoring tab'ında mesaj istatistikleri

**[SCREENSHOT-6: SQS queue sayfası]**

---

### 7. CloudWatch Logs - Lambda Çıktıları

**Neden önemli:** Blog yazısında logların nasıl göründüğünü göstermek için.

**Adımlar:**
1. AWS Console'da üst arama: **"CloudWatch"** yazın
2. **"CloudWatch"** servisine tıklayın
3. Sol menüden **"Log groups"** seçin
4. **`/aws/lambda/alert-lambda`** log group'una tıklayın
5. En son **log stream**'i açın (en üstteki)

**Ekran görüntüsü alınacak:**
- Lambda çıktıları görünür
- "Received X SQS messages" logları
- "Parsed alert" logları
- "Successfully sent alert to Slack" logları

**Öneri:** Önce bir test mesajı gönderin, sonra log'ları açın:

```bash
aws sqs send-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/533420169013/alert-queue \
  --message-body '{
    "level": "info",
    "service": "test",
    "message": "Blog yazısı için log örneği",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }'
```

Sonra log'ları açın ve 5-10 saniye bekleyin, yeni log'lar görünecek.

**[SCREENSHOT-7: CloudWatch Logs - Lambda çıktıları]**

---

### 8. Slack Alert Mesajları (En Önemli!)

**Neden önemli:** Blog yazısının en etkileyici kısmı - gerçek çalışan sistemin çıktısı!

**Adımlar:**
1. Slack workspace'inizde webhook'u eklediğiniz kanalı açın
2. Farklı seviyelerde mesajlar gönderin (yukarıda gönderdik)

**Ekran görüntüsü alınacak:**
- **Örnek 1:** Info seviyesi alert (yeşil)
- **Örnek 2:** Warning seviyesi alert (turuncu)
- **Örnek 3:** Error seviyesi alert (kırmızı)
- **Örnek 4:** Critical seviyesi alert (mor)

**Öneri:** 4 farklı seviyeyi tek bir ekran görüntüsünde göstermek için:
1. Önce 4 mesaj gönderin (yukarıda gönderdik, zaten Slack'te olmalı)
2. Slack'te scroll yaparak 4 mesajı da görünür hale getirin
3. Tek bir ekran görüntüsü alın

**Veya:** Her seviye için ayrı ayrı alın ve blog yazısında karşılaştırmalı gösterin.

**[SCREENSHOT-8: Slack alert mesajları - tüm seviyeler]**

---

### 9. AWS Console - Lambda Oluşturma (Opsiyonel)

**Neden önemli:** Blog yazısında Lambda'nın nasıl oluşturulduğunu gösteriyorsanız.

**Adımlar:**
1. Lambda Console > **"Create function"** butonuna tıklayın
2. **"Author from scratch"** seçin
3. Formu doldurun (görsel için, oluşturmayın!)

**Ekran görüntüsü alınacak:**
- Function name field
- Runtime dropdown: "Provide your own bootstrap on Amazon Linux 2023"
- Architecture: arm64 seçili

**Not:** Eğer Lambda'yı zaten oluşturduysanız, bu adımı atlayabilirsiniz. Veya blog yazısında bu kısmı text olarak açıklayabilirsiniz.

---

### 10. SQS Queue Oluşturma (Opsiyonel)

**Neden önemli:** Blog yazısında SQS queue'nun nasıl oluşturulduğunu gösteriyorsanız.

**Adımlar:**
1. SQS Console > **"Create queue"** butonuna tıklayın
2. Formu gösterin (görsel için, oluşturmayın!)

**Not:** Eğer queue'yu zaten oluşturduysanız, bu adımı atlayabilirsiniz.

---

## 📸 EKRAN GÖRÜNTÜSÜ ALMA İPUÇLARI

### macOS'te Ekran Görüntüsü Alma

**Tüm ekran:**
- `Command + Shift + 3`

**Seçilen alan:**
- `Command + Shift + 4` (fare ile alan seçin)

**Pencere:**
- `Command + Shift + 4` + `Space` tuşu (sonra pencereye tıklayın)

**Ekran görüntüleri nereye kaydedilir:**
- Masaüstüne kaydedilir: `Screenshot 2025-11-28 at 14.30.15.png`

### Düzenleme Önerileri

1. **Önemli kısımları vurgulayın:**
   - Kırmızı ok ile işaretleyin
   - Kutu içine alın
   - Renkli daire içine alın

2. **Açıklayıcı metinler ekleyin:**
   - "Function Name: alert-lambda"
   - "Environment Variable: SLACK_WEBHOOK_URL"
   - "SQS Trigger: alert-queue"

3. **Gereksiz kısımları kesin:**
   - Browser bar'ı kaldırın
   - Sol menüyü kaldırın (gerekiyorsa)
   - Sadece önemli kısımları gösterin

4. **Tutarlı stil:**
   - Tüm ekran görüntülerinde aynı stili kullanın
   - Aynı font ve renkleri kullanın
   - Aynı açıklama formatını kullanın

### Kullanabileceğiniz Araçlar

**Basit düzenleme (macOS):**
- **Preview** (macOS'ta varsayılan)
  - Tools > Annotate ile ok/metin ekleyebilirsiniz

**Online düzenleme:**
- **Canva:** [canva.com](https://canva.com) - Ücretsiz, online
- **Photopea:** [photopea.com](https://photopea.com) - Photoshop benzeri, ücretsiz

**GIF kaydı (animasyonlu gösterimler için):**
- **Kap:** [getkap.co](https://getkap.co) - Ücretsiz, macOS için

---

## 🎬 ANİMASYONLU GİF'LER (Opsiyonel ama Etkili)

Blog yazısında bazı adımları GIF ile göstermek çok etkili olur!

### Önerilen GIF'ler

1. **Lambda oluşturma süreci:**
   - Create function butonuna tıklama
   - Form doldurma
   - Create butonuna tıklama

2. **SQS trigger ekleme:**
   - Add trigger butonuna tıklama
   - SQS seçimi
   - Queue seçimi
   - Add butonuna tıklama

3. **Test mesajı gönderme:**
   - Terminal'de komut çalıştırma
   - Slack'te mesajın gelmesi

### GIF Kaydı İçin

**Kap kullanarak:**
1. [getkap.co](https://getkap.co) adresinden Kap'ı indirin
2. Kurun ve açın
3. Kayıt alanını seçin
4. Adımları uygulayın
5. GIF olarak kaydedin

---

## ✅ KONTROL LİSTESİ

Tüm ekran görüntülerini aldınız mı?

- [ ] Lambda fonksiyon genel görünüm
- [ ] Lambda environment variables
- [ ] Lambda permissions/IAM role
- [ ] Lambda triggers/SQS event source mapping
- [ ] Lambda monitoring dashboard
- [ ] SQS queue sayfası
- [ ] CloudWatch Logs - Lambda çıktıları
- [ ] Slack alert mesajları (4 farklı seviye)
- [ ] (Opsiyonel) Lambda oluşturma ekranı
- [ ] (Opsiyonel) SQS queue oluşturma ekranı
- [ ] (Opsiyonel) GIF'ler

---

## 📝 EKRAN GÖRÜNTÜLERİNİ DÜZENLEME

### Örnek Düzenleme Adımları

1. **Ekran görüntüsünü açın:**
   ```bash
   open ~/Desktop/Screenshot*.png
   ```

2. **Preview ile düzenleyin:**
   - Tools > Annotate
   - Ok ekleyin
   - Metin ekleyin
   - Kutu çizin

3. **Kaydedin:**
   - Yeni isimle kaydedin: `lambda-function-page.png`

### Dosya İsimlendirme Önerileri

```
lambda-function-overview.png
lambda-environment-variables.png
lambda-permissions.png
lambda-triggers.png
lambda-monitoring.png
sqs-queue-page.png
cloudwatch-logs.png
slack-alerts-all-levels.png
slack-alert-info.png
slack-alert-error.png
```

---

## 🚀 SONRAKİ ADIM: BLOG YAZISINA EKLEME

Ekran görüntülerini aldıktan sonra:

1. **`blog-yazisi.md` dosyasını açın:**
   ```bash
   open ~/Desktop/lambda-blog-project/blog-yazisi.md
   ```

2. **Placeholder'ları bulun:**
   - `[SCREENSHOT-1: ...]`
   - `[SCREENSHOT-2: ...]`
   - `[GIF-1: ...]`

3. **Placeholder'ları gerçek görsellerle değiştirin:**
   - Medium'da görsel eklemek için drag & drop yapabilirsiniz
   - Veya `+` butonuna tıklayıp görsel ekleyebilirsiniz

4. **Her görselin altına açıklama ekleyin:**
   - "Lambda fonksiyon sayfası - genel görünüm"
   - "Slack'te gelen alert mesajları"

---

## 📚 İYİ BLOG YAZISI İÇİN İPUÇLARI

1. **Başlık çekici olsun:**
   - "İlk Lambda Fonksiyonunuzu Oluşturun ve Deploy Edin"
   - ✅ İyi başlık!

2. **Görseller bol olsun:**
   - Her adımda görsel olsun
   - Kod + ekran görüntüsü kombinasyonu

3. **Kod blokları düzgün olsun:**
   - Syntax highlighting kullanın
   - Açıklayıcı yorumlar ekleyin

4. **Pratik örnekler olsun:**
   - Gerçek use case'ler
   - Test senaryoları

5. **Sonuç net olsun:**
   - Ne öğrendik?
   - Nerede kullanılır?
   - Sonraki adımlar neler?

---

## 🎉 HAZIRSINIZ!

Ekran görüntülerini aldıktan sonra blog yazınızı yayınlayabilirsiniz!

**Sıradaki adımlar:**
1. ✅ Ekran görüntülerini alın (bu rehberden)
2. ✅ Blog yazısına ekleyin
3. ✅ Medium'da yayınlayın
4. ✅ Paylaşın! 🚀

**Sorularınız varsa:** Her zaman sorabilirsiniz!

