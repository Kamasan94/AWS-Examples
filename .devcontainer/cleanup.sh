#!/usr/bin/env bash
set -e

echo "🧹 Cleaning up AWS environment..."

cd $(dirname $0)

terraform destroy -auto-approve || true

echo "✅ AWS environment destroyed."