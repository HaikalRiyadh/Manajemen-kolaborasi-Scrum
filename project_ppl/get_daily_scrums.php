<?php
require_once __DIR__ . '/api_helpers.php';

// Ambil parameter (support GET dan POST)
$project_id = 0;
if (isset($_GET['project_id'])) {
    $project_id = intval($_GET['project_id']);
} elseif (isset($_POST['project_id'])) {
    $project_id = intval($_POST['project_id']);
} else {
    $input = json_decode(file_get_contents("php://input"), true);
    if ($input && isset($input['project_id'])) {
        $project_id = intval($input['project_id']);
    }
}

if ($project_id <= 0) {
    sendJsonResponse(400, ["status" => "error", "message" => "project_id diperlukan"]);
}

try {
    // Buat tabel daily_scrums jika belum ada
    $conn->query("
        CREATE TABLE IF NOT EXISTS daily_scrums (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            project_id INT NOT NULL,
            yesterday TEXT NOT NULL,
            today TEXT NOT NULL,
            blockers TEXT,
            scrum_date DATE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    // Ambil daily scrum logs dengan info username
    $stmt = $conn->prepare("
        SELECT ds.*, u.username 
        FROM daily_scrums ds 
        LEFT JOIN users u ON ds.user_id = u.id 
        WHERE ds.project_id = ? 
        ORDER BY ds.scrum_date DESC, ds.created_at DESC
    ");

    if (!$stmt) {
        throw new Exception("Gagal prepare statement: " . $conn->error);
    }

    $stmt->bind_param("i", $project_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $logs = [];
    while ($row = $result->fetch_assoc()) {
        $logs[] = $row;
    }

    $stmt->close();

    sendJsonResponse(200, ["status" => "success", "data" => $logs]);

} catch (Exception $e) {
    sendJsonResponse(500, [
        "status" => "error",
        "message" => "Gagal mengambil daily scrum logs: " . $e->getMessage()
    ]);
} finally {
    if (isset($conn)) $conn->close();
}
