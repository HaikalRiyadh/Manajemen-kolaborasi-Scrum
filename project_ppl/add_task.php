<?php
// CORS & headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

function sendJsonResponse($code, $data) {
    http_response_code($code);
    echo json_encode($data);
    exit();
}

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    sendJsonResponse(200, ["status" => "ok"]);
}

include 'db_connect.php'; // Memanggil file koneksi

// Accept JSON or form data
$contentType = $_SERVER['CONTENT_TYPE'] ?? '';
if (stripos($contentType, 'application/json') !== false) {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    if (!is_array($data)) {
        sendJsonResponse(400, ["status" => "error", "message" => "Invalid JSON body."]);
    }
} else {
    $data = $_POST;
}

if (!isset($data['project_id'], $data['title'], $data['status'], $data['story_points'])) {
    sendJsonResponse(400, ["status" => "error", "message" => "Data input tidak lengkap."]);
}

// Cast and sanitize
$project_id = intval($data['project_id']);
$title = trim($data['title']);
$status = trim($data['status']);
$story_points = intval($data['story_points']);

if ($title === '') {
    sendJsonResponse(400, ["status" => "error", "message" => "Field 'title' tidak boleh kosong."]);
}

// Prepare and execute
$stmt = $conn->prepare("INSERT INTO tasks (project_id, title, status, story_points) VALUES (?, ?, ?, ?)");
if ($stmt === false) {
    sendJsonResponse(500, ["status" => "error", "message" => "Gagal menyiapkan statement: " . $conn->error]);
}

$bind = $stmt->bind_param("issi", $project_id, $title, $status, $story_points);
if ($bind === false) {
    $stmt->close();
    sendJsonResponse(500, ["status" => "error", "message" => "Gagal bind parameter: " . $stmt->error]);
}

if ($stmt->execute()) {
    $insert_id = $stmt->insert_id ?? $conn->insert_id;
    $stmt->close();
    $conn->close();
    sendJsonResponse(201, ["status" => "success", "message" => "Tugas berhasil ditambahkan.", "id" => intval($insert_id)]);
} else {
    $err = $stmt->error ?: $conn->error;
    $stmt->close();
    $conn->close();
    sendJsonResponse(500, ["status" => "error", "message" => "Gagal menambahkan tugas ke database: " . $err]);
}
?>