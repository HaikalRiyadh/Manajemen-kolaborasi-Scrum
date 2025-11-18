<?php
// Tahan semua pesan error PHP agar tidak merusak output JSON
error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING & ~E_DEPRECATED); 
ini_set('display_errors', 0); 

// === HEADER DAN KONFIGURASI CORS ===
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS"); // Menggunakan GET untuk pengambilan data
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

// Fungsi bantuan untuk mengirim respons JSON dan keluar
function sendJsonResponse($status_code, $data) {
    http_response_code($status_code);
    echo json_encode($data);
    exit();
}

// Jika request OPTIONS (Preflight check CORS), langsung exit
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    sendJsonResponse(200, ["status" => "ok"]);
}

// --- KONFIGURASI & KONEKSI DATABASE ---
$servername = "127.0.0.1";
$username_db = "root";
$password_db = "";
$dbname = "lib_scrum_app";

// Aktifkan reporting error untuk mysqli
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    $conn = new mysqli($servername, $username_db, $password_db, $dbname);
    $conn->set_charset("utf8mb4"); 
} catch (mysqli_sql_exception $e) {
    // Jika koneksi gagal, langsung kirim JSON error
    sendJsonResponse(500, [
        "status" => "error", 
        "message" => "Koneksi database gagal. Pastikan Laragon/MySQL berjalan. Detail: " . $e->getMessage()
    ]);
}

// --- AMBIL SEMUA DATA DARI TABEL projects ---
$sql = "SELECT id, name, duration, progress FROM projects ORDER BY id DESC";

// Menggunakan try-catch untuk eksekusi query (optional, karena strict reporting sudah aktif)
try {
    $result = $conn->query($sql);
} catch (Exception $e) {
    // Tangani error jika query gagal
    sendJsonResponse(500, [
        "status" => "error", 
        "message" => "Gagal mengeksekusi query database. Cek tabel 'projects' Anda."
    ]);
}


$projects = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // Konversi tipe data agar sesuai dengan Flutter
        $row['id'] = intval($row['id']);
        $row['duration'] = intval($row['duration']);
        $row['progress'] = intval($row['progress']); 
        $projects[] = $row;
    }
}

// Kirim data yang sudah bersih
sendJsonResponse(200, ["status" => "success", "data" => $projects]);

$conn->close();