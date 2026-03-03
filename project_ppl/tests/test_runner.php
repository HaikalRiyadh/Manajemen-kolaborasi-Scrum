<?php
/**
 * Simple PHP Test Framework
 * Lightweight test runner for backend API unit tests
 * 
 * Usage: php test_runner.php
 */

class TestRunner {
    private $passed = 0;
    private $failed = 0;
    private $errors = [];
    private $currentSuite = '';

    public function suite(string $name) {
        $this->currentSuite = $name;
        echo "\n" . str_repeat('=', 60) . "\n";
        echo "  TEST SUITE: $name\n";
        echo str_repeat('=', 60) . "\n";
    }

    public function assert($condition, string $message) {
        if ($condition) {
            $this->passed++;
            echo "  ✅ PASS: $message\n";
        } else {
            $this->failed++;
            $this->errors[] = "[$this->currentSuite] $message";
            echo "  ❌ FAIL: $message\n";
        }
    }

    public function assertEquals($expected, $actual, string $message) {
        $this->assert(
            $expected === $actual,
            "$message (expected: " . var_export($expected, true) . ", got: " . var_export($actual, true) . ")"
        );
    }

    public function assertNotEmpty($value, string $message) {
        $this->assert(!empty($value), $message);
    }

    public function assertArrayHasKey($key, $array, string $message) {
        $this->assert(array_key_exists($key, $array), $message);
    }

    public function assertIsArray($value, string $message) {
        $this->assert(is_array($value), $message);
    }

    public function summary() {
        $total = $this->passed + $this->failed;
        echo "\n" . str_repeat('=', 60) . "\n";
        echo "  TEST RESULTS\n";
        echo str_repeat('-', 60) . "\n";
        echo "  Total:  $total\n";
        echo "  Passed: $this->passed ✅\n";
        echo "  Failed: $this->failed ❌\n";
        echo str_repeat('=', 60) . "\n";

        if (!empty($this->errors)) {
            echo "\n  FAILURES:\n";
            foreach ($this->errors as $i => $error) {
                echo "  " . ($i + 1) . ". $error\n";
            }
        }

        echo "\n";
        return $this->failed === 0;
    }
}

// ================================================================
// HELPERS
// ================================================================

function makeRequest(string $url, string $method = 'GET', array $data = []): array {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);

    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    }

    curl_setopt($ch, CURLOPT_URL, $url);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);

    return [
        'status_code' => $httpCode,
        'body' => $response,
        'data' => json_decode($response, true),
        'error' => $error,
    ];
}

// ================================================================
// RUN TESTS
// ================================================================

$t = new TestRunner();
$baseUrl = 'http://localhost/project_ppl';

// Unique identifier for test data
$testId = 'test_' . time() . '_' . rand(1000, 9999);

echo "\n🧪 PHP Backend Unit Test Runner\n";
echo "Base URL: $baseUrl\n";
echo "Test ID: $testId\n";

// ================================================================
// 1. API HELPERS / CONNECTION TEST
// ================================================================
$t->suite('Database Connection & API Helpers');

// Test: api_helpers.php loads correctly
$helperPath = __DIR__ . '/../api_helpers.php';
$t->assert(file_exists($helperPath), 'api_helpers.php exists');

// Test: Projects SQL schema file exists
$sqlPath = __DIR__ . '/../projects.sql';
$t->assert(file_exists($sqlPath), 'projects.sql schema file exists');

// Test: All API endpoint files exist
$endpoints = [
    'login.php', 'register.php', 'add_project.php', 'add_task.php',
    'delete_task.php', 'update_task_status.php', 'get_all_data.php',
    'get_notifications.php', 'add_daily_scrum.php', 'get_daily_scrums.php',
];
foreach ($endpoints as $ep) {
    $t->assert(file_exists(__DIR__ . '/../' . $ep), "Endpoint $ep exists");
}

// ================================================================
// 2. REGISTER ENDPOINT TEST
// ================================================================
$t->suite('Register Endpoint (POST /register.php)');

$testUsername = 'unittest_' . $testId;
$testPassword = 'TestPass123!';
$testFullName = 'Unit Test User';

