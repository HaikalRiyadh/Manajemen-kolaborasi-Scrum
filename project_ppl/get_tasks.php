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

include 'db_connect.php'; // Asumsi Anda punya file koneksi

$project_id = isset($_GET['project_id']) ? intval($_GET['project_id']) : null;

try {
    if ($project_id && $project_id > 0) {
        // Prepared statement for filtered query
        $stmt = $conn->prepare("SELECT id, project_id, title, status, story_points FROM tasks WHERE project_id = ? ORDER BY id DESC");
        if ($stmt === false) {
            sendJsonResponse(500, ["status" => "error", "message" => "Gagal menyiapkan statement: " . $conn->error]);
        }
        $stmt->bind_param("i", $project_id);
        $stmt->execute();
        $result = $stmt->get_result();
    } else {
        // No filter: return all tasks
        $sql = "SELECT id, project_id, title, status, story_points FROM tasks ORDER BY id DESC";
        $result = $conn->query($sql);
        if ($result === false) {
            sendJsonResponse(500, ["status" => "error", "message" => "Query gagal: " . $conn->error]);
        }
    }

    $tasks = [];
    if ($result && $result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            // Cast numeric fields to integers for client
            if (isset($row['id'])) $row['id'] = intval($row['id']);
            if (isset($row['project_id'])) $row['project_id'] = intval($row['project_id']);
            if (isset($row['story_points'])) $row['story_points'] = intval($row['story_points']);
            $tasks[] = $row;
        }
    }

    sendJsonResponse(200, ["status" => "success", "data" => $tasks]);

} catch (Exception $e) {
    sendJsonResponse(500, ["status" => "error", "message" => $e->getMessage()]);
} finally {
    if (isset($stmt) && is_object($stmt)) {
        $stmt->close();
    }
    $conn->close();
}

?>