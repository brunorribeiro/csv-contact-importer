#!/bin/bash

set -e

echo "=== CSV Contact Importer - DigitalOcean Ubuntu 22.04 LTS Deploy ==="
echo ""

# Configuration
APP_NAME="csv-contact-importer"
APP_DIR="/var/www/$APP_NAME"
DOMAIN="${1:-localhost}"
EMAIL="${2:-admin@example.com}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Function to check Ubuntu version
check_ubuntu_version() {
    if ! grep -q "Ubuntu 22.04" /etc/os-release; then
        print_warning "This script is designed for Ubuntu 22.04 LTS. Your system may not be compatible."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_status "Ubuntu 22.04 LTS detected"
    fi
}

# Function to update system
update_system() {
    print_header "Updating System"
    sudo apt update && sudo apt upgrade -y
    print_status "System updated successfully"
}

# Function to install Docker
install_docker() {
    print_header "Installing Docker"
    
    if command -v docker &> /dev/null; then
        print_status "Docker already installed"
        return
    fi
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Clean up
    rm get-docker.sh
    
    print_status "Docker installed successfully"
    print_warning "Please log out and log back in for Docker group changes to take effect"
}

# Function to install Docker Compose
install_docker_compose() {
    print_header "Installing Docker Compose"
    
    if command -v docker-compose &> /dev/null; then
        print_status "Docker Compose already installed"
        return
    fi
    
    # Docker Compose is included with Docker Desktop, but we'll install it separately for server
    sudo apt install -y docker-compose-plugin
    
    print_status "Docker Compose installed successfully"
}

# Function to setup firewall
setup_firewall() {
    print_header "Setting up UFW Firewall"
    
    # Install and enable UFW
    sudo apt install -y ufw
    
    # Default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH
    sudo ufw allow ssh
    
    # Allow HTTP and HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Allow application port
    sudo ufw allow 8080/tcp
    
    # Enable firewall
    sudo ufw --force enable
    
    print_status "Firewall configured successfully"
}

# Function to create application directory
create_app_directory() {
    print_header "Creating Application Directory"
    
    sudo mkdir -p $APP_DIR
    sudo chown $USER:$USER $APP_DIR
    
    print_status "Application directory created at $APP_DIR"
}

# Function to copy application files
copy_application() {
    print_header "Copying Application Files"
    
    # Copy all files except git and temp files
    rsync -av --exclude='.git' --exclude='node_modules' --exclude='vendor' \
          --exclude='storage/logs/*' --exclude='storage/framework/cache/*' \
          --exclude='storage/framework/sessions/*' --exclude='storage/framework/views/*' \
          ./ $APP_DIR/
    
    # Set proper ownership
    sudo chown -R $USER:$USER $APP_DIR
    
    print_status "Application files copied successfully"
}

# Function to create production environment file
create_env_file() {
    print_header "Creating Production Environment File"
    
    cat > $APP_DIR/.env << EOF
APP_NAME="CSV Contact Importer"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://$DOMAIN:8080

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=csv_importer
DB_USERNAME=laravel
DB_PASSWORD=$(openssl rand -base64 32)

BROADCAST_DRIVER=log
CACHE_DRIVER=redis
FILESYSTEM_DISK=local
QUEUE_CONNECTION=database
SESSION_DRIVER=redis
SESSION_LIFETIME=120

REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="noreply@$DOMAIN"
MAIL_FROM_NAME="\${APP_NAME}"

VITE_APP_NAME="\${APP_NAME}"
EOF

    print_status "Production environment file created"
}

# Function to create production docker-compose file
create_production_compose() {
    print_header "Creating Production Docker Compose"
    
    cat > $APP_DIR/docker-compose.prod.yml << 'EOF'
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
      MYSQL_DATABASE: csv_importer
      MYSQL_USER: laravel
      MYSQL_PASSWORD_FILE: /run/secrets/mysql_password
      MYSQL_ROOT_HOST: '%'
    volumes:
      - mysql_data:/var/lib/mysql
      - ./docker/mysql-init:/docker-entrypoint-initdb.d
    networks:
      - app-network
    command: --default-authentication-plugin=mysql_native_password --bind-address=0.0.0.0
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
      interval: 10s
      start_period: 40s
    secrets:
      - mysql_root_password
      - mysql_password
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      timeout: 10s
      retries: 5
      interval: 10s
      start_period: 30s
    restart: unless-stopped

  app:
    build:
      context: .
      dockerfile: Dockerfile.prod
    ports:
      - "8080:80"
    environment:
      APP_NAME: "CSV Contact Importer"
      APP_ENV: production
      APP_DEBUG: "false"
      APP_URL: http://localhost:8080
      DB_CONNECTION: mysql
      DB_HOST: mysql
      DB_PORT: 3306
      DB_DATABASE: csv_importer
      DB_USERNAME: laravel
      QUEUE_CONNECTION: database
      CACHE_DRIVER: redis
      SESSION_DRIVER: redis
      REDIS_HOST: redis
      REDIS_PORT: 6379
      BROADCAST_DRIVER: log
      LOG_CHANNEL: stack
      LOG_LEVEL: error
    env_file:
      - .env
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - storage_data:/var/www/storage
      - ./storage/logs:/var/www/storage/logs
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      timeout: 10s
      retries: 5
      interval: 30s
      start_period: 60s

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./docker/nginx/sites:/etc/nginx/sites-available
      - ./docker/ssl:/etc/nginx/ssl
      - storage_data:/var/www/storage
    depends_on:
      - app
    networks:
      - app-network
    restart: unless-stopped

volumes:
  mysql_data:
  redis_data:
  storage_data:

networks:
  app-network:
    driver: bridge

secrets:
  mysql_root_password:
    file: ./secrets/mysql_root_password.txt
  mysql_password:
    file: ./secrets/mysql_password.txt
EOF

    print_status "Production Docker Compose file created"
}

