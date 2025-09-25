<?php

namespace App\Http\Controllers;

use App\Http\Requests\ContactUploadRequest;
use App\Jobs\ProcessCsvImportJob;
use App\Models\Contact;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;

class ContactController extends Controller
{
    /**
     * Upload and queue CSV file for processing.
     */
    public function upload(ContactUploadRequest $request): JsonResponse
    {
        $file = $request->file('csv_file');
        $sessionId = $request->get('session_id', uniqid('upload_', true));
        
        try {
            // Store the uploaded file temporarily
            $fileName = 'csv_imports/' . $sessionId . '_' . $file->getClientOriginalName();
            $filePath = $file->storeAs('csv_imports', $sessionId . '_' . $file->getClientOriginalName(), 'local');
            $fullPath = Storage::path($filePath);

            // Initialize progress
            Cache::put("upload_progress_{$sessionId}", [
                'percentage' => 0,
                'current_row' => 0,
                'total_rows' => 0,
                'status' => 'queued',
                'message' => 'File uploaded successfully. Processing queued...',
                'file_name' => $file->getClientOriginalName(),
                'file_size' => $this->formatFileSize($file->getSize())
            ], 600);

            // Dispatch the job
            ProcessCsvImportJob::dispatch($fullPath, $sessionId);

            return response()->json([
                'success' => true,
                'session_id' => $sessionId,
                'message' => 'File uploaded and queued for processing',
                'file_name' => $file->getClientOriginalName(),
                'file_size' => $this->formatFileSize($file->getSize())
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
                'session_id' => $sessionId
            ], 400);
        }
    }

    /**
     * Get paginated list of contacts.
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = $request->get('per_page', 15);
        $search = $request->get('search');

        $query = Contact::query();

        if ($search) {
            $query->search($search);
        }

        $contacts = $query->orderBy('created_at', 'desc')
            ->paginate($perPage);

        // Add gravatar URL to each contact
        $contacts->getCollection()->transform(function ($contact) {
            $contact->gravatar_url = $contact->gravatar_url;
            $contact->formatted_phone = $contact->formatted_phone;
            return $contact;
        });

        return response()->json($contacts);
    }

    /**
     * Format file size in human readable format.
     */
    private function formatFileSize(int $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);

        $bytes /= pow(1024, $pow);

        return round($bytes, 2) . ' ' . $units[$pow];
    }
}
