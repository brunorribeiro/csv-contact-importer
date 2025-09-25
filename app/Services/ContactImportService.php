<?php

namespace App\Services;

use App\Events\CsvProcessingProgress;
use App\Models\Contact;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Validator;

class ContactImportService
{
    /**
     * Import contacts from CSV file.
     */
    public function importFromCsv(string $filePath, ?string $sessionId = null): array
    {
        if ($sessionId) {
            $this->updateProgress($sessionId, [
                'percentage' => 0,
                'current_row' => 0,
                'total_rows' => 0,
                'status' => 'starting',
                'message' => 'Starting file processing...',
                'file_name' => basename($filePath)
            ]);
        }

        $handle = $this->openCsvFile($filePath);
        $delimiter = $this->detectDelimiter($handle);
        $header = $this->getAndValidateHeader($handle, $delimiter);
        $columnMapping = $this->mapColumns($header);
        
        $this->validateRequiredColumns($columnMapping);
        
        // Count total rows for progress calculation
        $totalRows = $this->countCsvRows($handle);
        
        if ($sessionId) {
            $this->updateProgress($sessionId, [
                'percentage' => 5,
                'current_row' => 0,
                'total_rows' => $totalRows,
                'status' => 'processing',
                'message' => "Processing {$totalRows} rows...",
                'file_name' => basename($filePath)
            ]);
        }
        
        return $this->processRows($handle, $delimiter, $columnMapping, $sessionId, $totalRows);
    }

    /**
     * Open CSV file and validate.
     */
    private function openCsvFile(string $filePath)
    {
        $handle = fopen($filePath, 'r');
        if (!$handle) {
            throw new \Exception('Could not open CSV file');
        }
        return $handle;
    }

    /**
     * Detect CSV delimiter.
     */
    private function detectDelimiter($handle): string
    {
        $firstLine = fgets($handle);
        rewind($handle);
        
        return strpos($firstLine, ';') !== false ? ';' : ',';
    }

    /**
     * Get and validate CSV header.
     */
    private function getAndValidateHeader($handle, string $delimiter): array
    {
        $header = fgetcsv($handle, 0, $delimiter);
        
        if (!$header) {
            fclose($handle);
            throw new \Exception('CSV file is empty or invalid');
        }

        return array_map(function($col) {
            return strtolower(trim($col));
        }, $header);
    }

    /**
     * Map CSV columns to contact fields.
     */
    private function mapColumns(array $header): array
    {
        return [
            'name' => $this->findColumnIndex($header, ['name', 'full_name', 'fullname']),
            'email' => $this->findColumnIndex($header, ['email', 'email_address', 'e-mail']),
            'phone' => $this->findColumnIndex($header, ['phone', 'telephone', 'phone_number']),
            'birthdate' => $this->findColumnIndex($header, ['birthdate', 'birth_date', 'dob', 'date_of_birth']),
        ];
    }

    /**
     * Validate that required columns exist.
     */
    private function validateRequiredColumns(array $columnMapping): void
    {
        if ($columnMapping['name'] === false || $columnMapping['email'] === false) {
            throw new \Exception('CSV must contain at least name and email columns');
        }
    }

    /**
     * Count total rows in CSV file.
     */
    private function countCsvRows($handle): int
    {
        $currentPosition = ftell($handle);
        $count = 0;
        
        while (fgetcsv($handle) !== false) {
            $count++;
        }
        
        // Reset file pointer to original position
        fseek($handle, $currentPosition);
        
        return $count;
    }

    /**
     * Process CSV rows and import contacts.
     */
    private function processRows($handle, string $delimiter, array $columnMapping, ?string $sessionId = null, int $totalRows = 0): array
    {
        $stats = $this->initializeStats();
        $existingEmails = Contact::pluck('email')->toArray();
        $processedEmails = [];
        $currentRow = 0;

        while (($row = fgetcsv($handle, 0, $delimiter)) !== false) {
            $currentRow++;
            $stats['total_rows']++;
            
            // Update progress every 5 rows for more responsive updates
            if ($sessionId && ($currentRow % 5 === 0 || $currentRow === $totalRows)) {
                $percentage = $totalRows > 0 ? min(95, 5 + (($currentRow / $totalRows) * 90)) : 50;
                $this->updateProgress($sessionId, [
                    'percentage' => round($percentage),
                    'current_row' => $currentRow,
                    'total_rows' => $totalRows,
                    'status' => 'processing',
                    'message' => "Processing row {$currentRow} of {$totalRows}...",
                    'imported' => $stats['imported'],
                    'duplicates' => $stats['duplicates'],
                    'errors' => $stats['validation_errors'],
                    'file_name' => basename($handle) ?? 'Unknown'
                ]);
            }
            
            if (!$this->isValidRow($row, $columnMapping, $stats)) {
                continue;
            }

            $contactData = $this->extractContactData($row, $columnMapping);
            
            if (!$this->validateContactData($contactData, $stats)) {
                continue;
            }

            if ($this->isDuplicate($contactData['email'], $existingEmails, $processedEmails)) {
                $stats['duplicates']++;
                continue;
            }

            if ($this->createContact($contactData, $processedEmails, $stats)) {
                $stats['imported']++;
            }
        }

        // Final progress update
        if ($sessionId) {
            $this->updateProgress($sessionId, [
                'percentage' => 100,
                'current_row' => $currentRow,
                'total_rows' => $totalRows,
                'status' => 'completed',
                'message' => 'Processing completed successfully!',
                'results' => $stats,
                'file_name' => basename($handle) ?? 'Unknown'
            ]);
        }

        fclose($handle);
        return $stats;
    }

