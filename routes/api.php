<?php

use App\Http\Controllers\ContactController;
use App\Http\Controllers\UploadProgressController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Contact routes
Route::post('/contacts/upload', [ContactController::class, 'upload']);
Route::get('/contacts', [ContactController::class, 'index']);

// Upload progress routes
Route::get('/upload/progress', [UploadProgressController::class, 'getProgress']);
