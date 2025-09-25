# DigitalOcean Ubuntu 22.04 LTS Deployment Guide

## Prerequisites

### DigitalOcean Droplet Requirements
- **OS**: Ubuntu 22.04 LTS
- **RAM**: Minimum 2GB (4GB recommended)
- **Storage**: Minimum 25GB SSD
- **CPU**: 1 vCPU (2 vCPUs recommended)

### Domain Setup (Optional)
- Point your domain A record to the droplet's IP address
- Example: `csv-importer.yourdomain.com -> YOUR_DROPLET_IP`

## Quick Deployment (Automated)

### Step 1: Create DigitalOcean Droplet
1. Log into DigitalOcean
2. Create new Droplet with Ubuntu 22.04 LTS
3. Choose appropriate size (minimum $12/month droplet)
4. Add your SSH key
5. Create droplet and note the IP address

### Step 2: Connect to Server
```bash
# Replace YOUR_DROPLET_IP with actual IP
ssh root@YOUR_DROPLET_IP

# Create non-root user (recommended)
adduser deployer
usermod -aG sudo deployer
su - deployer
```

### Step 3: Upload Project Files
```bash
# On your local machine, upload the project
scp -r csv-contact-importer/ deployer@YOUR_DROPLET_IP:~/

# Or clone from repository
git clone YOUR_REPOSITORY_URL csv-contact-importer
cd csv-contact-importer
```

### Step 4: Run Automated Deployment
```bash
# Make script executable and run
chmod +x deploy-digitalocean.sh

# Deploy with domain (optional)
./deploy-digitalocean.sh yourdomain.com your-email@domain.com

# Or deploy with localhost
./deploy-digitalocean.sh
```

### Step 5: Access Application
- Open browser to `http://YOUR_DROPLET_IP:8080`
- Or `http://yourdomain.com:8080` if using custom domain

## Manual Deployment (Step by Step)

### 1. System Preparation
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl git unzip
```

### 2. Install Docker
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Log out and back in for group changes
exit
# SSH back in
```

### 3. Setup Firewall
```bash
# Configure UFW firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
sudo ufw --force enable
```

### 4. Prepare Application
```bash
# Create application directory
sudo mkdir -p /var/www/csv-contact-importer
sudo chown $USER:$USER /var/www/csv-contact-importer

# Copy application files
cp -r ~/csv-contact-importer/* /var/www/csv-contact-importer/
cd /var/www/csv-contact-importer
```

### 5. Configure Environment
```bash
# Create production environment file
cp .env.example .env

# Edit environment variables
nano .env
```

Required environment variables:
```env
APP_NAME="CSV Contact Importer"
APP_ENV=production
APP_DEBUG=false
APP_URL=http://YOUR_DOMAIN:8080

DB_CONNECTION=mysql
DB_HOST=mysql
DB_DATABASE=csv_importer
DB_USERNAME=laravel
DB_PASSWORD=your_secure_password

QUEUE_CONNECTION=database
CACHE_DRIVER=redis
SESSION_DRIVER=redis
REDIS_HOST=redis
```

### 6. Deploy Application
```bash
# Build and start services
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d

# Wait for services to start (2-3 minutes)
docker compose -f docker-compose.prod.yml logs -f app

# Generate application key
docker compose -f docker-compose.prod.yml exec app php artisan key:generate --force

# Run migrations
docker compose -f docker-compose.prod.yml exec app php artisan migrate --force
```

## Production Configuration

### SSL Certificate Setup (Recommended)
```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d yourdomain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Backup Configuration
```bash
# Create backup script
cat > /home/deployer/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/deployer/backups"
mkdir -p $BACKUP_DIR

# Database backup
docker compose -f /var/www/csv-contact-importer/docker-compose.prod.yml exec -T mysql mysqldump -u root -p$(cat /var/www/csv-contact-importer/secrets/mysql_root_password.txt) csv_importer > $BACKUP_DIR/database_$DATE.sql

# Application files backup
tar -czf $BACKUP_DIR/app_$DATE.tar.gz -C /var/www csv-contact-importer

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /home/deployer/backup.sh

