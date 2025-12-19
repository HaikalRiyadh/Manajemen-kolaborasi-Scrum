<?php
// api_helpers.php

// Matikan display error agar tidak merusak format JSON
ini_set('display_errors', 0);
error_reporting(E_ALL);

// 1. Mulai output buffering
ob_start();

// 2. Set error handler kustom
set_error_handler(function($severity, $message, $file, $line) {
    if (error_reporting() === 0) {
        return false;
    }
    throw new ErrorException($message, 0, $severity, $file, $line);
});

// 3. Fungsi untuk mengirim respons JSON
function sendJsonResponse($status_code, $data) {
    // Bersihkan buffer output agar tidak ada teks lain yang terkirim
    if (ob_get_length()) {
        ob_clean(); 
    }
    
    // Hanya set header jika tidak berjalan di CLI
    if (php_sapi_name() !== 'cli') {
        http_response_code($status_code);
        header('Content-Type: application/json');
    }
    echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    exit();
}

// 4. Set exception handler global
set_exception_handler(function($exception) {
    sendJsonResponse(500, [
        'status' => 'error',
        'message' => 'An unhandled exception occurred.',
        'detail' => [
            'error_message' => $exception->getMessage(),
        ]
    ]);
});

// 5. HEADERS, CORS
if (php_sapi_name() !== 'cli') {
    header("Access-Control-Allow-Origin: *");
    header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type");

    if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        sendJsonResponse(200, ["status" => "ok"]);
    }
}

// 6. KONEKSI DATABASE
$servername = "127.0.0.1";
$username_db = "root";
$password_db = "";
$dbname = "lib_scrum_app";

// Gunakan try-catch khusus untuk koneksi awal
try {
    $conn = new mysqli($servername, $username_db, $password_db, $dbname);
    if ($conn->connect_error) {
        throw new Exception("Database connection failed: " . $conn->connect_error);
    }
    $conn->set_charset("utf8mb4");
} catch (Exception $e) {
    sendJsonResponse(500, [
        'status' => 'error', 
        'message' => 'Gagal koneksi database. Pastikan database lib_scrum_app ada.',
        'detail' => $e->getMessage()
    ]);
}
// File PHP murni sebaiknya TIDAK diakhiri dengan tag penutup PHP untuk mencegah output whitespace tidak sengaja