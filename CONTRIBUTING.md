# Katkıda Bulunma Rehberi

Bu projeye katkıda bulunduğunuz için teşekkür ederiz! Bu rehber, katkı sürecini kolaylaştırmak için hazırlanmıştır.

## Katkı Süreci

1. **Fork** edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## Commit Mesajları

Commit mesajlarınız için [Conventional Commits](https://www.conventionalcommits.org/) standardını kullanın:

- `feat:` Yeni özellik
- `fix:` Bug fix
- `docs:` Dokümantasyon
- `style:` Formatlama
- `refactor:` Refactoring
- `test:` Test ekleme/düzenleme
- `chore:` Bakım işleri

Örnek:
```
feat: Add email notifier implementation
fix: Handle timeout errors in Slack notifier
docs: Update README with new configuration options
```

## Kod Standartları

### Go

- `gofmt` ile formatlayın
- `go vet` ile kontrol edin
- `golangci-lint` kullanın (varsa)
- Test coverage %80'in üzerinde olmalı

```bash
# Format
go fmt ./...

# Vet
go vet ./...

# Lint
golangci-lint run ./...

# Test
go test -v -race -coverprofile=coverage.out ./...
```

### Terraform

- `terraform fmt` kullanın
- Variable'ları dokümante edin
- Output'ları açıklayın

```bash
terraform fmt -recursive
terraform validate
```

## Pull Request Gereksinimleri

Pull request'iniz şunları içermelidir:

- [ ] Açıklayıcı başlık ve açıklama
- [ ] İlgili issue'ya referans (varsa)
- [ ] Yeni kod için testler
- [ ] Gerekirse dokümantasyon güncellemesi
- [ ] Tüm testlerin başarılı olması
- [ ] Linting hatası olmaması

## Test Etme

Değişikliklerinizi test edin:

```bash
# Unit testler
./scripts/test.sh

# Build
./scripts/build.sh

# Local test (SAM CLI ile)
sam local invoke -e test-event.json
```

## Dokümantasyon

- README'yi güncel tutun
- Yeni özellikler için örnek kullanım ekleyin
- Code comment'leri ekleyin (özellikle karmaşık logic için)
- Blog yazısını güncelleyin (gerekirse)

## Code Review

Pull request'iniz şu kriterlere göre değerlendirilir:

1. **Functionality**: Kod çalışıyor mu?
2. **Tests**: Test coverage yeterli mi?
3. **Documentation**: Dokümantasyon güncel mi?
4. **Code Quality**: Kod okunabilir ve maintainable mı?
5. **Performance**: Performance etkileri düşünülmüş mü?

## Yeni Özellik Önerileri

Yeni özellik öneriniz varsa:

1. Önce bir **Issue** açın
2. Özelliği detaylı açıklayın
3. Use case'leri belirtin
4. Implementation yaklaşımını tartışın
5. Onay aldıktan sonra implement edin

## Bug Raporlama

Bug bulduysanız bir issue açın ve şunları ekleyin:

- Bug'ın detaylı açıklaması
- Reproduce etme adımları
- Beklenen davranış
- Gerçek davranış
- Environment bilgileri (Go version, OS, AWS region, vb.)
- Log çıktıları (varsa)

## İletişim

Sorularınız için:

- GitHub Issues
- Pull Request comments
- Email: [your-email@example.com]

## Lisans

Katkıda bulunarak, katkılarınızın MIT lisansı altında yayınlanmasını kabul etmiş olursunuz.

## Teşekkürler!

Katkılarınız bu projeyi daha iyi hale getiriyor. 🙏

