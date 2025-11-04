#!/usr/bin/env bash
set -e

echo "🚀 Creating AWS test environment..."

cd $(dirname $0)

# Inizializza Terraform
terraform init

# Crea l'ambiente (puoi definire EC2, S3, ecc.)
terraform apply -auto-approve

echo "✅ Environment ready!"

