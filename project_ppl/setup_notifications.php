<?php
require_once __DIR__ . '/api_helpers.php';

$sql = "
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `user_id` INT(11) NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `message` TEXT NOT NULL,
  `type` VARCHAR(50) DEFAULT 'info',
  `is_read` TINYINT(1) DEFAULT 0,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
);
";

try {
    if ($conn->query($sql) === TRUE) {
        echo "<h1>Berhasil!</h1>";
        echo "<p>Tabel <b>notifications</b> berhasil dibuat.</p>";
        echo "<p>Sekarang Anda bisa menggunakan fitur Drag & Drop dan Notifikasi.</p>";
    } else {
        echo "<h1>Gagal</h1>";
        echo "<p>Error: " . $conn->error . "</p>";
    }
} catch (Exception $e) {
    echo "<h1>Error</h1>";
    echo "<p>" . $e->getMessage() . "</p>";
}
?>
