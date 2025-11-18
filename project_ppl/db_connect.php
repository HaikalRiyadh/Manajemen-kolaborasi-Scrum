<?php
// Konfigurasi koneksi database untuk Laragon
$servername = "127.0.0.1"; // atau bisa juga "localhost"
$username_db = "root";      // default Laragon user
$password_db = "";          // default Laragon password kosong
$dbname = "lib_scrum_app";  // nama database kamu

// Membuat koneksi ke database
$conn = new mysqli($servername, $username_db, $password_db, $dbname);

// Cek koneksi
if ($conn->connect_error) {
    header('Content-Type: application/json');
    http_response_code(500);
    die(json_encode([
        "status" => "error",
        "message" => "Koneksi ke database gagal: " . $conn->connect_error
    ]));
}

// Set charset agar mendukung UTF-8
$conn->set_charset("utf8mb4");

// (Opsional) tampilkan pesan sukses saat testing
// echo json_encode(["status" => "success", "message" => "Koneksi berhasil"]);
?>
