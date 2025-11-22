<?php
// 1. Include the central helper file.
require_once __DIR__ . '/api_helpers.php';

// 2. This script should only handle POST requests for adding a project.
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // --- PROCESS INSERT PROJECT ---
    $data = $_POST;
    if (empty($data)) {
        $inputJSON = file_get_contents('php://input');
        $data = json_decode($inputJSON, TRUE) ?? [];
    }

    // Read 'name' and 'sprint' from the request
    $name = $data['name'] ?? '';
    $sprint_str = $data['sprint'] ?? '0'; // Baca sebagai string

    // Validasi input
    if (empty(trim($name))) {
        sendJsonResponse(400, ["status" => "error", "message" => "Field 'name' wajib diisi"]);
    }
    if (!is_numeric($sprint_str) || intval($sprint_str) <= 0) {
        sendJsonResponse(400, ["status" => "error", "message" => "Field 'sprint' harus berupa angka positif"]);
    }

    // Konversi sprint ke integer SETELAH validasi
    $sprint_int = intval($sprint_str);

    // The global handler in api_helpers.php will catch any database errors.
        $stmt = $conn->prepare("INSERT INTO projects (name, sprint) VALUES (?, ?)");
    $stmt->bind_param('si', $name, $sprint_int); // Pastikan variabel kedua adalah $sprint_int
    
    $stmt->execute();
    $insert_id = $conn->insert_id;
    $stmt->close();

    sendJsonResponse(201, ["status" => "success", "message" => "Project berhasil dibuat", "id" => intval($insert_id)]);

} else {
    // Method Not Allowed. This endpoint is only for creating projects.
    sendJsonResponse(405, ["status" => "error", "message" => "Method not allowed. Use POST to create a project."]);
}
?>