# 🏪 PixelMart: Simulator Toko Kelontong

<img width="770" height="615" alt="image" src="https://github.com/user-attachments/assets/c570bc44-c15f-4ecd-b938-929afe610216" />


**PixelMart: Simulator Toko Kelontong** adalah sebuah game simulasi manajemen toko kelontong 2D yang dikembangkan menggunakan **Lazarus / Free Pascal (FPC)**. 

Di dalam game ini, pemain bertindak sebagai pemilik warung yang harus bertahan hidup dalam siklus ekonomi harian. Pemain ditantang untuk mengatur tata letak toko, melakukan kulakan stok barang, menentukan harga jual yang kompetitif, dan menghadapi ratusan pelanggan dengan kecerdasan buatan (AI) yang memiliki toleransi harganya masing-masing.

---

## ✨ Fitur Utama

*   🧠 **Kecerdasan Buatan (Customer AI):** Pelanggan tidak hanya berjalan secara acak. Mereka dibekali *pathfinding* (pencari jalan otomatis), sistem antrean cerdas (anti-macet), dan sistem belanja impulsif (*Impulse Buying*). Mereka bisa marah jika rak kosong ("Yah, Kosong!") atau menolak membeli jika harga Anda tidak masuk akal ("Kemahalan!").
*   📦 **Inventaris Data-Driven & FIFO:** Seluruh master data barang tidak di-*hardcode*, melainkan dimuat secara dinamis dari file `products.csv`. Sistem rak menggunakan logika akuntansi **First-In, First-Out (FIFO)** yang melacak sisa umur kedaluwarsa barang secara presisi.
*   📈 **Buku Besar & Pajak (Ledger):** Game ini memiliki mesin akuntansi internal. Setiap malam, sistem akan menghitung Omzet Bruto, Kerugian (Barang Basi), Beban Operasional (Gaji), dan secara otomatis memotong **Pajak 0.5%** sebelum mencetak Laba Bersih di layar Laporan Keuangan Harian.
*   🏷️ **Dynamic Pricing:** Pemain bebas merubah harga jual kapan saja (*mark-up*) untuk mencari titik ekuilibrium margin keuntungan maksimal melawan toleransi harga pasar.
*   📊 **Live Stock Monitor:** Jendela monitor *real-time* (Non-Modal) yang terus memperbarui sisa ketersediaan barang secara fisik dari detik ke detik layaknya layar CCTV gudang.
*   🎨 **Custom 2D Rendering & Audio:** Mesin render dibangun murni di atas *Canvas* menggunakan *Double-Buffering* (bebas *flicker*), dipadukan dengan pustaka `MMSystem` bawaan Windows untuk efek suara laci kasir dan interaksi secara asinkron (tanpa *lag*).

---

## 🎮 Cara Bermain

1. **Kulakan Barang:** Klik tombol `Stok` di pagi hari untuk membeli barang (klik ganda pada tabel produk).
2. **Atur Harga:** Buka menu `Atur Harga` untuk menentukan margin keuntungan. Jangan terlalu mahal agar pelanggan tidak kabur!
3. **Pantau Warung:** Buka `Monitor Stok` untuk melihat pergerakan barang secara *live*.
4. **Analisis Laba:** Di akhir hari, buka `Buku Besar` untuk melihat rekapitulasi keuangan Anda dan pastikan saldo kas Anda tetap bertumbuh!

---
## Download
Link Download https://github.com/CodeInPas/PixelMart/releases/tag/PixeMart_v01



