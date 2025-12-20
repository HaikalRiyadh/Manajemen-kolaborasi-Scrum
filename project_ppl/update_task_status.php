<?php

require_once __DIR__ . '/api_helpers.php';

// --- DEBUGGING SETUP ---
$log_file = __DIR__ . '/debug_log.txt';
if (file_exists($log_file)) { unlink($log_file); }
function write_log($message) {
    global $log_file;
    file_put_contents($log_file, "[" . date("Y-m-d H:i:s") . "] " . print_r($message, true) . "\n", FILE_APPEND);
}

write_log("Script update_task_status.php started.");

// Ambil data dari POST atau JSON body
$data = $_POST;
if (empty($data)) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE) ?? [];
}

// Ambil data
$task_id = $data['task_id'] ?? '';
$new_status = $data['new_status'] ?? '';
$assigned_sprint = $data['assigned_sprint'] ?? null;

if (empty(trim($task_id)) || empty(trim($new_status)) || $assigned_sprint === null) {
    sendJsonResponse(400, ["status" => "error", "message" => "Input tidak lengkap."]);
}

try {
    // 1. Ambil info task (Optional, jangan sampai bikin error fatal)
    $taskInfo = null;
    try {
        $stmtInfo = $conn->prepare("
            SELECT t.title, p.user_id, p.name as project_name 
            FROM tasks t 
            JOIN projects p ON t.project_id = p.id 
            WHERE t.id = ?
        ");
        if ($stmtInfo) {
            $stmtInfo->bind_param("i", $task_id);
            $stmtInfo->execute();
            $resultInfo = $stmtInfo->get_result();
            $taskInfo = $resultInfo->fetch_assoc();
            $stmtInfo->close();
        }
    } catch (Exception $e) {
        write_log("Gagal ambil info task: " . $e->getMessage());
        // Lanjut saja, jangan stop proses
    }

    // 2. Update Task (INI WAJIB SUKSES)
    $completion_sprint_to_set = ($new_status === 'done') ? $assigned_sprint : null;
    
    $stmt = $conn->prepare("UPDATE tasks SET status = ?, assigned_sprint = ?, completion_sprint = ? WHERE id = ?");
    if (!$stmt) {
        throw new Exception("Gagal prepare update: " . $conn->error);
    }

    $stmt->bind_param("siis", $new_status, $assigned_sprint, $completion_sprint_to_set, $task_id);
    if (!$stmt->execute()) {
        throw new Exception("Gagal update database: " . $stmt->error);
    }
    $stmt->close();

    // 3. Buat Notifikasi (SAFE MODE: Error di sini tidak boleh rollback update task)
    if ($taskInfo) {
        try {
            $user_id = $taskInfo['user_id'];
            $notifTitle = "Update Status Tugas";
            
            // Format pesan yang lebih informatif (Menyertakan informasi Sprint)
            $sprintInfo = "";
            if ($assigned_sprint) {
                $sprintInfo = " di Sprint $assigned_sprint";
            }
            
            $notifMessage = "Tugas '{$taskInfo['title']}' dipindahkan ke '$new_status'$sprintInfo.";
            
            // Cek dulu apakah tabel notifications ada
            $checkTable = $conn->query("SHOW TABLES LIKE 'notifications'");
            if ($checkTable && $checkTable->num_rows > 0) {
                $stmtNotif = $conn->prepare("INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, 'project_update')");
                if ($stmtNotif) {
                    $stmtNotif->bind_param("iss", $user_id, $notifTitle, $notifMessage);
                    $stmtNotif->execute();
                    $stmtNotif->close();
                }
            } else {
                write_log("Tabel notifications tidak ditemukan. Notifikasi dilewati.");
            }
        } catch (Exception $e) {
            write_log("Gagal buat notifikasi: " . $e->getMessage());
            // Ignore error notifikasi, yang penting task terupdate
        }
    }

    sendJsonResponse(200, ["status" => "success", "message" => "Status tugas berhasil diperbarui."]);

} catch (Exception $e) {
    sendJsonResponse(500, ["status" => "error", "message" => $e->getMessage()]);
} finally {
    if (isset($conn)) $conn->close();
}
?>
