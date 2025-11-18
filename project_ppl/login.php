<?php
// === HEADER DAN KONFIGURASI CORS ===
// Header ini sangat penting untuk komunikasi antara Flutter/Emulator dan Laragon
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

// --- KONFIGURASI DATABASE ---
$servername = "localhost";
$username_db = "root";
$password_db = "";
$dbname = "lib_scrum_app";

// --- KONEKSI DATABASE ---
// Menggunakan mysqli_report untuk penanganan error yang lebih baik (Opsional, jika PHP >= 8.1)
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    $conn = new mysqli($servername, $username_db, $password_db, $dbname);
} catch (mysqli_sql_exception $e) {
    // Tangani kegagalan koneksi database
    sendJsonResponse(500, [
        "status" => "error",
        "message" => "Koneksi database gagal. Pastikan Laragon/MySQL berjalan. Detail: " . $e->getMessage()
    ]);
}

// --- AMBIL DATA DARI FLUTTER ---
// Flutter secara default mengirim data sebagai x-www-form-urlencoded (via $_POST)
// atau sebagai raw JSON. Kita prioritaskan $_POST karena ini umum untuk `http.post(url, body: {...})` di Flutter.
$username = $password = null;

if (isset($_POST['username'], $_POST['password'])) {
    // Data dari Flutter http.post(body: {...})
    $username = trim($_POST['username']);
    $password = $_POST['password']; // Jangan trim password
} else {
    // Fallback jika dikirim sebagai raw JSON
    $input = json_decode(file_get_contents("php://input"), true);
    if ($input && isset($input['username'], $input['password'])) {
        $username = trim($input['username']);
        $password = $input['password'];
    }
}

// --- VALIDASI INPUT ---
// PENTING: Password tidak boleh di trim agar tidak mengubah input user
if (empty($username) || $password === null || $password === '') { 
    sendJsonResponse(400, [
        "status" => "error",
        "message" => "Username dan password harus diisi"
    ]);
}

// --- PREPARED STATEMENT ---
$stmt = $conn->prepare("SELECT id, username, password, full_name, role FROM users WHERE username = ?");
$stmt->bind_param("s", $username);

try {
    $stmt->execute();
    $result = $stmt->get_result();
} catch (Exception $e) {
    $stmt->close();
    $conn->close();
    sendJsonResponse(500, [
        "status" => "error",
        "message" => "Eksekusi query gagal: " . $e->getMessage()
    ]);
}


// --- VERIFIKASI USER ---
if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();

    // Verifikasi hash password (Sangat bagus, pertahankan!)
    if (!empty($user['password']) && password_verify($password, $user['password'])) {
        // Login sukses
        sendJsonResponse(200, [
            "status" => "success",
            "message" => "Login berhasil",
            "data" => [
                "id" => $user['id'],
                "username" => $user['username'],
                "full_name" => $user['full_name'],
                "role" => $user['role']
            ]
        ]);
    } else {
        // Password salah (Gunakan 401 Unauthorized)
        sendJsonResponse(401, [
            "status" => "error",
            "message" => "Kombinasi username atau password salah" // Pesan digabungkan demi keamanan
        ]);
    }
} else {
    // Username tidak ditemukan (Gunakan 401 Unauthorized, bukan 404, untuk keamanan)
    sendJsonResponse(401, [
        "status" => "error",
        "message" => "Kombinasi username atau password salah"
    ]);
}

$stmt->close();
$conn->close();
?>