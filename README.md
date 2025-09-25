# CSV Contact Importer

Modern Laravel application for importing CSV contacts with real-time progress tracking and Material Design interface.

## Features

- **Asynchronous Processing**: Background jobs with queue system
- **Real-time Progress**: Live updates during CSV processing  
- **Material Design UI**: Modern interface with drag & drop upload
- **US Phone Validation**: Automatic formatting to international standard
- **Scalable Architecture**: Handles files up to 50MB efficiently

## Quick Start with Docker

### Windows Docker Desktop (Recommended)
```cmd
# Double-click start-windows.bat
# OR run in Command Prompt:
start-windows.bat
```

### Linux/macOS or Manual Setup
```bash
# Clone and start
git clone <repository>
cd csv-contact-importer
docker compose up -d

# Access application
open http://localhost:8080
```

### Windows WSL Troubleshooting
```bash
# If issues occur, run the fix script:
./docker-windows-fix.sh
```

## Manual Installation

### Requirements
- PHP 8.1+
- MySQL 8.0+
- Redis (optional)
- Node.js 16+

### Setup
```bash
# Install dependencies
composer install
npm install && npm run build

# Configure environment
cp .env.example .env
php artisan key:generate

# Database setup
php artisan migrate

# Start queue worker (required for async processing)
php artisan queue:work

# Start development server
php artisan serve
```

## Configuration

### Environment Variables
```env
# Database
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_DATABASE=csv_importer
DB_USERNAME=root
DB_PASSWORD=

# Queue (required for async processing)
QUEUE_CONNECTION=database

# Cache (optional, improves performance)
CACHE_DRIVER=redis
REDIS_HOST=127.0.0.1
```

### Production Setup
```bash
# Optimize for production
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Queue workers (use supervisor)
php artisan queue:work --sleep=3 --tries=3 --max-time=3600
```

## Usage

1. **Upload CSV**: Drag & drop or select file (max 50MB)
2. **Monitor Progress**: Real-time updates with statistics
3. **View Results**: Detailed import summary with error reporting
4. **Browse Contacts**: Navigate to contacts list

### CSV Format
```csv
name,email,phone,birthdate
John Smith,john@email.com,(555) 123-4567,1990-01-15
Mary Johnson,mary@email.com,555-987-6543,1985-05-20
```

**Required**: name, email  
**Optional**: phone (US format), birthdate

## API Endpoints

- `POST /api/contacts/upload` - Upload CSV file
- `GET /api/upload/progress?session_id={id}` - Get progress
- `GET /api/contacts` - List contacts

## Architecture

- **Controller**: Thin layer handling HTTP requests
- **Job**: Asynchronous CSV processing (`ProcessCsvImportJob`)
- **Service**: Business logic (`ContactImportService`)
- **Model**: Data layer with phone formatting
- **Events**: Real-time progress broadcasting

## Troubleshooting

**Queue not processing?**
```bash
php artisan queue:work
```

**Progress not updating?**
- Check queue worker is running
- Verify session_id in requests

**File upload fails?**
- Check file size (max 50MB)
- Verify file format (CSV/TXT)
- Check disk space

## License

MIT License
