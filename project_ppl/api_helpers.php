<?php
// api_helpers.php

// --- STRATEGI PENANGANAN ERROR PALING TANGGUH ---

// 1. Mulai output buffering untuk menangkap semua output liar
ob_start();

// 2. Set error handler kustom
set_error_handler(function($severity, $message, $file, $line) {
    if (error_reporting() === 0) {
        return false;
    }
    throw new ErrorException($message, 0, $severity, $file, $line);
});

// 3. Fungsi untuk mengirim respons JSON yang dijamin bersih
function sendJsonResponse($status_code, $data) {
    if (ob_get_length()) {
        ob_end_clean();
    }
    // Hanya set header jika tidak berjalan di CLI
    if (php_sapi_name() !== 'cli') {
        http_response_code($status_code);
        header('Content-Type: application/json');
    }
    echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    exit();
}

// 4. Set exception handler global sebagai lapisan pertahanan terakhir
set_exception_handler(function($exception) {
    sendJsonResponse(500, [
        'status' => 'error',
        'message' => 'An unhandled exception occurred.',
        'detail' => [
            'error_message' => $exception->getMessage(),
            'file' => $exception->getFile(),
            'line' => $exception->getLine(),
        ]
    ]);
});

// 5. HEADERS, CORS, & PREFLIGHT REQUEST
// Hanya jalankan ini jika tidak dalam mode CLI
if (php_sapi_name() !== 'cli') {
    header("Access-Control-Allow-Origin: *");
    header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type");

    // PERBAIKAN: Cek apakah REQUEST_METHOD ada sebelum digunakan
    if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        sendJsonResponse(200, ["status" => "ok"]);
    }
}


// 6. KONEKSI DATABASE
$servername = "127.0.0.1";
$username_db = "root";
$password_db = "";
$dbname = "lib_scrum_app"; // PERBAIKAN: Nama database dikembalikan sesuai gambar

$conn = new mysqli($servername, $username_db, $password_db, $dbname);
if ($conn->connect_error) {
    throw new Exception("Database connection failed: " . $conn->connect_error);
}
$conn->set_charset("utf8mb4");

?>
