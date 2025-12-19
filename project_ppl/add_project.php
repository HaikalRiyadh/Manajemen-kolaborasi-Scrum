<?php
require_once __DIR__ . '/api_helpers.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = $_POST;
    if (empty($data)) {
        $inputJSON = file_get_contents('php://input');
        $data = json_decode($inputJSON, TRUE) ?? [];
    }

    $name = $data['name'] ?? '';
    $sprint_str = $data['sprint'] ?? '0'; 
    $user_id = isset($data['user_id']) ? intval($data['user_id']) : 0;

    if (empty(trim($name))) {
        sendJsonResponse(400, ["status" => "error", "message" => "Field 'name' wajib diisi"]);
    }
    if ($user_id <= 0) {
        sendJsonResponse(400, ["status" => "error", "message" => "User ID tidak valid. Silakan login ulang."]);
    }

    $sprint_int = intval($sprint_str);
    if ($sprint_int <= 0) $sprint_int = 1; 

    // Debugging: Cek apakah prepare berhasil
    $stmt = $conn->prepare("INSERT INTO projects (user_id, name, sprint) VALUES (?, ?, ?)");
    
    if (!$stmt) {
        // Kemungkinan besar kolom user_id belum ada di database
        sendJsonResponse(500, [
            "status" => "error", 
            "message" => "Gagal menyiapkan query database. Kemungkinan struktur tabel belum diupdate (kolom user_id hilang). Error: " . $conn->error
        ]);
    }

    $stmt->bind_param('isi', $user_id, $name, $sprint_int);
    
    if ($stmt->execute()) {
        $insert_id = $conn->insert_id;
        sendJsonResponse(201, ["status" => "success", "message" => "Project berhasil dibuat", "id" => intval($insert_id)]);
    } else {
        sendJsonResponse(500, ["status" => "error", "message" => "Gagal membuat project: " . $stmt->error]);
    }
    $stmt->close();

} else {
    sendJsonResponse(405, ["status" => "error", "message" => "Method not allowed."]);
}
// Tidak ada tag penutup PHP
