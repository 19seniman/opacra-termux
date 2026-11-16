# Membuat wallet Opacra di Termux

Panduan membangun `opacra-wallet-cli` di HP Android dan membuat wallet **offline** — alamat dan
25 kata dibuat di perangkatmu sendiri, tanpa menghubungi node dan tanpa mengirim apa pun ke mana pun.

> **Peringatan:** 25 kata yang muncul adalah satu-satunya salinan wallet-mu. Tulis di kertas.
> Jangan difoto, jangan disimpan di notes atau cloud, dan jangan pernah mengetiknya ke chat —
> termasuk ke asisten AI. Siapa pun yang memegang kata itu memegang koinnya.

## Status pengujian

Resep build miner di `README.md` sudah diuji di HP Cortex-A53. **Build wallet ini belum** — ia
disusun dari struktur build Monero v0.18.5.1 (Opacra adalah fork-nya). Titik gagal yang paling
mungkin: versi Boost dan OpenSSL 3. Kalau macet di situ, itu keterbatasan toolchain, bukan
kesalahan langkah.

Kalau kamu punya PC Windows, jalur yang jauh lebih ringan ada di bagian [Alternatif](#alternatif)
di bawah: GUI resmi 45,9 MB, tanpa compile.

---

## 1. Dependensi

```bash
pkg update -y && pkg upgrade -y
pkg install -y git cmake make clang pkg-config boost openssl libsodium libuv \
  zeromq readline libunbound libusb libexpat liblzma
```

`pkg upgrade` jangan dilewati: tanpa itu `cmake` bisa gagal dengan error
`cannot locate symbol "_ZNSt6__ndk113__hash_memory"`.

## 2. Ambil source

```bash
cd ~
git clone --recursive --depth 1 https://github.com/opacra/opacra.git
cd opacra
```

`--recursive` wajib: Monero membawa submodule `easylogging++`, `rapidjson`, dan `randomx`.
Tanpa submodule, configure akan berhenti.

## 3. Build wallet saja

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF -DUSE_DEVICE_TREZOR=OFF
make -j1 opacra-wallet-cli
```

Yang dibangun hanya target wallet, bukan `opacrad` — jadi tidak perlu blockchain 20 GB.

| | Perkiraan |
|---|---|
| Waktu | 1–2 jam |
| Disk | ±2,5 GB |
| RAM saat link | ±1 GB bebas |

Kalau `make` mati di tengah, ulangi `make -j1` setelah menutup aplikasi lain.

## 4. Buat wallet

```bash
cd ~/opacra/build/bin
./opacra-wallet-cli --offline --generate-new-wallet mainnet-wallet \
  --mnemonic-language English --create-address-file --command address
```

`--offline` berarti tidak ada koneksi ke node: kunci dibuat lokal, dan alamat dicetak tanpa
perlu sinkronisasi.

Kamu akan ditanya password wallet. Itu password **lokal** untuk membuka file di HP ini — beda
dengan 25 kata. Catat keduanya.

## 5. Simpan dan amankan

Setelah selesai, di folder yang sama ada:

| Berkas | Isi | Perlakuan |
|---|---|---|
| `mainnet-wallet` | data wallet terenkripsi | cadangkan |
| `mainnet-wallet.keys` | kunci terenkripsi | cadangkan, jangan dibagikan |
| `mainnet-wallet.address.txt` | alamat `Pa…` | **boleh** dibagikan |

Lalu bersihkan jejak di terminal:

```bash
history -c && clear
```

Tulis 25 kata di kertas, simpan terpisah dari HP. Kalau HP hilang dan kertas hilang, koinnya hilang
permanen — tidak ada pemulihan akun, tidak ada customer service.

## 6. Memakai koinnya

Wallet CLI butuh **node yang tersinkron** untuk melihat saldo dan mengirim koin:

```bash
# di mesin lain dengan disk ≥20 GB, bukan di HP
opacrad --data-dir ~/.opacra
```

Lalu arahkan wallet ke node itu:

```bash
./opacra-wallet-cli --daemon-address <host>:<port> --wallet-file mainnet-wallet
```

Ini batasan nyata: di Termux kamu bisa **membuat** wallet dengan aman, tetapi **memakai** koinnya
butuh node. Kalau tujuannya hanya menampung hasil mining, wallet offline sudah cukup sampai kamu
siap memindahkannya.

## Alternatif

Kalau ada PC Windows, pakai GUI resminya — tanpa compile, tanpa node, 5 menit:

1. Unduh `opacra-gui-v1.0.0-win-x64.zip` (45,9 MB) dari halaman release `opacra/opacra-gui`
2. Ekstrak, jalankan, pilih **Create new wallet**
3. Tulis 25 kata di kertas, simpan password

Alamat yang dihasilkan sama formatnya (`Pa…`) dan bisa langsung dipakai di miner.

## Troubleshooting

| Gejala | Sebab | Solusi |
|---|---|---|
| `cannot locate symbol "_ZNSt6__ndk113__hash_memory"` | paket Termux tidak sinkron | `pkg upgrade -y`, lalu `pkg reinstall -y libc++ cmake` |
| `Could NOT find Boost` | paket boost belum terpasang | `pkg install -y boost` |
| configure berhenti di `randomx` | submodule tidak ikut | clone ulang dengan `--recursive` |
| `linker command failed due to signal` | RAM habis saat link | tutup aplikasi lain, `make -j1` |
| `opacra-wallet-cli: not found` | target belum selesai dibangun | `make -j1 opacra-wallet-cli` di folder `build` |
| lupa 25 kata | — | tidak bisa dipulihkan; buat wallet baru |

## Verifikasi

Rilis resmi Opacra menyertakan checksum dan tanda tangan GPG. Kunci rilis:
`D861 7219 6FEC AAB6 84F5 B3FD CB65 D212 D0B1 162B`.

Build di panduan ini tidak memakai biner rilis — semuanya dibangun dari source yang kamu clone
sendiri, jadi yang perlu kamu percaya hanya repo `opacra/opacra`.
