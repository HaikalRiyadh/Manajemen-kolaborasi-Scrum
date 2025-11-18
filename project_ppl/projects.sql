-- ==============================
-- TABEL: projects (Disinkronkan dengan skrip PHP dan Flutter)
-- ==============================
CREATE TABLE `projects` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  -- Kolom Baru yang DIWAJIBKAN oleh skrip PHP/Flutter Anda
  `duration` INT(11) NOT NULL DEFAULT 1, 
  `progress` INT(11) NOT NULL DEFAULT 0, -- Nilai default 0%
  -- Kolom Asli (dipertahankan)
  `description` TEXT,
  `start_date` DATE DEFAULT NULL,
  `end_date` DATE DEFAULT NULL,
  `status` VARCHAR(50) DEFAULT 'active',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

-- Contoh data project
INSERT INTO `projects` (`name`, `duration`, `progress`)
VALUES
('Scrum App Development', 30, 10),
('Marketing Website Revamp', 14, 80);