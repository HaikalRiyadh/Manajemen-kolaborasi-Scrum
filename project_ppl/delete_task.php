<?php
// 1. Include the central helper file.
require_once __DIR__ . '/api_helpers.php';

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

$task_id = isset($data['task_id']) ? trim(strval($data['task_id'])) : '';

if ($task_id === '') {
    sendJsonResponse(400, ["status" => "error", "message" => "Input 'task_id' wajib diisi."]);
}

// 3. --- OPERASI DATABASE ---
try {
    $stmt = $conn->prepare("DELETE FROM tasks WHERE id = ?");
    if ($stmt === false) {
        throw new Exception("Gagal menyiapkan statement: " . $conn->error);
    }

    $stmt->bind_param("s", $task_id);
    $stmt->execute();

    if ($stmt->affected_rows > 0) {
        sendJsonResponse(200, ["status" => "success", "message" => "Tugas berhasil dihapus."]);
    } else {
        // ID tidak ditemukan, tapi ini bukan error server. Kirim respons sukses agar klien bisa refresh.
        sendJsonResponse(200, ["status" => "success", "message" => "Tugas tidak ditemukan atau sudah dihapus."]);
    }

} catch (Exception $e) {
    sendJsonResponse(500, ["status" => "error", "message" => "Gagal menghapus tugas dari database: " . $e->getMessage()]);
} finally {
    if (isset($stmt)) $stmt->close();
    if (isset($conn)) $conn->close();
}
?>
