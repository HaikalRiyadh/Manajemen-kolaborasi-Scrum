# Kelompok 3 - PPL PRAK I6

**Anggota:**
*   Haikal Riyadh Romadhon - 502510310005
*   Tantri Pradipta Kusumawardani - 502510310007
*   Deviani Trinita - 502510310008
*   Jasmine Mumtaz - 502510310010

---

# Scrum Management App

Aplikasi manajemen proyek Scrum (Mobile) dengan backend PHP Native.

## 🛠 Teknologi

| Kategori | Teknologi |
| :--- | :--- |
| **Frontend** | Flutter (Dart) |
| **Backend** | PHP Native |
| **Database** | MySQL |

## 📋 Prasyarat

1.  Flutter SDK & Android Studio/VS Code.
2.  Local Server (Laragon/XAMPP) dengan MySQL & Apache.
3.  Git.

---

## ⚙️ Setup Backend

1.  **Pindahkan API:** Salin folder `project_ppl` ke `C:\laragon\www\` (Laragon) atau `C:\xampp\htdocs\` (XAMPP).
2.  **Database:**
    *   Buat DB baru: **`lib_scrum_app`**.
    *   Import: `project_ppl/projects.sql`.
3.  **Config DB:** Edit `project_ppl/api_helpers.php` jika user/pass MySQL bukan default (`root`/kosong).

---

## 📱 Setup Frontend

1.  **Install:**
    ```bash
    flutter pub get
    ```
2.  **Config API:**
    *   **Emulator:** `10.0.2.2` (Default).
    *   **Fisik:** Edit IP di `lib/services/sprint_provider.dart` & `lib/screens/login_page.dart`.
3.  **Run:**
    ```bash
    flutter run
    ```

---

## 📂 Direktori

*   `lib/`: Kode Flutter.
*   `project_ppl/`: Backend PHP & SQL.