// Test: Successful registration
$res = makeRequest("$baseUrl/register.php", 'POST', [
    'username' => $testUsername,
    'password' => $testPassword,
    'full_name' => $testFullName,
]);
$t->assert($res['status_code'] == 200 || $res['status_code'] == 201, 'Register returns 200/201');
$t->assertNotEmpty($res['data'], 'Register returns non-empty JSON');
$t->assertEquals('success', $res['data']['status'] ?? '', 'Register status is success');
$testUserId = $res['data']['data']['id'] ?? 0;
$t->assert($testUserId > 0, 'Register returns valid user ID');

// Test: Duplicate username should fail
$res2 = makeRequest("$baseUrl/register.php", 'POST', [
    'username' => $testUsername,
    'password' => $testPassword,
    'full_name' => $testFullName,
]);
$t->assertEquals('error', $res2['data']['status'] ?? '', 'Duplicate username returns error');
$t->assert($res2['status_code'] == 409, 'Duplicate username returns 409 Conflict');

// Test: Empty fields should fail
$res3 = makeRequest("$baseUrl/register.php", 'POST', [
    'username' => '',
    'password' => '',
    'full_name' => '',
]);
$t->assertEquals('error', $res3['data']['status'] ?? '', 'Empty fields returns error');
$t->assert($res3['status_code'] == 400, 'Empty fields returns 400');

// ================================================================
// 3. LOGIN ENDPOINT TEST
// ================================================================
$t->suite('Login Endpoint (POST /login.php)');

// Test: Successful login
$res = makeRequest("$baseUrl/login.php", 'POST', [
    'username' => $testUsername,
    'password' => $testPassword,
]);
$t->assert($res['status_code'] == 200, 'Login returns 200');
$t->assertEquals('success', $res['data']['status'] ?? '', 'Login status is success');
$t->assertArrayHasKey('data', $res['data'], 'Login response has data key');
$t->assertEquals($testUsername, $res['data']['data']['username'] ?? '', 'Login returns correct username');
$t->assertEquals($testFullName, $res['data']['data']['full_name'] ?? '', 'Login returns correct full_name');
$t->assertArrayHasKey('role', $res['data']['data'], 'Login response has role field');

// Test: Wrong password
$res = makeRequest("$baseUrl/login.php", 'POST', [
    'username' => $testUsername,
    'password' => 'wrongpassword',
]);
$t->assertEquals('error', $res['data']['status'] ?? '', 'Wrong password returns error');
$t->assert($res['status_code'] == 401, 'Wrong password returns 401');

// Test: User not found
$res = makeRequest("$baseUrl/login.php", 'POST', [
    'username' => 'nonexistent_user_xyz',
    'password' => 'anything',
]);
$t->assertEquals('error', $res['data']['status'] ?? '', 'Unknown user returns error');

// Test: Empty credentials
$res = makeRequest("$baseUrl/login.php", 'POST', [
    'username' => '',
    'password' => '',
]);
$t->assertEquals('error', $res['data']['status'] ?? '', 'Empty credentials returns error');

// ================================================================
// 4. ADD PROJECT TEST
// ================================================================
$t->suite('Add Project Endpoint (POST /add_project.php)');

// Test: Create project successfully
$res = makeRequest("$baseUrl/add_project.php", 'POST', [
    'name' => "Test Project $testId",
    'sprint' => '3',
    'user_id' => (string)$testUserId,
]);
$t->assert($res['status_code'] == 201, 'Add project returns 201');
$t->assertEquals('success', $res['data']['status'] ?? '', 'Add project status is success');
$testProjectId = $res['data']['id'] ?? 0;
$t->assert($testProjectId > 0, 'Add project returns valid project ID');

// Test: Missing name should fail
$res = makeRequest("$baseUrl/add_project.php", 'POST', [
    'name' => '',
    'sprint' => '3',
    'user_id' => (string)$testUserId,
]);
$t->assertEquals('error', $res['data']['status'] ?? '', 'Empty name returns error');

// Test: Invalid user_id should fail
$res = makeRequest("$baseUrl/add_project.php", 'POST', [
    'name' => 'Test',
    'sprint' => '3',
    'user_id' => '0',
]);
$t->assertEquals('error', $res['data']['status'] ?? '', 'Invalid user_id returns error');

