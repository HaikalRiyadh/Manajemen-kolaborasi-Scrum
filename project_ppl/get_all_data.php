<?php
// CORS & headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

function sendJsonResponse($code, $data) {
    http_response_code($code);
    echo json_encode($data);
    exit();
}

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    sendJsonResponse(200, ["status" => "ok"]);
}

include 'db_connect.php'; // Memanggil file koneksi

try {
    // 1. Ambil semua proyek
    $projects_result = $conn->query("SELECT id, name, duration, progress FROM projects ORDER BY id DESC");
    if ($projects_result === false) {
        throw new Exception("Gagal mengambil data proyek: " . $conn->error);
    }

    $projects = [];
    if ($projects_result->num_rows > 0) {
        while($project_row = $projects_result->fetch_assoc()) {
            // Konversi tipe data
            $project_row['id'] = intval($project_row['id']);
            $project_row['duration'] = intval($project_row['duration']);
            $project_row['progress'] = intval($project_row['progress']);

            // Tambahkan array kosong untuk tugas
            $project_row['tasks'] = [];
            $projects[] = $project_row;
        }
    }

    // 2. Ambil tugas untuk setiap proyek
    if (!empty($projects)) {
        // Siapkan statement untuk mengambil tugas berdasarkan project_id
        $stmt_tasks = $conn->prepare("SELECT id, project_id, title, status, story_points, completion_day FROM tasks WHERE project_id = ?");
        if ($stmt_tasks === false) {
            throw new Exception("Gagal menyiapkan statement untuk tugas: " . $conn->error);
        }

        foreach ($projects as &$project) { // Gunakan referensi (&) untuk memodifikasi array secara langsung
            $stmt_tasks->bind_param("i", $project['id']);
            $stmt_tasks->execute();
            $tasks_result = $stmt_tasks->get_result();

            if ($tasks_result->num_rows > 0) {
                while ($task_row = $tasks_result->fetch_assoc()) {
                    // Konversi tipe data tugas
                    $task_row['id'] = intval($task_row['id']);
                    $task_row['project_id'] = intval($task_row['project_id']);
                    $task_row['story_points'] = intval($task_row['story_points']);
                    if (isset($task_row['completion_day'])) {
                        $task_row['completion_day'] = intval($task_row['completion_day']);
                    }
                    $project['tasks'][] = $task_row;
                }
            }
        }
        $stmt_tasks->close();
    }

    sendJsonResponse(200, ["status" => "success", "data" => $projects]);

} catch (Exception $e) {
    sendJsonResponse(500, ["status" => "error", "message" => $e->getMessage()]);
} finally {
    $conn->close();
}
?>