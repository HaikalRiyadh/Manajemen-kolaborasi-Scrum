<?php
// CORS & headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
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

if (!isset($data['task_id'], $data['new_status'])) {
    sendJsonResponse(400, ["status" => "error", "message" => "Data input tidak lengkap."]);
}

$task_id = intval($data['task_id']);
$new_status = trim($data['new_status']);
$completion_day = isset($data['completion_day']) ? intval($data['completion_day']) : null;

// Prepare and execute
$stmt = $conn->prepare("UPDATE tasks SET status = ?, completion_day = ? WHERE id = ?");
if ($stmt === false) {
    sendJsonResponse(500, ["status" => "error", "message" => "Gagal menyiapkan statement: " . $conn->error]);
}

$bind = $stmt->bind_param("sii", $new_status, $completion_day, $task_id);
if ($bind === false) {
    $stmt->close();
    sendJsonResponse(500, ["status" => "error", "message" => "Gagal bind parameter: " . $stmt->error]);
}

if ($stmt->execute()) {
    $stmt->close();
    $conn->close();
    sendJsonResponse(200, ["status" => "success", "message" => "Status tugas berhasil diupdate."]);
} else {
    $err = $stmt->error ?: $conn->error;
    $stmt->close();
    $conn->close();
    sendJsonResponse(500, ["status" => "error", "message" => "Gagal mengupdate status tugas: " . $err]);
}
?>