    /**
     * Find column index by possible names.
     */
    private function findColumnIndex(array $header, array $possibleNames)
    {
        foreach ($possibleNames as $name) {
            $index = array_search($name, $header);
            if ($index !== false) {
                return $index;
            }
        }
        return false;
    }

    /**
     * Initialize import statistics.
     */
    private function initializeStats(): array
    {
        return [
            'total_rows' => 0,
            'imported' => 0,
            'duplicates' => 0,
            'validation_errors' => 0,
            'errors' => []
        ];
    }

    /**
     * Check if row is valid.
     */
    private function isValidRow(array $row, array $columnMapping, array &$stats): bool
    {
        if (count($row) < 2) { // At least name and email
            $stats['validation_errors']++;
            $stats['errors'][] = "Row {$stats['total_rows']}: Insufficient columns";
            return false;
        }
        return true;
    }

    /**
     * Extract contact data from row.
     */
    private function extractContactData(array $row, array $columnMapping): array
    {
        return [
            'name' => isset($row[$columnMapping['name']]) ? trim($row[$columnMapping['name']]) : '',
            'email' => isset($row[$columnMapping['email']]) ? trim(strtolower($row[$columnMapping['email']])) : '',
            'phone' => $columnMapping['phone'] !== false && isset($row[$columnMapping['phone']]) ? trim($row[$columnMapping['phone']]) : null,
            'birthdate' => $columnMapping['birthdate'] !== false && isset($row[$columnMapping['birthdate']]) ? $this->parseDate(trim($row[$columnMapping['birthdate']])) : null,
        ];
    }

    /**
     * Validate contact data.
     */
    private function validateContactData(array $contactData, array &$stats): bool
    {
        $validator = Validator::make($contactData, [
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255',
            'phone' => 'nullable|phone:US',
            'birthdate' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            $stats['validation_errors']++;
            $stats['errors'][] = "Row {$stats['total_rows']}: " . implode(', ', $validator->errors()->all());
            return false;
        }

        return true;
    }

    /**
     * Check if email is duplicate.
     */
    private function isDuplicate(string $email, array $existingEmails, array $processedEmails): bool
    {
        return in_array($email, $existingEmails) || in_array($email, $processedEmails);
    }

    /**
     * Create contact and handle errors.
     */
    private function createContact(array $contactData, array &$processedEmails, array &$stats): bool
    {
        try {
            Contact::create($contactData);
            $processedEmails[] = $contactData['email'];
            return true;
        } catch (\Exception $e) {
            $stats['validation_errors']++;
            $stats['errors'][] = "Row {$stats['total_rows']}: Database error - " . $e->getMessage();
            return false;
        }
    }

    /**
     * Parse date string to Y-m-d format.
     */
    private function parseDate(?string $dateString): ?string
    {
        if (empty($dateString)) {
            return null;
        }

        // Try different date formats
        $formats = ['Y-m-d', 'd/m/Y', 'm/d/Y', 'd-m-Y', 'm-d-Y'];
        
        foreach ($formats as $format) {
            $date = \DateTime::createFromFormat($format, $dateString);
            if ($date && $date->format($format) === $dateString) {
                return $date->format('Y-m-d');
            }
        }

        // Try strtotime as fallback
        $timestamp = strtotime($dateString);
        if ($timestamp !== false) {
            return date('Y-m-d', $timestamp);
        }

        return null;
    }

    /**
     * Update progress in cache and broadcast event.
     */
    private function updateProgress(string $sessionId, array $progressData): void
    {
        // Store in cache
        Cache::put("upload_progress_{$sessionId}", $progressData, 600); // 10 minutes TTL
        
        // Broadcast real-time update
        try {
            broadcast(new CsvProcessingProgress($sessionId, $progressData));
        } catch (\Exception $e) {
            // Log error but don't fail the import process
            \Log::warning('Failed to broadcast progress update', [
                'session_id' => $sessionId,
                'error' => $e->getMessage()
            ]);
        }
    }
}
