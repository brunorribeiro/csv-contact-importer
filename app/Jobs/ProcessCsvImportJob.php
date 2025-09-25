<?php

namespace App\Jobs;

use App\Services\ContactImportService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class ProcessCsvImportJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $timeout = 300; // 5 minutes timeout
    public $tries = 3;

    protected string $filePath;
    protected string $sessionId;

    /**
     * Create a new job instance.
     */
    public function __construct(string $filePath, string $sessionId)
    {
        $this->filePath = $filePath;
        $this->sessionId = $sessionId;
    }

    /**
     * Execute the job.
     */
    public function handle(ContactImportService $importService): void
    {
        try {
            // Update progress to processing
            $this->updateProgress([
                'percentage' => 0,
                'current_row' => 0,
                'total_rows' => 0,
                'status' => 'processing',
                'message' => 'Starting CSV processing...',
                'file_name' => basename($this->filePath)
            ]);

            // Process the CSV file
            $results = $importService->importFromCsv($this->filePath, $this->sessionId);

            // Update progress to completed
            $this->updateProgress([
                'percentage' => 100,
                'current_row' => $results['total_rows'] ?? 0,
                'total_rows' => $results['total_rows'] ?? 0,
                'status' => 'completed',
                'message' => 'Processing completed successfully!',
                'results' => $results,
                'file_name' => basename($this->filePath)
            ]);

            Log::info('CSV import completed successfully', [
                'session_id' => $this->sessionId,
                'results' => $results
            ]);

        } catch (\Exception $e) {
            // Update progress to failed
            $this->updateProgress([
                'percentage' => 0,
                'current_row' => 0,
                'total_rows' => 0,
                'status' => 'failed',
                'message' => 'Processing failed: ' . $e->getMessage(),
                'error' => $e->getMessage(),
                'file_name' => basename($this->filePath)
            ]);

            Log::error('CSV import failed', [
                'session_id' => $this->sessionId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            throw $e;
        }
    }

    /**
     * Handle a job failure.
     */
    public function failed(\Throwable $exception): void
    {
        $this->updateProgress([
            'percentage' => 0,
            'current_row' => 0,
            'total_rows' => 0,
            'status' => 'failed',
            'message' => 'Job failed: ' . $exception->getMessage(),
            'error' => $exception->getMessage(),
            'file_name' => basename($this->filePath)
        ]);

        Log::error('CSV import job failed', [
            'session_id' => $this->sessionId,
            'error' => $exception->getMessage()
        ]);
    }

    /**
     * Update progress in cache.
     */
    private function updateProgress(array $progressData): void
    {
        Cache::put("upload_progress_{$this->sessionId}", $progressData, 600); // 10 minutes TTL
    }
}
