<?php
require_once __DIR__ . '/api_helpers.php';

// Ambil user_id dari parameter GET
$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

if ($user_id <= 0) {
    sendJsonResponse(400, ["status" => "error", "message" => "user_id diperlukan"]);
}

// === FUNGSI LOGIKA PENGINGAT CERDAS ===
function generateSmartReminders($conn, $user_id) {
    // 1. Cek BOTTLENECK: Terlalu banyak tugas di "In Progress"
    // Batas wajar: 3 tugas. Jika lebih, beri peringatan agar fokus menyelesaikan.
    $sqlInProg = "
        SELECT p.name as project_name, COUNT(t.id) as task_count 
        FROM tasks t
        JOIN projects p ON t.project_id = p.id
        WHERE p.user_id = ? AND t.status = 'inProgress'
        GROUP BY p.id
        HAVING task_count > 3
    ";
    $stmt = $conn->prepare($sqlInProg);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $res = $stmt->get_result();
    while ($row = $res->fetch_assoc()) {
        createReminderIfNotExists($conn, $user_id, 
            "Fokus Terpecah di " . $row['project_name'], 
            "Anda memiliki " . $row['task_count'] . " tugas yang sedang berjalan (In Progress). Selesaikan satu per satu agar lebih efisien.",
            "alert"
        );
    }
    $stmt->close();

    // 2. Cek DEADLINE/TARGET: Sprint terakhir tapi progress < 80%
    $sqlSprint = "
        SELECT name, current_sprint, sprint, progress 
        FROM projects 
        WHERE user_id = ? AND current_sprint = sprint AND progress < 80
    ";
    $stmt = $conn->prepare($sqlSprint);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $res = $stmt->get_result();
    while ($row = $res->fetch_assoc()) {
        createReminderIfNotExists($conn, $user_id, 
            "Kejar Target Proyek " . $row['name'], 
            "Ini adalah sprint terakhir ({$row['current_sprint']}) tapi progress baru {$row['progress']}%. Ayo kebut penyelesaian tugas!",
            "alert"
        );
    }
    $stmt->close();

    // 3. Cek STARTING: Proyek baru tapi belum ada tugas (Reminder untuk planning)
    $sqlEmpty = "
        SELECT p.name 
        FROM projects p
        LEFT JOIN tasks t ON p.id = t.project_id
        WHERE p.user_id = ? AND t.id IS NULL
    ";
    $stmt = $conn->prepare($sqlEmpty);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $res = $stmt->get_result();
    while ($row = $res->fetch_assoc()) {
        createReminderIfNotExists($conn, $user_id, 
            "Mulai Perencanaan " . $row['name'], 
            "Proyek ini belum memiliki tugas sama sekali. Tambahkan tugas ke Backlog untuk memulai Scrum Board.",
            "info"
        );
    }
    $stmt->close();
}

// Helper untuk mencegah notifikasi duplikat dalam 24 jam terakhir
function createReminderIfNotExists($conn, $user_id, $title, $message, $type) {
    // Cek apakah notifikasi serupa sudah dibuat dalam 24 jam terakhir
    $checkSql = "SELECT id FROM notifications 
                 WHERE user_id = ? AND title = ? 
                 AND created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)";
    
    $stmtCheck = $conn->prepare($checkSql);
    $stmtCheck->bind_param("is", $user_id, $title);
    $stmtCheck->execute();
    $stmtCheck->store_result();
    
    if ($stmtCheck->num_rows == 0) {
        // Jika belum ada, buat notifikasi baru
        $insertSql = "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)";
        $stmtInsert = $conn->prepare($insertSql);
        $stmtInsert->bind_param("isss", $user_id, $title, $message, $type);
        $stmtInsert->execute();
        $stmtInsert->close();
    }
    $stmtCheck->close();
}
// ======================================

try {
    // 1. Jalankan logika Smart Reminders sebelum mengambil data
    generateSmartReminders($conn, $user_id);

    // 2. Ambil semua notifikasi (termasuk yang baru saja dibuat)
    $stmt = $conn->prepare("SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $notifications = [];
    while ($row = $result->fetch_assoc()) {
        $notifications[] = $row;
    }

    sendJsonResponse(200, ["status" => "success", "data" => $notifications]);

} catch (Exception $e) {
    sendJsonResponse(500, ["status" => "error", "message" => "Gagal mengambil notifikasi: " . $e->getMessage()]);
} finally {
    if (isset($conn)) $conn->close();
}
?>
