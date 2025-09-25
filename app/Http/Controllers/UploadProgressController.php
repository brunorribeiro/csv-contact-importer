<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;

class UploadProgressController extends Controller
{
    /**
     * Get upload progress for a specific session.
     */
    public function getProgress(Request $request): JsonResponse
    {
        $sessionId = $request->get('session_id');
        
        if (!$sessionId) {
            return response()->json(['error' => 'Session ID is required'], 400);
        }

        $progress = Cache::get("upload_progress_{$sessionId}", [
            'percentage' => 0,
            'current_row' => 0,
            'total_rows' => 0,
            'status' => 'waiting',
            'message' => 'Waiting for processing to start...',
            'file_name' => '',
            'file_size' => ''
        ]);

        return response()->json($progress);
    }

    /**
     * Update upload progress for a specific session.
     */
    public function updateProgress(string $sessionId, array $progressData): void
    {
        Cache::put("upload_progress_{$sessionId}", $progressData, 300); // 5 minutes TTL
    }

    /**
     * Clear progress data for a session.
     */
    public function clearProgress(string $sessionId): void
    {
        Cache::forget("upload_progress_{$sessionId}");
    }
}
