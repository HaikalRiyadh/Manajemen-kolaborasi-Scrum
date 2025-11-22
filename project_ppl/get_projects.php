<?php
// 1. Include the central helper file.
require_once __DIR__ . '/api_helpers.php';

// This endpoint only handles GET requests.
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendJsonResponse(405, ['status' => 'error', 'message' => 'Method Not Allowed']);
}

// 2. --- OPERASI DATABASE ---
try {
    $result = $conn->query("SELECT id, name, duration, progress FROM projects ORDER BY id DESC");
    
    $projects = [];
    if ($result && $result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            // Konversi tipe data agar konsisten dengan model Flutter
            $row['id'] = strval($row['id']);
            $row['duration'] = intval($row['duration']);
            $row['progress'] = intval($row['progress']); 
            $projects[] = $row;
        }
    }
    sendJsonResponse(200, ["status" => "success", "data" => $projects]);

} catch (Exception $e) {
    sendJsonResponse(500, ["status" => "error", "message" => "Gagal mengambil data proyek: " . $e->getMessage()]);
} finally {
    if (isset($conn)) $conn->close();
}
?>
