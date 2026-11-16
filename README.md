# Opacra mining di Termux

Menambang **OPCA** (Opacra) dari HP Android lewat Termux. Semua langkah di bawah sudah diuji
sampai miner benar-benar berjalan dan pool menerima share.

> **Baca dulu:** OPCA adalah koin privacy yang baru diluncurkan (mainnet 8 November 2026) dan
> **belum punya harga pasar** — tidak ada bursa yang me-list. Yang kamu dapat adalah koin, bukan
> uang, sampai ada pasar yang benar-benar membelinya. Jangan jalankan ini untuk HP yang kamu
> pakai sehari-hari: RandomX memakai CPU 100% terus-menerus.

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

## Perkiraan hasil

Diukur dari jaringan Opacra saat dokumentasi ini ditulis (hashrate jaringan 1,53 MH/s,
reward 2,3715 OPCA/block, 2880 block/hari):

| Hashrate | OPCA/hari | Payout pertama (0,33) |
|---|---|---|
| 150 H/s | ±0,7 | ±11 jam |
| 300 H/s | ±1,3 | ±6 jam |
| 600 H/s | ±2,7 | ±3 jam |

Angka ini koin, bukan rupiah — lihat catatan di bagian atas.

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
| `README.md` | dokumen ini |
| `2-miner.sh` | skrip build + jalankan, mengikuti resep yang terbukti di HP ini |

## Lisensi

Skrip di repo ini bebas dipakai. XMRig berlisensi GPL-3.0, Opacra mengikuti lisensi Monero
(BSD-3-Clause); keduanya milik pemiliknya masing-masing.
