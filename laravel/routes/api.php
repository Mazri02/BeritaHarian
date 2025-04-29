<?php 

use App\Http\Controllers\AuthController;
use App\Http\Controllers\NewsController;

// Public Routes
Route::get('/getNews', [NewsController::class, 'getNews']);
Route::get('/generateNews', [NewsController::class, 'generateLatestNews']);
Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});