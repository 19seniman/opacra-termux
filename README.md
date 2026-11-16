# Opacra mining di Termux

Menambang **OPCA** (Opacra) dari HP Android lewat Termux. Semua langkah di bawah sudah diuji
sampai miner benar-benar berjalan dan pool menerima share.

> **Baca dulu:** OPCA baru diluncurkan (mainnet 8 November 2026) dan pasarnya masih sangat muda.
> **MARKET PENJUALAN** — OPCA/USDT di NeoxEX: https://neoxa.exchange/register?ref=NEXFEC4ACFC
>
> Pada 16 November 2026 harganya sekitar **$0,42**, rentang 24 jam $0,106–$1,00, dan perubahan
> **−58%** dalam sehari. Harganya ada, tetapi likuiditasnya tipis: jangan jadikan hasil mining
> sebagai penghasilan tetap, dan jangan jalankan di HP sehari-hari karena RandomX memakai CPU
> 100% terus-menerus.

---

## Kenapa harus build dari source

Semua rilis resmi Opacra hanya untuk **x86-64**, sementara Termux di HP adalah **aarch64**:

| Berkas rilis | Arsitektur |
|---|---|
| `opacra-v1.0.1-linux-x64.tar.gz` | x86-64 |
| `opacra-xmrig-…-linux-x64.tar.gz` | x86-64 |

Dan algoritmanya bukan RandomX standar — Opacra memakai `rx/opca`, jadi XMRig biasa juga tidak
bisa. Yang dipakai di sini adalah XMRig v6.26.0 + patch resmi Opacra, dibangun di HP.

Repo `opacra/opacra-xmrig` **bukan** fork berisi source — isinya hanya patch dan skrip build
Ubuntu. Karena itu langkah 4 di bawah meng-clone XMRig dari upstream, bukan dari repo itu.

## Yang dibutuhkan

| | Minimum |
|---|---|
| Android | 64-bit (arm64), Android 8+ |
| Termux | dari **F-Droid** — jangan dari Play Store |
| RAM | 3 GB (mode hemat memori wajib di bawah 4 GB) |
| Storage | ±2,5 GB untuk source + build |
| Listrik | colok charger selama build dan mining |

---

## Mulai cepat

Kalau semua prasyarat sudah ada, ini intinya:

```bash
pkg install -y git cmake make clang pkg-config openssl libuv
echo 'Pa...alamatmu' > ~/mainnet-address.txt
git clone --depth 1 --branch v6.26.0 https://github.com/xmrig/xmrig.git ~/xmrig
cd ~/xmrig && git apply <(curl -sL https://raw.githubusercontent.com/opacra/opacra-xmrig/main/opacra-xmrig.patch)
mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release -DWITH_HWLOC=OFF -DWITH_OPENCL=OFF -DWITH_CUDA=OFF && make -j1
./xmrig -o pool.opacra.org:4242 -a rx/opca -u "$(cat ~/mainnet-address.txt)" -p termux -k --threads 2 --randomx-mode=light
```

Sisanya di bawah ini menjelaskan tiap langkah beserta cara memverifikasinya.

---

## 1. Pasang Termux

