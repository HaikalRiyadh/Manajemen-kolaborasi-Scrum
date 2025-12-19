# Kelompok 3 - PPL PRAK I6

### 👥 Anggota Tim
*   **Haikal Riyadh Romadhon** (502510310005)
*   **Tantri Pradipta Kusumawardani** (502510310007)
*   **Deviani Trinita** (502510310008)
*   **Jasmine Mumtaz** (502510310010)

---

# 📱 Scrum Management App

Aplikasi mobile berbasis **Flutter** untuk manajemen proyek Scrum yang kolaboratif dan *multi-user*. Membantu tim mengelola Sprint, Backlog, dan Task secara efisien.

### 🛠️ Tech Stack

| Frontend | Backend | Database | Tools |
| :--- | :--- | :--- | :--- |
| **Flutter** (Dart) | **PHP Native** | **MySQL** | Git, Android Studio/VS Code, Laragon/XAMPP |

---

## 🚀 Panduan Instalasi Cepat

Ikuti langkah-langkah ini secara berurutan agar aplikasi berjalan lancar.

### 1️⃣ Persiapan Backend (Server & Database)

1.  **Salin API:**
    Copy folder `project_ppl` dari proyek ini ke folder root server lokal Anda:
    *   Laragon: `C:\laragon\www\project_ppl\`
    *   XAMPP: `C:\xampp\htdocs\project_ppl\`

2.  **Setup Database:**
    *   Buka **phpMyAdmin**.
    *   Buat database baru bernama: **`lib_scrum_app`**.
    *   Import file **`project_ppl/projects.sql`** ke database tersebut.

3.  **Cek Koneksi:**
    Pastikan server Apache & MySQL sudah **Start**. Akses `http://localhost/project_ppl/` di browser. Jika tidak error 404, backend siap.

### 2️⃣ Persiapan Frontend (Mobile App)

1.  **Install Dependensi:**
    Buka terminal di folder `project/` dan jalankan:
    ```bash
    flutter pub get
    ```

2.  **Pilih Environment (PENTING!):**
    *   🟢 **Emulator Android:** Langsung jalankan (Otomatis pakai IP `10.0.2.2`).
    *   🟢 **Web/iOS Simulator:** Langsung jalankan (Otomatis pakai `localhost`).
    *   ⚠️ **HP Fisik:** Edit IP di `lib/services/sprint_provider.dart` & `lib/screens/login_page.dart` ke IP LAN Laptop Anda (misal `192.168.1.x`).

3.  **Jalankan Aplikasi:**
    ```bash
    flutter run
    ```

---

## ✨ Fitur Utama

*   🔐 **Auth:** Register, Login, & Logout aman.
*   👤 **Profil:** Lihat detail akun pengguna.
*   📂 **Project:** mengelola sprint.
*   📊 **Scrum Board:** Kelola status task (To Do, In Progress, Done) & Story Points.

---

---

## 📂 Struktur Folder
*   `lib/` ➝ Kode Flutter (UI & Logic)
*   `project_ppl/` ➝ Kode Backend PHP & SQL
