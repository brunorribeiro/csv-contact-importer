#!/bin/bash
set -e

echo "=== CSV Contact Importer Starting ==="

# Function to wait for database
wait_for_db() {
    echo "Waiting for database connection..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if php artisan migrate:status > /dev/null 2>&1; then
            echo "Database connection established!"
            return 0
        fi
        
        echo "Database not ready (attempt $attempt/$max_attempts), waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: Database connection failed after $max_attempts attempts"
    exit 1
}

# Wait for database
wait_for_db

# Set proper permissions (Windows Docker Desktop fix)
echo "Setting file permissions..."
chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
chmod -R 755 /var/www/storage /var/www/bootstrap/cache

# Generate app key if not exists
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:YWJjZGVmZ2hpams=" ]; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# Run migrations
echo "Running database migrations..."
php artisan migrate --force

# Clear any existing cache
echo "Clearing cache..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

# Cache configuration for production
echo "Optimizing application..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Create storage link if it doesn't exist
if [ ! -L /var/www/public/storage ]; then
    echo "Creating storage link..."
    php artisan storage:link
fi

# Ensure nginx can write to its directories
mkdir -p /var/log/nginx /var/lib/nginx/body /var/lib/nginx/fastcgi
chown -R www-data:www-data /var/log/nginx /var/lib/nginx

# Test nginx configuration
echo "Testing nginx configuration..."
nginx -t

echo "=== Starting services ==="
echo "Application will be available at http://localhost:8080"

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