Ambil dari **[F-Droid](https://f-droid.org/packages/com.termux/)**. Versi Play Store memakai
paket usang dan akan gagal di tahap build.

```bash
pkg update -y && pkg upgrade -y
```

Kalau ditanya soal config file, jawab `Y`.

## 2. Pasang alat build

```bash
pkg install -y git cmake make clang pkg-config openssl libuv
```

## 3. Simpan alamat wallet

Sekali saja. Alamat ini yang menerima semua koin:

```bash
echo 'Pa2TYWPjtq5ExMeZhNB3BRCdUY78DF9gNbMTML6LSznzdGioWn4Ah2hAMfF1oovobV7Gc8ThcprCSRScJUwHGj5t9dBoDfmitH' > ~/mainnet-address.txt
```

Ganti dengan alamatmu sendiri. Bentuk yang benar: **98 karakter**, diawali `Pa`.

Alamat adalah data publik (seperti nomor rekening) dan aman dibagikan. Yang **tidak boleh**
dibagikan adalah 25 kata seed wallet-mu — tidak ada layanan sah yang memintanya.

Belum punya alamat? Cara membuatnya di HP ada di **[WALLET.md](WALLET.md)**.

## 4. Ambil source dan tempel patch

```bash
cd ~
git clone --depth 1 --branch v6.26.0 https://github.com/xmrig/xmrig.git
cd xmrig
git rev-parse HEAD
```

Output wajib:

```
b2ca72480c58d197e18c885d9fc1a0c8d517e60a
```

Kalau berbeda, berhenti: tag di upstream sudah bergeser dan patch belum tentu cocok.

```bash
curl -sL https://raw.githubusercontent.com/opacra/opacra-xmrig/main/opacra-xmrig.patch -o opacra-xmrig.patch
git apply opacra-xmrig.patch
sed -i 's/kDefaultDonateLevel = 1;/kDefaultDonateLevel = 0;/' src/donate.h
sed -i 's/kMinimumDonateLevel = 1;/kMinimumDonateLevel = 0;/' src/donate.h
```

Dua `sed` terakhir menyetel donasi ke 0%, sama seperti build resmi Opacra.

## 5. Build

```bash
cd ~/xmrig
rm -rf build && mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DWITH_HWLOC=OFF -DWITH_OPENCL=OFF -DWITH_CUDA=OFF
make -j1
```

**Tiga flag itu saja.** `WITH_HWLOC=OFF` wajib karena paket hwloc di Termux tidak menyertakan
file development yang dicari CMake. OpenCL dan CUDA mati karena HP tidak punya perangkatnya.

Flag tambahan seperti `-DWITH_TLS=OFF`, `-DCMAKE_POLICY_VERSION_MINIMUM`, atau
`-DCMAKE_EXE_LINKER_FLAGS` **merusak** tahap configure/link di Termux — jangan ditambahkan.

Tanda selesai:

```
[100%] Linking CXX executable xmrig
[100%] Built target xmrig
```

Waktu: 20–25 menit. Tutup aplikasi lain dan colok charger; tahap link butuh ±1 GB RAM.

## 6. Jalankan

```bash
termux-wake-lock
cd ~/xmrig/build
./xmrig -o pool.opacra.org:4242 -a rx/opca -u "$(cat ~/mainnet-address.txt)" -p termux -k --threads 2 --randomx-mode=light --no-color
```

Di pengaturan Android: **Apps → Termux → Battery → Unrestricted**, supaya prosesnya tidak
dibunuh saat layar mati.

`--randomx-mode=light` **wajib** di HP di bawah 4 GB RAM. Mode normal memesan 2,3 GB dataset
RandomX, dan Android akan mematikan prosesnya.

## 7. Membaca layarnya

| Baris | Arti |
|---|---|
| `use pool pool.opacra.org:4242` | tersambung |
| `new job … algo rx/opca height …` | pool mengirim pekerjaan, alamat diterima |
| `accepted (N/0)` | share diterima — hashrate dihitung |
| `DONATE 0%` | patch donasi aktif |
| `speed 10s/60s/15m … H/s` | hashrate (tekan `h`) |

Tombol di layar miner: `h` hashrate · `p` pause · `r` resume · `q` keluar.

## 8. Cek hasil

```
https://pool.opacra.org/#ALAMATMU
```

Saldo dan share tampil di sana. Payout pertama setelah mencapai **0,33 OPCA**.

## 9. Mulai lagi besok

```bash
termux-wake-lock
cd ~/xmrig/build && ./xmrig -o pool.opacra.org:4242 -a rx/opca -u "$(cat ~/mainnet-address.txt)" -p termux -k --threads 2 --randomx-mode=light --no-color
```

---

## 10. PC, Windows, dan VPS

Build dari source **hanya dibutuhkan di ARM**. Di x86-64 miner sudah tersedia sebagai binary
siap pakai, jadi tidak ada compile sama sekali.

### 10.1 Alamat wallet — sama untuk semua platform

Alamat dimasukkan **saat menjalankan miner**, lewat parameter `-u`. Tidak ada file konfigurasi
yang perlu diedit.

Simpan sekali supaya tidak mengetik 98 karakter berulang kali:

```bash
echo 'Pa2TYWPjtq5ExMeZhNB3BRCdUY78DF9gNbMTML6LSznzdGioWn4Ah2hAMfF1oovobV7Gc8ThcprCSRScJUwHGj5t9dBoDfmitH' > ~/mainnet-address.txt
```

Ganti dengan alamatmu. Bentuk benar: 98 karakter, diawali `Pa`. Alamat aman dibagikan; yang
**tidak boleh** dibagikan adalah 25 kata seed wallet.

### 10.2 Linux x64 — PC, laptop, atau VPS

**Langkah 1 — unduh miner**

```bash
mkdir -p ~/opacra && cd ~/opacra
curl -sLO https://github.com/opacra/opacra-xmrig/releases/download/v1.0.0/opacra-xmrig-6.26.0-opacra-1.0.0-linux-x64.tar.gz
```

**Langkah 2 — verifikasi checksum** (jangan dilewati, ini binary yang akan jalan di mesinmu)

```bash
sha256sum opacra-xmrig-6.26.0-opacra-1.0.0-linux-x64.tar.gz
```

Harus keluar persis:

```
810eaaa8364bb4743145a1ced64f95f00fcfae516262d1d4e721e5f5b6129960
```

Nilai itu bisa dicocokkan dengan `SHA256SUMS-xmrig-v1.0.0.asc` yang ditandatangani kunci rilis
Opacra (fingerprint `D861 7219 6FEC AAB6 84F5 B3FD CB65 D212 D0B1 162B`).

**Langkah 3 — ekstrak**

```bash
tar -xzf opacra-xmrig-6.26.0-opacra-1.0.0-linux-x64.tar.gz
cd opacra-xmrig-6.26.0-opacra-1.0.0-linux-x64
./xmrig --version
```

`--version` harus menampilkan `XMRig 6.26.0`. Isi paket cuma tiga file: `LICENSE`,
`README.txt`, dan `xmrig`.

**Langkah 4 — jalankan di depan (untuk tes)**

```bash
./xmrig -o pool.opacra.org:4242 -a rx/opca -u "$(cat ~/mainnet-address.txt)" -p pc -k
```

Tanda berhasil: `use pool pool.opacra.org:4242`, lalu `accepted`. Tekan `h` untuk hashrate,
`q` untuk keluar.

**Langkah 5 — jalankan di background (khusus VPS)**

Kalau sesi SSH ditutup, miner ikut mati. Dua cara:

*Cara cepat, pakai `screen`:*

```bash
sudo apt install -y screen        # sekali saja
screen -S opacra
./xmrig -o pool.opacra.org:4242 -a rx/opca -u "$(cat ~/mainnet-address.txt)" -p vps -k
# lepas layar: Ctrl-A lalu D
# masuk lagi: screen -r opacra
```

*Cara permanen, pakai systemd:*

```bash
sudo tee /etc/systemd/system/opacra-miner.service >/dev/null <<EOF
[Unit]
Description=Opacra miner
After=network-online.target

[Service]
ExecStart=/root/opacra/opacra-xmrig-6.26.0-opacra-1.0.0-linux-x64/xmrig -o pool.opacra.org:4242 -a rx/opca -u $(cat ~/mainnet-address.txt) -p vps -k
Restart=always
RestartSec=10
Nice=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now opacra-miner
sudo systemctl status opacra-miner --no-pager
```

Lihat log: `journalctl -u opacra-miner -f` · Hentikan: `sudo systemctl stop opacra-miner`

Sesuaikan `/root/opacra/...` kalau kamu bukan root — ganti dengan `$HOME/opacra/...`.

### 10.3 Windows

**Langkah 1** — unduh
`opacra-xmrig-6.26.0-opacra-1.0.0-win-x64.zip`, ekstrak ke folder, misal `C:\opacra`.
Checksum SHA-256 yang benar: `9e900765326ff9a9f17ab6d8e46ee9d93ce37e4f6d50a5601e21d8cfb553934b`

**Langkah 2** — izinkan folder di Defender. Ini wajib: Defender memblokir semua miner, bukan
hanya yang ini. Buka **Windows Security → Virus & threat protection → Manage settings →
Exclusions → Add folder** → pilih `C:\opacra`.

**Langkah 3** — buka PowerShell di folder itu (Shift + klik kanan → *Open PowerShell here*),
lalu tes:

```powershell
.\xmrig.exe -o pool.opacra.org:4242 -a rx/opca -u "Pa...alamatmu" -p pc -k
```

**Langkah 4** — kalau sudah jalan, buat `mulai.bat` di folder yang sama supaya tidak perlu
mengetik ulang:

```bat
@echo off
cd /d %~dp0
xmrig.exe -o pool.opacra.org:4242 -a rx/opca -u "Pa...alamatmu" -p pc -k
pause
```

Klik dua kali `mulai.bat` untuk mulai mining.

### 10.4 Linux ARM — Raspberry Pi atau VPS ARM

Sama seperti Termux, tetapi dengan `apt` dan tanpa keanehan Termux:

```bash
sudo apt update && sudo apt install -y git cmake make g++ pkg-config libssl-dev libuv1-dev libhwloc-dev
git clone --depth 1 -b v6.26.0 https://github.com/xmrig/xmrig.git && cd xmrig
git rev-parse HEAD    # harus b2ca72480c58d197e18c885d9fc1a0c8d517e60a
curl -sLO https://raw.githubusercontent.com/opacra/opacra-xmrig/main/opacra-xmrig.patch
git apply opacra-xmrig.patch
sed -i 's/kDefaultDonateLevel = 1;/kDefaultDonateLevel = 0;/' src/donate.h
sed -i 's/kMinimumDonateLevel = 1;/kMinimumDonateLevel = 0;/' src/donate.h
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DWITH_OPENCL=OFF -DWITH_CUDA=OFF
make -j$(nproc)
```

Lalu jalankan:

```bash
./xmrig -o pool.opacra.org:4242 -a rx/opca -u "$(cat ~/mainnet-address.txt)" -p arm -k
```

Di sini `-DWITH_HWLOC=OFF` **tidak** diperlukan karena `libhwloc-dev` tersedia lewat apt. Itu
satu-satunya perbedaan penting dari resep Termux.

### 10.5 Cek hasil dan perbandingan

Dashboard pool (sama untuk semua platform):

```
https://pool.opacra.org/#ALAMATMU
```

Perkiraan hasil, dari data jaringan saat dokumen ini ditulis — **OPCA/hari ≈ H/s ÷ 231**:

| Perangkat | Hashrate | OPCA/hari |
|---|---|---|
| HP Cortex-A53, 2 thread | 150–300 | 0,65–1,3 |
| Laptop 4 core | ±2.000 | ±8,7 |
| PC desktop 8 core | ±6.000 | ±26 |

PC bisa memberi hasil sekitar 20× HP. Dengan harga $0,42 (16 November 2026), 26 OPCA/hari setara
sekitar **$11/hari** sebelum listrik — tetapi harga itu sempat turun 58% dalam satu hari, jadi angka
rupiahnya bisa berubah cepat ke arah mana pun.

---

## Perkiraan hasil

Diukur dari jaringan Opacra saat dokumentasi ini ditulis (hashrate jaringan 1,53 MH/s,
reward 2,3715 OPCA/block, 2880 block/hari):

| Hashrate | OPCA/hari | Payout pertama (0,33 OPCA) | ≈USD/hari @ $0,42 |
|---|---|---|---|
| 150 H/s | ±0,7 | ±11 jam | ±$0,27 |
| 300 H/s | ±1,3 | ±6 jam | ±$0,55 |
| 600 H/s | ±2,7 | ±3 jam | ±$1,10 |

Kolom USD memakai harga 16 November 2026 dan **bukan janji**: dalam 24 jam hari itu harga bergerak
dari $0,106 ke $1,00. Kalau OPCA kehilangan pasarnya, angkanya kembali ke nol.

## Troubleshooting

Semua baris di bawah ini adalah error nyata yang muncul saat pengujian, bukan dugaan.

| Gejala | Sebab | Solusi |
|---|---|---|
| `cannot locate symbol "_ZNSt6__ndk113__hash_memory"` | paket Termux tidak sinkron | `pkg upgrade -y`, lalu `pkg reinstall -y libc++ cmake` |
| `does not appear to contain CMakeLists.txt` | meng-clone repo patch, bukan source | clone `xmrig/xmrig` tag `v6.26.0` |
| `No TARGET 'xmrig' has been created` | ada flag tambahan di `cmake` | pakai tepat tiga flag di langkah 5 |
| `Could NOT find HWLoc` | paket hwloc Termux tanpa file dev | tambahkan `-DWITH_HWLOC=OFF` |
| `linker command failed due to signal` | RAM habis saat link | tutup aplikasi lain, `make -j1` |
| Mining mati sendiri beberapa menit | dataset 2,3 GB dibunuh Android | `--randomx-mode=light` |
| Hashrate 0 di awal | inisialisasi RandomX | tunggu 1–2 menit |
| HP panas dan lambat | wajar, CPU dipakai penuh | `--threads 1` |

## Verifikasi keaslian

Rilis resmi Opacra menyertakan checksum dan tanda tangan GPG. Untuk paket Linux v1.0.1:

```bash
sha256sum opacra-v1.0.1-linux-x64.tar.gz
# harus: ef8f8373b4f0cd44620a064c6959c335e3e2b17b254ddf053ffe654f15b9b9d5
```

Kunci rilis: fingerprint `D861 7219 6FEC AAB6 84F5 B3FD CB65 D212 D0B1 162B`.

Build di repo ini tidak memakai biner itu — kita membangun dari source XMRig + patch, dan
commit-nya dipin di langkah 4 supaya isi build tidak berubah diam-diam.

## Isi repo

| Berkas | Keterangan |
|---|---|
| `README.md` | dokumen ini — pasang miner dan jalankan |
| `WALLET.md` | membuat wallet Opacra di Termux (offline, 25 kata di perangkatmu) |
| `2-miner.sh` | skrip build + jalankan, mengikuti resep yang terbukti di HP ini |

## Lisensi

Skrip di repo ini bebas dipakai. XMRig berlisensi GPL-3.0, Opacra mengikuti lisensi Monero
(BSD-3-Clause); keduanya milik pemiliknya masing-masing.
