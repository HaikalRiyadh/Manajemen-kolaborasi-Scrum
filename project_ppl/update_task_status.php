<?php
// File: update_task_status.php

require_once __DIR__ . '/api_helpers.php';

$data = $_POST;
if (empty($data)) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE) ?? [];
}

$task_id = $data['task_id'] ?? '';
$new_status = $data['new_status'] ?? '';

if (empty(trim($task_id)) || empty(trim($new_status))) {
    sendJsonResponse(400, ["status" => "error", "message" => "Input tidak lengkap: task_id dan new_status wajib diisi."]);
}

// PERBAIKAN UTAMA: Query ini HANYA memperbarui kolom 'status'.
$stmt = $conn->prepare("UPDATE tasks SET status = ? WHERE id = ?");
$stmt->bind_param("ss", $new_status, $task_id);
$stmt->execute();
$stmt->close();

sendJsonResponse(200, ["status" => "success", "message" => "Operasi update selesai."]);
?>