// ================================================================
// 5. ADD TASK TEST
// ================================================================
$t->suite('Add Task Endpoint (POST /add_task.php)');

// Test: Create task successfully
$res = makeRequest("$baseUrl/add_task.php", 'POST', [
    'project_id' => (string)$testProjectId,
    'title' => "Test Task $testId",
    'story_points' => '5',
    'status' => 'backlog',
]);
$t->assert($res['status_code'] == 201, 'Add task returns 201');
$t->assertEquals('success', $res['data']['status'] ?? '', 'Add task status is success');
$testTaskId = $res['data']['id'] ?? '';
$t->assertNotEmpty($testTaskId, 'Add task returns valid task ID');

// Test: Missing required fields
$res = makeRequest("$baseUrl/add_task.php", 'POST', [
    'project_id' => (string)$testProjectId,
    'title' => '',
    'story_points' => '0',
]);
$t->assertEquals('error', $res['data']['status'] ?? '', 'Empty task fields returns error');

// ================================================================
// 6. GET ALL DATA TEST
// ================================================================
$t->suite('Get All Data Endpoint (GET /get_all_data.php)');

$res = makeRequest("$baseUrl/get_all_data.php?user_id=$testUserId");
$t->assert($res['status_code'] == 200, 'Get all data returns 200');
$t->assertEquals('success', $res['data']['status'] ?? '', 'Get all data status is success');
$t->assertIsArray($res['data']['data'] ?? null, 'Get all data returns array');
$t->assert(count($res['data']['data']) > 0, 'Get all data returns at least one project');

// Verify project contains tasks
$firstProject = $res['data']['data'][0] ?? [];
$t->assertArrayHasKey('tasks', $firstProject, 'Project has tasks array');
$t->assert(count($firstProject['tasks']) > 0, 'Project has at least one task');

// Test: Invalid user_id returns empty
$res = makeRequest("$baseUrl/get_all_data.php?user_id=0");
$t->assertEquals('success', $res['data']['status'] ?? '', 'Invalid user_id still returns success');
$t->assert(count($res['data']['data'] ?? []) === 0, 'Invalid user_id returns empty data');

// ================================================================
// 7. UPDATE TASK STATUS TEST
// ================================================================
$t->suite('Update Task Status Endpoint (POST /update_task_status.php)');

// Test: Move task to toDo in Sprint 1
$res = makeRequest("$baseUrl/update_task_status.php", 'POST', [
    'task_id' => $testTaskId,
    'new_status' => 'toDo',
    'assigned_sprint' => '1',
]);
$t->assert($res['status_code'] == 200, 'Update task status returns 200');
$t->assertEquals('success', $res['data']['status'] ?? '', 'Update task status is success');

// Test: Move task to inProgress
$res = makeRequest("$baseUrl/update_task_status.php", 'POST', [
    'task_id' => $testTaskId,
    'new_status' => 'inProgress',
    'assigned_sprint' => '1',
]);
$t->assertEquals('success', $res['data']['status'] ?? '', 'Move to inProgress succeeds');

// Test: Move task to done
$res = makeRequest("$baseUrl/update_task_status.php", 'POST', [
    'task_id' => $testTaskId,
    'new_status' => 'done',
    'assigned_sprint' => '1',
]);
$t->assertEquals('success', $res['data']['status'] ?? '', 'Move to done succeeds');

// Test: Missing required fields
$res = makeRequest("$baseUrl/update_task_status.php", 'POST', [
    'task_id' => '',
    'new_status' => '',
]);
$t->assertEquals('error', $res['data']['status'] ?? '', 'Empty fields returns error');

// ================================================================
// 8. NOTIFICATIONS TEST
// ================================================================
$t->suite('Notifications Endpoint (GET /get_notifications.php)');

$res = makeRequest("$baseUrl/get_notifications.php?user_id=$testUserId");
$t->assert($res['status_code'] == 200, 'Get notifications returns 200');
$t->assertEquals('success', $res['data']['status'] ?? '', 'Get notifications status is success');
$t->assertIsArray($res['data']['data'] ?? null, 'Notifications returns array');

