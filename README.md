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

## Langkah Instalasi

Ikuti langkah-langkah berikut untuk menjalankan proyek secara lokal.

### 1. Clone Repositori

Buka terminal atau command prompt, lalu jalankan:

```bash
git clone https://github.com/HaikalRiyadh/Manajemen-kolaborasi-Scrum
cd project
```

### 2. Konfigurasi Backend (PHP Native)

Salin folder API ke direktori root web server Anda:

*   **Laragon:** Pindahkan folder `project_ppl` ke `C:\laragon\www\`
*   **XAMPP:** Pindahkan folder `project_ppl` ke `C:\xampp\htdocs\`

Setup Database:

1.  Buka **phpMyAdmin** (`http://localhost/phpmyadmin`).
2.  Buat database baru dengan nama: **`lib_scrum_app`**.
3.  Import file database dari: `project_ppl/projects.sql`.

### 3. Konfigurasi Frontend (Flutter)

Masuk ke direktori project flutter, lalu instal dependensi:

```bash
flutter pub get
```

Sesuaikan konfigurasi IP (Jika perlu):

*   **Emulator:** Tidak perlu ubah (Otomatis `10.0.2.2`).
*   **HP Fisik:** Edit IP di `lib/services/sprint_provider.dart` ke IP Laptop Anda.

Jalankan aplikasi:

```bash
flutter run
```

---

## ✨ Fitur Utama

*   🔐 **Auth:** Register, Login, & Logout aman.
*   ⚙️ **Settings:** Kelola akun dan pengaturan aplikasi.
*   🔔 **Notifikasi:** Pemberitahuan aktivitas dan update proyek.
*   📂 **Project:** Mengelola sprint.
*   📊 **Scrum Board:** Kelola status task (To Do, In Progress, Done) & Story Points.

---

## 📂 Struktur Folder
*   `lib/` ➝ Kode Flutter (UI & Logic)
*   `project_ppl/` ➝ Kode Backend PHP & SQL
