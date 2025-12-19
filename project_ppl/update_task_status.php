<?php

require_once __DIR__ . '/api_helpers.php';

// --- DEBUGGING SETUP ---
$log_file = __DIR__ . '/debug_log.txt';
// Hapus log lama setiap kali skrip dijalankan untuk kejelasan
if (file_exists($log_file)) { unlink($log_file); }
function write_log($message) {
    global $log_file;
    file_put_contents($log_file, "[" . date("Y-m-d H:i:s") . "] " . print_r($message, true) . "\n", FILE_APPEND);
}

write_log("Script update_task_status.php started.");

// Ambil data dari POST atau JSON body
$data = $_POST;
if (empty($data)) {
    write_log("Data POST kosong, mencoba membaca JSON body.");
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE) ?? [];
    write_log("Data JSON yang diterima:");
    write_log($data);
} else {
    write_log("Data POST yang diterima:");
    write_log($data);
}

// Ambil semua data yang relevan dari request
$task_id = $data['task_id'] ?? '';
$new_status = $data['new_status'] ?? '';
$assigned_sprint = $data['assigned_sprint'] ?? null;

write_log("Data yang diekstrak: task_id=$task_id, new_status=$new_status, assigned_sprint=$assigned_sprint");

// Validasi input dasar
if (empty(trim($task_id)) || empty(trim($new_status)) || $assigned_sprint === null) {
    $error_msg = "Input tidak lengkap: task_id, new_status, dan assigned_sprint wajib diisi.";
    write_log("VALIDATION FAILED: " . $error_msg);
    sendJsonResponse(400, ["status" => "error", "message" => $error_msg]);
}

// --- Logika Inti yang Disederhanakan ---

$completion_sprint_to_set = ($new_status === 'done') ? $assigned_sprint : null;
write_log("Nilai completion_sprint_to_set: " . ($completion_sprint_to_set ?? 'NULL'));

$sql = "UPDATE tasks SET status = ?, assigned_sprint = ?, completion_sprint = ? WHERE id = ?";
write_log("Query SQL yang akan dijalankan: " . $sql);

$stmt = $conn->prepare($sql);
if ($stmt === false) {
    $error_msg = "Gagal mempersiapkan statement SQL: " . $conn->error;
    write_log("DB PREPARE FAILED: " . $error_msg);
    sendJsonResponse(500, ["status" => "error", "message" => $error_msg]);
}

$stmt->bind_param("siis", $new_status, $assigned_sprint, $completion_sprint_to_set, $task_id);
write_log("Parameter yang di-bind: status=$new_status, assigned_sprint=$assigned_sprint, completion_sprint=" . ($completion_sprint_to_set ?? 'NULL') . ", id=$task_id");

if ($stmt->execute()) {
    write_log("SQL EXECUTE SUCCESSFUL.");
    sendJsonResponse(200, ["status" => "success", "message" => "Status tugas berhasil diperbarui."]);
} else {
    $error_msg = "Gagal memperbarui database: " . $stmt->error;
    write_log("DB EXECUTE FAILED: " . $error_msg);
    sendJsonResponse(500, ["status" => "error", "message" => $error_msg]);
}

$stmt->close();
write_log("Script finished.");

?>
