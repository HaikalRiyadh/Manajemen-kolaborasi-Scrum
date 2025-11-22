<?php
// 1. Include the central helper file.
require_once __DIR__ . '/api_helpers.php';

// 2. --- OPERASI DATABASE ---

// Ambil semua proyek. Pastikan query ini benar.
$projects_result = $conn->query("SELECT id, name, sprint, progress FROM projects ORDER BY id ASC");

$projects = [];
if ($projects_result && $projects_result->num_rows > 0) {
    while($project_row = $projects_result->fetch_assoc()) {
        $project_id_str = strval($project_row['id']);

        $project_row['id'] = $project_id_str;
        $project_row['sprint'] = intval($project_row['sprint']);
        $project_row['tasks'] = []; // Siapkan array untuk tugas

        $projects[$project_id_str] = $project_row;
    }
}

// Ambil semua tugas sekaligus untuk efisiensi
$tasks_result = $conn->query("SELECT id, project_id, title, status, story_points, completion_day FROM tasks");
if ($tasks_result && $tasks_result->num_rows > 0) {
    while ($task_row = $tasks_result->fetch_assoc()) {
        $project_id_str = strval($task_row['project_id']);

        if (isset($projects[$project_id_str])) {
            $task_row['id'] = strval($task_row['id']);
            $task_row['project_id'] = $project_id_str;
            $task_row['story_points'] = intval($task_row['story_points']);
            if (isset($task_row['completion_day'])) {
                $task_row['completion_day'] = intval($task_row['completion_day']);
            }
            $projects[$project_id_str]['tasks'][] = $task_row;
        }
    }
}

// Kembalikan array ke format biasa
$final_projects_list = array_values($projects);

sendJsonResponse(200, ["status" => "success", "data" => $final_projects_list]);

?>