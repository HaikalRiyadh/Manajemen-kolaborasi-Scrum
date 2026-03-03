<?php
require_once __DIR__ . '/api_helpers.php';

// This endpoint only handles POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendJsonResponse(405, ['status' => 'error', 'message' => 'Method Not Allowed']);
}

// --- PROSES INPUT ---
$data = $_POST;
if (empty($data)) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE) ?? [];
}

$user_id = isset($data['user_id']) ? intval($data['user_id']) : 0;
$project_id = isset($data['project_id']) ? intval($data['project_id']) : 0;
$yesterday = isset($data['yesterday']) ? trim($data['yesterday']) : '';
$today = isset($data['today']) ? trim($data['today']) : '';
$blockers = isset($data['blockers']) ? trim($data['blockers']) : '';

// --- VALIDASI ---
if ($user_id <= 0 || $project_id <= 0) {
    sendJsonResponse(400, [
        "status" => "error",
        "message" => "user_id dan project_id wajib diisi dan valid."
    ]);
}

if (empty($yesterday) || empty($today)) {
    sendJsonResponse(400, [
        "status" => "error",
        "message" => "Field 'yesterday' dan 'today' wajib diisi."
    ]);
}

// --- OPERASI DATABASE ---
try {
    // Cek apakah tabel daily_scrums sudah ada, jika belum buat
    $checkTable = $conn->query("SHOW TABLES LIKE 'daily_scrums'");
    if ($checkTable->num_rows == 0) {
        $createSql = "CREATE TABLE IF NOT EXISTS `daily_scrums` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `user_id` INT(11) NOT NULL,
            `project_id` INT(11) NOT NULL,
            `yesterday` TEXT NOT NULL,
            `today` TEXT NOT NULL,
            `blockers` TEXT,
            `scrum_date` DATE NOT NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
            FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`) ON DELETE CASCADE
        )";
        $conn->query($createSql);
    }

    $scrum_date = date('Y-m-d');

    $stmt = $conn->prepare(
        "INSERT INTO daily_scrums (user_id, project_id, yesterday, today, blockers, scrum_date) VALUES (?, ?, ?, ?, ?, ?)"
    );
    if (!$stmt) {
        throw new Exception("Gagal prepare statement: " . $conn->error);
    }

    $stmt->bind_param("iissss", $user_id, $project_id, $yesterday, $today, $blockers, $scrum_date);

    if ($stmt->execute()) {
        $insert_id = $conn->insert_id;
        sendJsonResponse(201, [
            "status" => "success",
            "message" => "Daily Scrum berhasil disimpan",
            "id" => $insert_id
        ]);
    } else {
        throw new Exception("Gagal menyimpan: " . $stmt->error);
    }

    $stmt->close();

} catch (Exception $e) {
    sendJsonResponse(500, [
        "status" => "error",
        "message" => "Gagal menyimpan daily scrum: " . $e->getMessage()
    ]);
} finally {
    if (isset($conn)) $conn->close();
}