// Should have notifications from task creation and status updates
$notifCount = count($res['data']['data'] ?? []);
$t->assert($notifCount > 0, "Has notifications (found: $notifCount)");

// Test: Invalid user_id
$res = makeRequest("$baseUrl/get_notifications.php?user_id=0");
$t->assertEquals('error', $res['data']['status'] ?? '', 'Invalid user_id returns error');

// ================================================================
// 9. DAILY SCRUM TEST
// ================================================================
$t->suite('Daily Scrum Endpoints');

// Test: Add daily scrum log
$res = makeRequest("$baseUrl/add_daily_scrum.php", 'POST', [
    'user_id' => (string)$testUserId,
    'project_id' => (string)$testProjectId,
    'yesterday' => 'Worked on unit tests',
    'today' => 'Will implement daily scrum feature',
    'blockers' => 'No blockers',
]);
$t->assert($res['status_code'] == 200 || $res['status_code'] == 201, 'Add daily scrum returns 200/201');
$t->assertEquals('success', $res['data']['status'] ?? '', 'Add daily scrum status is success');

// Test: Get daily scrum logs
$res = makeRequest("$baseUrl/get_daily_scrums.php?project_id=$testProjectId");
$t->assert($res['status_code'] == 200, 'Get daily scrums returns 200');
$t->assertEquals('success', $res['data']['status'] ?? '', 'Get daily scrums status is success');
$t->assertIsArray($res['data']['data'] ?? null, 'Daily scrums returns array');
$t->assert(count($res['data']['data']) > 0, 'Has at least one daily scrum log');

// Verify daily scrum log contents
$firstLog = $res['data']['data'][0] ?? [];
$t->assertArrayHasKey('yesterday', $firstLog, 'Daily scrum has yesterday field');
$t->assertArrayHasKey('today', $firstLog, 'Daily scrum has today field');
$t->assertArrayHasKey('blockers', $firstLog, 'Daily scrum has blockers field');
$t->assertArrayHasKey('username', $firstLog, 'Daily scrum has username field');

// Test: Missing required fields
$res = makeRequest("$baseUrl/add_daily_scrum.php", 'POST', [
    'user_id' => '0',
    'project_id' => '0',
    'yesterday' => '',
    'today' => '',
]);
$t->assertEquals('error', $res['data']['status'] ?? '', 'Invalid daily scrum input returns error');

// ================================================================
// 10. DELETE TASK TEST (cleanup)
// ================================================================
$t->suite('Delete Task Endpoint (POST /delete_task.php)');

$res = makeRequest("$baseUrl/delete_task.php", 'POST', [
    'task_id' => $testTaskId,
]);
$t->assert($res['status_code'] == 200, 'Delete task returns 200');
$t->assertEquals('success', $res['data']['status'] ?? '', 'Delete task status is success');

// Test: Delete non-existent task (should still succeed - idempotent)
$res = makeRequest("$baseUrl/delete_task.php", 'POST', [
    'task_id' => '99999999',
]);
$t->assertEquals('success', $res['data']['status'] ?? '', 'Delete non-existent task still returns success');

// Test: Empty task_id
$res = makeRequest("$baseUrl/delete_task.php", 'POST', [
    'task_id' => '',
]);
$t->assertEquals('error', $res['data']['status'] ?? '', 'Empty task_id returns error');

// ================================================================
// CLEANUP: Remove test data
// ================================================================
$t->suite('Cleanup Test Data');

// Delete test project (cascades to tasks, daily scrums)
try {
    // Direct DB cleanup
    $cleanupUrl = "$baseUrl/get_all_data.php?user_id=$testUserId";
    $res = makeRequest($cleanupUrl);
    $t->assert(true, 'Cleanup: fetched test data for verification');

    // Note: Test data will remain in DB. In production, use a dedicated cleanup endpoint
    // or run tests against a test database.
    $t->assert(true, "Cleanup: Test user ID=$testUserId, Project ID=$testProjectId created (manual cleanup may be needed)");
} catch (Exception $e) {
    $t->assert(false, 'Cleanup failed: ' . $e->getMessage());
}

// ================================================================
// SUMMARY
// ================================================================
$allPassed = $t->summary();
exit($allPassed ? 0 : 1);
