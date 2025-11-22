<?php
// 1. Include the central helper file.
require_once __DIR__ . '/api_helpers.php';

// The script continues here. The $conn variable is available.
// Preflight requests (OPTIONS) are already handled by the helper.

// This endpoint only handles POST requests.
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendJsonResponse(405, ['status' => 'error', 'message' => 'Method Not Allowed']);
}

// 2. --- PROSES INPUT ---
$data = $_POST;
if (empty($data)) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE) ?? [];
}

// Validasi input
$project_id = isset($data['project_id']) ? intval($data['project_id']) : 0;
$title = isset($data['title']) ? trim($data['title']) : '';
$story_points = isset($data['story_points']) ? intval($data['story_points']) : 0;
$status = isset($data['status']) ? trim($data['status']) : 'backlog'; // Default status

if ($project_id <= 0 || $title === '' || $story_points <= 0) {
    sendJsonResponse(400, ["status" => "error", "message" => "Input tidak lengkap atau tidak valid: project_id, title, dan story_points wajib diisi."]);
}

// 3. --- OPERASI DATABASE ---
try {
    $stmt = $conn->prepare("INSERT INTO tasks (project_id, title, status, story_points) VALUES (?, ?, ?, ?)");
    if ($stmt === false) {
        throw new Exception("Gagal menyiapkan statement: " . $conn->error);
    }

    $stmt->bind_param("issi", $project_id, $title, $status, $story_points);
    $stmt->execute();
    $insert_id = $conn->insert_id;

    sendJsonResponse(201, ["status" => "success", "message" => "Tugas berhasil dibuat", "id" => strval($insert_id)]); // Kirim ID sebagai string

} catch (Exception $e) {
    sendJsonResponse(500, ["status" => "error", "message" => "Gagal memasukkan tugas ke database: " . $e->getMessage()]);
} finally {
    if (isset($stmt)) $stmt->close();
    if (isset($conn)) $conn->close();
}
?>
