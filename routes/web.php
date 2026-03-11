<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/health', function () {
    return response()->json([
        'status' => 'online',
        'database' => 'connected',
    ]);
});

Route::get('/contact', function () {
    return response()->json([
        'status' => 'contact page',
        'database' => 'connected',
    ]);
});