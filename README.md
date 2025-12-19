# Scrum Management App

Aplikasi manajemen proyek Scrum berbasis mobile yang dibangun menggunakan **Flutter** (Frontend) dan **PHP Native** (Backend).

## 📋 Prasyarat (Prerequisites)

Pastikan Anda telah menginstal software berikut di komputer Anda:
1.  **Flutter SDK** (versi terbaru).
2.  **Android Studio** atau **VS Code** (dengan ekstensi Flutter/Dart).
3.  **Local Server** (XAMPP atau Laragon) yang menjalankan **Apache** dan **MySQL**.
4.  **Git**.

---

## ⚙️ Backend Setup (PHP & Database)

Langkah ini penting agar aplikasi bisa berkomunikasi dengan server dan database.

### 1. Pindahkan Folder API
Salin folder `project_ppl` yang ada di dalam proyek ini ke dalam folder root server lokal Anda.
*   **Laragon:** `C:\laragon\www\`

Struktur akhirnya harus seperti ini:
`C:\laragon\www\project_ppl\` atau `http://localhost/project_ppl/`

### 2. Setup Database
1.  Buka **phpMyAdmin** atau Database Manager (HeidiSQL).
2.  Buat database baru dengan nama: **`lib_scrum_app`**.
3.  Import file database yang telah disediakan:
    *   File terletak di: `project_ppl/projects.sql`.
    *   Jalankan file tersebut untuk membuat tabel `users`, `projects`, dan `tasks`.

### 3. Konfigurasi Koneksi (Opsional)
Jika Anda menggunakan username/password database selain default (`root` / kosong), edit file:
`project_ppl/api_helpers.php`

```php
$servername = "127.0.0.1";
$username_db = "root"; 
$password_db = "";     
$dbname = "lib_scrum_app";
```

---

## 📱 Mobile App Setup (Flutter)

### 1. Install Dependencies
Buka terminal di root folder proyek Flutter, lalu jalankan:

```bash
flutter pub get
```

### 2. Konfigurasi URL API
Aplikasi ini sudah dikonfigurasi untuk mendeteksi lingkungan secara otomatis (Web vs Android Emulator).
*   **Android Emulator:** Menggunakan `10.0.2.2` (IP loopback khusus emulator).
*   **Web / iOS Simulator:** Menggunakan `localhost`.

Jika Anda menggunakan **Device Asli (Fisik)**, Anda perlu mengubah URL di `lib/services/sprint_provider.dart` dan `lib/screens/login_page.dart` menggunakan alamat IP LAN komputer Anda (contoh: `192.168.1.x`).

### 3. Jalankan Aplikasi
Pastikan emulator sudah berjalan atau device terhubung via USB.

```bash
flutter run
```

---

## 🛠 Troubleshooting

**1. Error "Format respons server salah" / "Connection Refused"**
*   Pastikan Apache dan MySQL di XAMPP/Laragon sudah **Start**.
*   Pastikan nama database di phpMyAdmin adalah `lib_scrum_app`.
*   Jika menggunakan Emulator, pastikan bisa mengakses `http://10.0.2.2/project_ppl/get_all_data.php` dari browser emulator.

**2. Login Gagal / Proyek Kosong**
*   Saat pertama kali install, tabel `projects` kosong. Register akun baru, login, lalu buat proyek baru.

---

## 📂 Struktur Folder
*   `lib/` - Kode utama Flutter (UI & Logika).
*   `project_ppl/` - Kode Backend PHP (API).
*   `project_ppl/projects.sql` - Skema Database.
