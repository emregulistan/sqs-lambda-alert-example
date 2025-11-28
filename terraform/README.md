# Terraform Infrastructure

Bu dizin Lambda fonksiyonunu ve ilgili AWS kaynaklarını Infrastructure as Code (IaC) yaklaşımıyla yönetmek için Terraform konfigürasyonlarını içerir.

## Kaynaklar

Bu Terraform konfigürasyonu şu AWS kaynaklarını oluşturur:

- **Lambda Function**: Alert işleme fonksiyonu
- **SQS Queue**: Alert mesajlarını alan kuyruk
- **SQS Dead Letter Queue**: Başarısız mesajlar için DLQ
- **IAM Role & Policy**: Lambda için gerekli izinler
- **CloudWatch Log Group**: Lambda logları
- **Lambda Event Source Mapping**: SQS'den Lambda'ya event akışı
- **CloudWatch Alarm**: Lambda error monitoring

## Kullanım

### 1. Terraform'u Yükleyin

```bash
# macOS
brew install terraform

# veya https://www.terraform.io/downloads adresinden indirin
```

### 2. Lambda Paketini Build Edin

```bash
cd ..
./scripts/build.sh
```

### 3. Terraform Variables'ı Ayarlayın

```bash
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars dosyasını düzenleyin
```

### 4. Terraform'u Başlatın

```bash
terraform init
```

### 5. Plan'ı İnceleyin

```bash
terraform plan
```

### 6. Kaynakları Oluşturun

```bash
terraform apply
```

### 7. Kaynakları Silin (gerekirse)

```bash
terraform destroy
```

## Environment Variables

Alternatif olarak, environment variables kullanabilirsiniz:

```bash
export TF_VAR_aws_region="us-east-1"
export TF_VAR_lambda_function_name="alert-lambda"
export TF_VAR_slack_webhook_url="https://hooks.slack.com/services/..."
```

## Outputs

Terraform apply sonrası şu bilgiler gösterilir:

- Lambda Function ARN
- Lambda Function Name
- SQS Queue URL
- SQS Queue ARN
- DLQ Queue URL
- Lambda IAM Role ARN
- CloudWatch Log Group Name

## Best Practices

1. **State Management**: Production'da Terraform state'i S3 backend'de saklayın
2. **Secrets Management**: Sensitive değerleri AWS Secrets Manager'da tutun
3. **Workspace'ler**: Farklı environment'lar için Terraform workspace'leri kullanın
4. **Tagging**: Tüm kaynakları uygun şekilde tag'leyin

## S3 Backend Örneği

Production kullanımı için `backend.tf` dosyası oluşturun:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "lambda-blog-project/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

