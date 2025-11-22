<?php
// File: get_tasks.php

require_once __DIR__ . '/api_helpers.php';

if (php_sapi_name() !== 'cli' && $_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendJsonResponse(405, ['status' => 'error', 'message' => 'Method Not Allowed']);
}

$project_id = $_GET['project_id'] ?? 0;
if (empty($project_id) || !is_numeric($project_id)) {
    sendJsonResponse(400, ["status" => "error", "message" => "Parameter 'project_id' wajib diisi dan harus berupa angka."]);
}

// PERBAIKAN UTAMA: Query ini TIDAK LAGI mengambil kolom 'completion_day'
$stmt = $conn->prepare("SELECT id, project_id, title, status, story_points FROM tasks WHERE project_id = ?");
$stmt->bind_param("i", $project_id);
$stmt->execute();
$result = $stmt->get_result();

$tasks = [];
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $row['id'] = strval($row['id']);
        $row['project_id'] = strval($row['project_id']);
        $row['story_points'] = intval($row['story_points']);
        $tasks[] = $row;
    }
}
$stmt->close();

sendJsonResponse(200, ["status" => "success", "data" => $tasks]);
?>