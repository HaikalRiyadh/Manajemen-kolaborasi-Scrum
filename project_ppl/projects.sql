-- ==============================
-- TABEL: users (DIBUTUHKAN UNTUK REGISTER & LOGIN)
-- ==============================
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL, -- Akan menyimpan hash password
  `full_name` VARCHAR(100) NOT NULL,
  `role` VARCHAR(20) DEFAULT 'user',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

-- ==============================
-- TABEL: projects (Disinkronkan dengan skrip PHP dan Flutter)
-- ==============================
CREATE TABLE IF NOT EXISTS `projects` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `user_id` INT(11) NOT NULL, -- Pemilik Proyek
  `name` VARCHAR(255) NOT NULL,
  `sprint` INT(11) NOT NULL DEFAULT 1, 
  `current_sprint` INT(11) NOT NULL DEFAULT 1,
  `progress` INT(11) NOT NULL DEFAULT 0, 
  `description` TEXT,
  `start_date` DATE DEFAULT NULL,
  `end_date` DATE DEFAULT NULL,
  `status` VARCHAR(50) DEFAULT 'active',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
);

-- ==============================
-- TABEL: tasks (UNTUK SCRUM BOARD)
-- ==============================
CREATE TABLE IF NOT EXISTS `tasks` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `project_id` INT(11) NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `story_points` INT(11) DEFAULT 0,
  `status` ENUM('backlog', 'toDo', 'inProgress', 'done') DEFAULT 'backlog',
  `assigned_sprint` INT(11) DEFAULT NULL,
  `completion_sprint` INT(11) DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`project_id`) REFERENCES `projects`(`id`) ON DELETE CASCADE
);

-- ==============================
-- TABEL: notifications (BARU)
-- ==============================
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
