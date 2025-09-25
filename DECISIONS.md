# Technical Decisions

## Architecture Choices

**Fat Model, Thin Controller**: Business logic moved to Service layer and Model methods for better testability and reusability.

**Jobs & Queues**: Asynchronous processing prevents UI blocking and enables scalability for large files (50MB+).

**Real-time Progress**: WebSocket broadcasting provides immediate user feedback during long-running operations.

## Technology Stack

**Laravel 10**: Mature framework with excellent queue system and broadcasting capabilities.

**Vue.js 3**: Reactive UI for real-time progress updates and modern component architecture.

**Material Design**: Industry-standard design system ensuring professional UX and accessibility.

**MySQL + Redis**: Reliable persistence with fast caching for session data and queue management.

## Implementation Details

**Phone Validation**: `propaganistas/laravel-phone` package ensures international US format compliance.

**Progress Tracking**: Cache-based with 250ms polling for responsive updates without overwhelming the server.

**Error Handling**: Comprehensive validation with user-friendly messages and automatic retry mechanisms.

**File Processing**: Row-by-row CSV parsing with memory-efficient streaming for large datasets.

**Docker**: Multi-service containerization with nginx, PHP-FPM, and queue workers for production deployment.

## Performance Optimizations

**Chunked Updates**: Progress reported every 5 rows to balance responsiveness with performance.

**Database Indexing**: Email column indexed for efficient duplicate detection.

**Asset Optimization**: Vite build system with code splitting and minification.

**Queue Workers**: Multiple workers enable parallel processing of concurrent uploads.

**Caching Strategy**: Redis for session storage and Laravel's config/route/view caching in production.