# Function to create production Dockerfile
create_production_dockerfile() {
    print_header "Creating Production Dockerfile"
    
    cat > $APP_DIR/Dockerfile.prod << 'EOF'
FROM php:8.1-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    oniguruma-dev \
    libxml2-dev \
    zip \
    unzip \
    nodejs \
    npm \
    supervisor \
    mysql-client \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy composer files first for better caching
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --optimize-autoloader

# Copy package.json for npm caching
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Complete composer installation
RUN composer dump-autoload --optimize

# Build frontend assets
RUN npm run build && npm cache clean --force

# Create required directories and set permissions
RUN mkdir -p storage/logs \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/app/csv_imports \
    bootstrap/cache \
    && chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

# Copy supervisor configuration
COPY docker/supervisord.prod.conf /etc/supervisor/conf.d/supervisord.conf

# Copy entrypoint script
COPY docker/entrypoint.prod.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD php artisan tinker --execute="echo 'OK';" || exit 1

# Start supervisor
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
EOF

    print_status "Production Dockerfile created"
}

# Function to create secrets
create_secrets() {
    print_header "Creating Database Secrets"
    
    mkdir -p $APP_DIR/secrets
    
    # Generate secure passwords
    openssl rand -base64 32 > $APP_DIR/secrets/mysql_root_password.txt
    openssl rand -base64 32 > $APP_DIR/secrets/mysql_password.txt
    
    # Set proper permissions
    chmod 600 $APP_DIR/secrets/*.txt
    
    print_status "Database secrets created"
}

# Function to create nginx configuration
create_nginx_config() {
    print_header "Creating Nginx Configuration"
    
    mkdir -p $APP_DIR/docker/nginx/sites
    
    cat > $APP_DIR/docker/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    client_max_body_size 50M;
    
    gzip on;
    gzip_vary on;
    gzip_min_length 10240;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/x-javascript
        application/xml+rss
        application/javascript
        application/json;
    
    include /etc/nginx/sites-available/*;
}
EOF

    cat > $APP_DIR/docker/nginx/sites/default << EOF
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/public;
    index index.php;

    client_max_body_size 50M;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass app:9000;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    location /storage {
        alias /var/www/storage/app/public;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

    print_status "Nginx configuration created"
}

# Function to deploy application
deploy_application() {
    print_header "Deploying Application"
    
    cd $APP_DIR
    
    # Build and start services
    docker compose -f docker-compose.prod.yml build --no-cache
    docker compose -f docker-compose.prod.yml up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to start..."
    sleep 30
    
    # Generate application key
    docker compose -f docker-compose.prod.yml exec -T app php artisan key:generate --force
    
    # Run migrations
    docker compose -f docker-compose.prod.yml exec -T app php artisan migrate --force
    
    # Clear and cache config
    docker compose -f docker-compose.prod.yml exec -T app php artisan config:cache
    docker compose -f docker-compose.prod.yml exec -T app php artisan route:cache
    docker compose -f docker-compose.prod.yml exec -T app php artisan view:cache
    
    print_status "Application deployed successfully"
}

# Function to show final information
show_final_info() {
    print_header "Deployment Complete"
    
    echo ""
    print_status "CSV Contact Importer has been successfully deployed!"
    echo ""
    echo "Application URL: http://$DOMAIN:8080"
    echo "Application Directory: $APP_DIR"
    echo ""
    echo "Useful Commands:"
    echo "  View logs: cd $APP_DIR && docker compose -f docker-compose.prod.yml logs -f app"
    echo "  Restart app: cd $APP_DIR && docker compose -f docker-compose.prod.yml restart app"
    echo "  Stop services: cd $APP_DIR && docker compose -f docker-compose.prod.yml down"
    echo "  Update app: cd $APP_DIR && docker compose -f docker-compose.prod.yml up -d --build"
    echo ""
    print_warning "Make sure to:"
    echo "  1. Point your domain to this server's IP address"
    echo "  2. Configure SSL certificate for production use"
    echo "  3. Set up regular backups for the database"
    echo "  4. Monitor application logs regularly"
    echo ""
}

# Main execution
main() {
    print_header "Starting DigitalOcean Deployment"
    
    # Pre-flight checks
    check_root
    check_ubuntu_version
    
    # System setup
    update_system
    install_docker
    install_docker_compose
    setup_firewall
    
    # Application setup
    create_app_directory
    copy_application
    create_env_file
    create_production_compose
    create_production_dockerfile
    create_secrets
    create_nginx_config
    
    # Deploy
    deploy_application
    
    # Final information
    show_final_info
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