# Schedule daily backups
crontab -e
# Add: 0 2 * * * /home/deployer/backup.sh
```

### Monitoring Setup
```bash
# Install monitoring tools
sudo apt install -y htop iotop nethogs

# Check application status
docker compose -f /var/www/csv-contact-importer/docker-compose.prod.yml ps

# View logs
docker compose -f /var/www/csv-contact-importer/docker-compose.prod.yml logs -f app
```

## Maintenance Commands

### Application Management
```bash
cd /var/www/csv-contact-importer

# View service status
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs -f app

# Restart application
docker compose -f docker-compose.prod.yml restart app

# Update application
git pull origin main
docker compose -f docker-compose.prod.yml up -d --build

# Stop services
docker compose -f docker-compose.prod.yml down

# Start services
docker compose -f docker-compose.prod.yml up -d
```

### Database Management
```bash
# Access database
docker compose -f docker-compose.prod.yml exec mysql mysql -u laravel -p csv_importer

# Run migrations
docker compose -f docker-compose.prod.yml exec app php artisan migrate

# Clear cache
docker compose -f docker-compose.prod.yml exec app php artisan cache:clear
```

### Performance Optimization
```bash
# Optimize Laravel
docker compose -f docker-compose.prod.yml exec app php artisan config:cache
docker compose -f docker-compose.prod.yml exec app php artisan route:cache
docker compose -f docker-compose.prod.yml exec app php artisan view:cache

# Clean Docker
docker system prune -f
docker image prune -f
```

## Troubleshooting

### Common Issues

#### Application not accessible
```bash
# Check if services are running
docker compose -f docker-compose.prod.yml ps

# Check firewall
sudo ufw status

# Check logs
docker compose -f docker-compose.prod.yml logs app
```

#### Database connection errors
```bash
# Check MySQL status
docker compose -f docker-compose.prod.yml logs mysql

# Restart MySQL
docker compose -f docker-compose.prod.yml restart mysql

# Check database credentials in .env file
```

#### High memory usage
```bash
# Check memory usage
free -h
docker stats

# Restart services to free memory
docker compose -f docker-compose.prod.yml restart
```

#### Queue jobs not processing
```bash
# Check worker logs
docker compose -f docker-compose.prod.yml logs app | grep worker

# Restart workers
docker compose -f docker-compose.prod.yml restart app
```

### Log Locations
- Application logs: `/var/www/csv-contact-importer/storage/logs/`
- Docker logs: `docker compose logs [service]`
- System logs: `/var/log/`
- Nginx logs: `/var/log/nginx/`

### Performance Monitoring
```bash
# System resources
htop

# Disk usage
df -h

# Docker container stats
docker stats

# Network connections
netstat -tulpn | grep :8080
```

## Security Considerations

### Server Hardening
```bash
# Disable root SSH login
sudo nano /etc/ssh/sshd_config
# Set: PermitRootLogin no

# Change SSH port (optional)
# Set: Port 2222

# Restart SSH
sudo systemctl restart ssh

# Install fail2ban
sudo apt install -y fail2ban
```

### Application Security
- Keep Docker images updated
- Regular security updates: `sudo apt update && sudo apt upgrade`
- Monitor application logs for suspicious activity
- Use strong database passwords
- Enable SSL/TLS certificates
- Regular backups

### Firewall Rules
```bash
# View current rules
sudo ufw status verbose

# Allow specific IPs only (optional)
sudo ufw allow from YOUR_IP_ADDRESS to any port 22

# Block specific IPs
sudo ufw deny from SUSPICIOUS_IP_ADDRESS
```

## Scaling Considerations

### Vertical Scaling (Upgrade Droplet)
1. Power off droplet
2. Resize in DigitalOcean panel
3. Power on droplet
4. No configuration changes needed

### Horizontal Scaling (Multiple Servers)
- Use DigitalOcean Load Balancer
- Separate database server (DigitalOcean Managed Database)
- Redis cluster for caching
- CDN for static assets

### Database Optimization
```bash
# For high traffic, consider:
# - DigitalOcean Managed MySQL
# - Read replicas
# - Connection pooling
# - Database indexing optimization
```

This guide provides comprehensive instructions for deploying the CSV Contact Importer on DigitalOcean Ubuntu 22.04 LTS with production-ready configuration.
