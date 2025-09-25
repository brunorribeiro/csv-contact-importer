#!/bin/bash

echo "=== Production Configuration Validation ==="
echo ""

# Check required files
echo "Checking required files..."
required_files=(
    "Dockerfile.prod"
    "docker-compose.prod.yml"
    "docker/supervisord.prod.conf"
    "docker/entrypoint.prod.sh"
    "docker/nginx/nginx.conf"
    "docker/nginx/sites/default"
    "composer.lock"
    ".env.production"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
        exit 1
    fi
done

echo ""
echo "Validating Docker configuration..."
if docker compose -f docker-compose.prod.yml config > /dev/null 2>&1; then
    echo "✓ docker-compose.prod.yml is valid"
else
    echo "✗ docker-compose.prod.yml has errors"
    exit 1
fi

echo ""
echo "Checking composer.lock..."
if composer validate --no-check-all --strict; then
    echo "✓ composer.lock is valid and up to date"
else
    echo "✗ composer.lock needs updating"
    exit 1
fi

echo ""
echo "All production configuration checks passed!"
echo "Ready for DigitalOcean deployment."
