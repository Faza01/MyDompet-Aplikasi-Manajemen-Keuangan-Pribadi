# Changelog

Semua perubahan penting pada proyek **MyDompet** akan dicatat di file ini.

## [1.3.0] - 2026-07-09

### Ditambahkan
- **Fitur Hutang & Piutang**: Pengelolaan pinjaman komprehensif dengan dukungan pembayaran/pelunasan cicilan secara parsial (sebagian nominal) dan tanggal tenggat waktu opsional.
- **Integrasi NLP & Asisten Chatbot**: Deteksi otomatis pernyataan pinjaman pada input cepat (NLP Parser) seperti *"hutang ke Budi 50rb"* atau *"pinjamkan ke Andi 100rb"* untuk dicatat langsung ke modul Hutang & Piutang.
- **Pengelola Kata Kunci In-App**: Dialog pengaturan kata kunci pemicu NLP kustom langsung di dalam aplikasi (menggunakan chip interaktif) dengan filter dinamis berbasis tipe kategori aktif.

### Diperbaiki
- **Bebas Efek Kedipan (Zero Flash)**: Mengganti ChoiceChip bawaan Flutter dengan custom `GestureDetector` + `AnimatedContainer` untuk menghilangkan efek kedipan kuning (Android `InkSparkle` shader) pada halaman Hutang & Piutang dan dialog NLP.
- **Optimasi Performa Kategori (Budgeting)**: Refaktorisasi list kata kunci kategori ke family provider `categoryKeywordsProvider` dan isolasi rebuild sub-widget `_KeywordsListWidget` (dilengkapi `RepaintBoundary`) untuk meniadakan lag/stutter saat men-scroll halaman detail anggaran.
- **Pembersihan Repo & Dependensi**: Menghapus dependensi mati `inspire_blur` serta membersihkan berkas ekspor profil DevTools besar (~301.6 MB) dari direktori kerja.

## [1.2.0] - 2026-07-05

### Ditambahkan
- Chatbot untuk input transaksi cepat, termasuk fitur edit pesan langsung
- Redesain dialog edit transaksi dengan aksen garis warna dan editor tanggal-waktu
- Grafik tren keuangan baru: perbandingan pemasukan vs pengeluaran berdampingan dengan tooltip
- Filter tanggal kini pakai modal ringkas, bukan layar penuh, dan bisa diedit manual
- Filter lanjutan (rentang waktu, tipe alokasi, multi-rekening) dengan tampilan bottom sheet baru
- Grafik laporan sekarang interaktif — bisa difilter dan ditoggle langsung dari chart
- Redesain halaman Pengaturan jadi satu kontainer rapi dengan kartu profil di atas
- Redesain dialog tambah/edit dompet, lebih modern dengan pilihan ikon dan warna

### Diperbaiki
- Palet warna kategori diganti jadi lebih soft dan enak dilihat di mode gelap maupun terang
- Opacity background icon kategori dinaikkan sedikit biar lebih jelas
- Icon kategori di dashboard sekarang monokrom, biar tampilan beranda tetap bersih
- Fix bug database bisa duplikat kalau tombol undo di-spam
- Update Flutter SDK di CI ke 3.44.4 + perbaikan proses build rilis otomatis

## [1.1.0] - 2026-07-04

### Ditambahkan
- **Paginasi Riwayat Transaksi**: Navigasi halaman interaktif (`< 1, 2, 3, ... >`) langsung pada dashboard beranda dengan performa scroll konstan 120 FPS.

### Diperbaiki
- **Optimasi Performa Ekstrem**: Menghapus efek shader blur pada navbar untuk memotong beban GPU menjadi 0ms, membatasi daftar transaksi awal hingga 10 transaksi terbaru untuk menghindari bottleneck UI Thread.
- **Revisi & Perbaikan Visual (UI Polish)**:
  - Mengubah warna fokus border input field dan nominal angka preview pemasukan (*income*) menjadi hijau (`0xFF10B981`) di Quick Input.
  - Mengubah warna tombol mic dan centang di sebelah kolom Quick Input menjadi hitam/charcoal.
  - Memperbaiki visibilitas tombol "Simpan Transaksi" (Quick Input) dan "Kirim Transfer" (Kelola Dompet) di mode gelap agar teks terlihat kontras.
  - Menyelaraskan tema Splash Screen Android secara default ke latar belakang putih, melenyapkan efek kedipan kilau saat aplikasi dimuat.

## [1.0.0] - 2026-07-04

### Ditambahkan
- **Estetika Premium Glassmorphism**:
  - Implementasi *Truly Floating Bottom Navbar* berbentuk kapsul melayang dengan aksen bayangan drop shadow yang realistis.
  - Integrasi paket `progressive_blur` berbasis custom shader GLSL untuk memudarkan keburaman (*feathered progressive blur*) secara kontinu dari atas (tajam) ke bawah (buram penuh) tanpa garis pembatas fisik.
  - Dukungan rendering layar penuh (*edge-to-edge*) yang menembus area navigasi sistem Android bawaan dengan membuat status bar dan system navigation bar transparan.
- **Pencatatan Cepat Cerdas (Quick Input NLP)**:
  - Dukungan asisten suara & teks pintar yang mendeteksi nominal uang, kategori, dan deskripsi pengeluaran secara otomatis berbasis pencocokan pola kata kunci asisten.
  - Pemosisian dan visualisasi masukan transaksi cepat yang intuitif.
- **Manajemen Anggaran (Budgeting)**:
  - Kemampuan menetapkan alokasi anggaran belanja bulanan per kategori.
  - Indikator bar progres interaktif yang melacak pengeluaran secara dinamis.
- **Laporan Statistik Visual**:
  - Penambahan visualisasi diagram pai dan diagram batang interaktif per kurun waktu (Hari, Minggu, Bulan, Tahun).
- **SQLite Backup & Restore**:
  - Fitur ekspor basis data lokal ke penyimpanan internal dan impor data cadangan kapan saja.
