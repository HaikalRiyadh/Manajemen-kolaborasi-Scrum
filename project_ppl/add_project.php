<?php
// Tahan semua pesan error PHP agar tidak merusak output JSON
error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING & ~E_DEPRECATED); 
ini_set('display_errors', 0); 

// === HEADER DAN KONFIGURASI CORS ===
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS"); // Mendukung POST untuk penambahan data
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
    // Preflight CORS
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

// Jika method POST -> lakukan INSERT
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Terima JSON atau form-encoded
    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    $raw = file_get_contents('php://input');
    if (stripos($contentType, 'application/json') !== false) {
        $data = json_decode($raw, true);
        if (!is_array($data)) {
            sendJsonResponse(400, ["status" => "error", "message" => "Invalid JSON body"]);
        }
    } else {
        // fallback ke $_POST (form-data or x-www-form-urlencoded)
        $data = $_POST;
    }

    $name = isset($data['name']) ? trim($data['name']) : '';
    $duration = isset($data['duration']) ? intval($data['duration']) : 0;
    $progress = isset($data['progress']) ? intval($data['progress']) : 0;

    if ($name === '') {
        sendJsonResponse(400, ["status" => "error", "message" => "Field 'name' wajib diisi"]);
    }

    // Persiapkan prepared statement untuk mencegah SQL injection
    try {
        $stmt = $conn->prepare("INSERT INTO projects (name, duration, progress) VALUES (?, ?, ?)");
        if ($stmt === false) {
            throw new Exception('Gagal membuat prepared statement');
        }
        $stmt->bind_param('sii', $name, $duration, $progress);
        $stmt->execute();
        $insert_id = $conn->insert_id;
        $stmt->close();

        sendJsonResponse(201, ["status" => "success", "message" => "Project berhasil dibuat", "id" => intval($insert_id)]);
    } catch (Exception $e) {
        sendJsonResponse(500, ["status" => "error", "message" => "Gagal memasukkan data: " . $e->getMessage()]);
    } finally {
        $conn->close();
    }

} else {
    // Default: GET -> ambil semua data dari tabel projects
    $sql = "SELECT id, name, duration, progress FROM projects ORDER BY id DESC";
    try {
        $result = $conn->query($sql);
    } catch (Exception $e) {
        sendJsonResponse(500, [
            "status" => "error",
            "message" => "Gagal mengeksekusi query database. Pastikan kolom 'duration' dan 'progress' ada di tabel 'projects'."
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
}