<?php
// === HEADER DAN KONFIGURASI CORS ===
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
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

// --- KONEKSI DATABASE ---
// Pastikan file ini berisi koneksi ke database Anda ($conn)
include 'db_connect.php'; 

// --- AMBIL DATA DARI FLUTTER ---
// Prioritaskan $_POST (form-data dari http.post)
$input = $_POST;

// Fallback untuk raw JSON (meskipun Flutter biasanya pakai $_POST untuk body:{...})
if (empty($input)) {
    $input = json_decode(file_get_contents("php://input"), true);
}

$username = $password_raw = $full_name = null;

if ($input && isset($input['username'], $input['password'], $input['full_name'])) {
    $username = trim($input['username']);
    $password_raw = $input['password']; // Password mentah
    $full_name = trim($input['full_name']);
} 

// --- VALIDASI INPUT ---
if (empty($username) || empty($password_raw) || empty($full_name)) {
    sendJsonResponse(400, [
        "status" => "error",
        "message" => "Data tidak lengkap. Harus ada username, password, dan full_name."
    ]);
}

// --- 1. CEK USERNAME SUDAH ADA BELUM (Menggunakan Prepared Statement) ---
$stmt_check = $conn->prepare("SELECT id FROM users WHERE username = ?");
if (!$stmt_check) {
    sendJsonResponse(500, ["status" => "error", "message" => "Prepared statement gagal: " . $conn->error]);
}
$stmt_check->bind_param("s", $username);

try {
    $stmt_check->execute();
    $result_check = $stmt_check->get_result();
} catch (Exception $e) {
    $stmt_check->close();
    $conn->close();
    sendJsonResponse(500, ["status" => "error", "message" => "Eksekusi cek username gagal"]);
}

if ($result_check->num_rows > 0) {
    $stmt_check->close();
    $conn->close();
    sendJsonResponse(409, [ // 409 Conflict: resource sudah ada
        "status" => "error",
        "message" => "Username sudah terdaftar!"
    ]);
}
$stmt_check->close();

// --- 2. SIMPAN KE DATABASE (Menggunakan Prepared Statement) ---

// Hash password sebelum disimpan
$password_hashed = password_hash($password_raw, PASSWORD_DEFAULT);

// Prepared Statement untuk INSERT
$stmt_insert = $conn->prepare("INSERT INTO users (username, password, full_name, role) VALUES (?, ?, ?, 'user')");
if (!$stmt_insert) {
    sendJsonResponse(500, ["status" => "error", "message" => "Prepared statement gagal (INSERT): " . $conn->error]);
}

$stmt_insert->bind_param("sss", $username, $password_hashed, $full_name);

if ($stmt_insert->execute()) {
    sendJsonResponse(200, [
        "status" => "success",
        "message" => "Registrasi berhasil",
        "data" => [
            "id" => $conn->insert_id,
            "username" => $username,
            "full_name" => $full_name
        ]
    ]);
} else {
    sendJsonResponse(500, [
        "status" => "error",
        "message" => "Gagal registrasi: " . $stmt_insert->error
    ]);
}

$stmt_insert->close();
$conn->close();
?>