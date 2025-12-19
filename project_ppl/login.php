<?php
// === KONEKSI DAN HELPER ===
require_once __DIR__ . '/api_helpers.php';

// --- AMBIL DATA DARI FLUTTER ---
$username = $password = null;

if (isset($_POST['username'], $_POST['password'])) {
    $username = trim($_POST['username']);
    $password = $_POST['password']; 
} else {
    $input = json_decode(file_get_contents("php://input"), true);
    if ($input && isset($input['username'], $input['password'])) {
        $username = trim($input['username']);
        $password = $input['password'];
    }
}

// --- VALIDASI INPUT ---
if (empty($username) || $password === null || $password === '') { 
    sendJsonResponse(400, [
        "status" => "error",
        "message" => "Username dan password harus diisi"
    ]);
}

// --- PREPARED STATEMENT ---
$stmt = $conn->prepare("SELECT id, username, password, full_name, role FROM users WHERE username = ?");
if (!$stmt) {
    sendJsonResponse(500, ["status" => "error", "message" => "Query preparation failed: " . $conn->error]);
}

$stmt->bind_param("s", $username);

try {
    $stmt->execute();
    $result = $stmt->get_result();
} catch (Exception $e) {
    $stmt->close();
    sendJsonResponse(500, [
        "status" => "error",
        "message" => "Eksekusi query gagal: " . $e->getMessage()
    ]);
}

// --- VERIFIKASI USER ---
if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();

    if (!empty($user['password']) && password_verify($password, $user['password'])) {
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
        sendJsonResponse(401, [
            "status" => "error",
            "message" => "Kombinasi username atau password salah"
        ]);
    }
} else {
    sendJsonResponse(401, [
        "status" => "error",
        "message" => "Kombinasi username atau password salah"
    ]);
}

$stmt->close();
// TIDAK ADA TAG PENUTUP PHP (?>) UNTUK MENCEGAH WHITESPACE INJECTION