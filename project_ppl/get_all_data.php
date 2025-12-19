<?php

require_once __DIR__ . '/api_helpers.php';

// Ambil user_id dari parameter GET
$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

if ($user_id <= 0) {
    // Jika tidak ada user_id, kembalikan list kosong (keamanan)
    sendJsonResponse(200, ["status" => "success", "data" => []]);
}

// --- Ambil Proyek Milik User Tersebut ---
// Gunakan Prepared Statement untuk keamanan
$stmt = $conn->prepare("SELECT id, name, sprint, current_sprint FROM projects WHERE user_id = ? ORDER BY id ASC");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$projects_result = $stmt->get_result();

$projects = [];
if ($projects_result && $projects_result->num_rows > 0) {
    while($project_row = $projects_result->fetch_assoc()) {
        $project_id = $project_row['id'];
        $projects[$project_id] = [
            'id' => $project_id,
            'name' => $project_row['name'],
            'sprint' => intval($project_row['sprint']),
            'current_sprint' => intval($project_row['current_sprint']),
            'tasks' => [], // Inisialisasi array tugas
        ];
    }
}
$stmt->close();

// Jika user tidak punya proyek, langsung kembalikan array kosong
if (empty($projects)) {
    sendJsonResponse(200, ["status" => "success", "data" => []]);
}

// --- Ambil Tugas ---
// Kita hanya perlu mengambil tugas yang project_id-nya ada di daftar proyek milik user ini
// Cara efisien: Gunakan WHERE IN (...)
$project_ids = array_keys($projects);
$ids_placeholder = implode(',', array_fill(0, count($project_ids), '?'));
$types = str_repeat('i', count($project_ids));

$tasks_sql = "SELECT id, project_id, title, status, story_points, assigned_sprint, completion_sprint FROM tasks WHERE project_id IN ($ids_placeholder)";
$stmt_tasks = $conn->prepare($tasks_sql);
$stmt_tasks->bind_param($types, ...$project_ids);
$stmt_tasks->execute();
$tasks_result = $stmt_tasks->get_result();

if ($tasks_result && $tasks_result->num_rows > 0) {
    while ($task_row = $tasks_result->fetch_assoc()) {
        $project_id = $task_row['project_id'];

        if (isset($projects[$project_id])) {
            $projects[$project_id]['tasks'][] = [
                'id' => $task_row['id'],
                'title' => $task_row['title'],
                'status' => $task_row['status'],
                'story_points' => intval($task_row['story_points']),
                'assigned_sprint' => $task_row['assigned_sprint'] !== null ? intval($task_row['assigned_sprint']) : null,
                'completion_sprint' => $task_row['completion_sprint'] !== null ? intval($task_row['completion_sprint']) : null,
            ];
        }
    }
}
$stmt_tasks->close();

// Ubah dari associative array menjadi list biasa
$final_projects_list = array_values($projects);

sendJsonResponse(200, ["status" => "success", "data" => $final_projects_list]);

?>