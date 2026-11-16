#!/data/data/com.termux/files/usr/bin/bash
# Opacra on Termux — build and run the miner.
#
# This is the recipe that actually built on a Cortex-A53 phone after five failed attempts.
# The flags below are the minimum set that works; every extra flag we tried (-DWITH_TLS=OFF,
# -DCMAKE_POLICY_VERSION_MINIMUM, -DWITH_HTTPD=OFF, custom linker flags) either broke the
# configure step or the link step. Do not add to them without a reason.
#
# The repo opacra/opacra-xmrig is NOT a fork with sources: it holds only opacra-xmrig.patch
# and an Ubuntu build script. So: XMRig v6.26.0 at a pinned commit, apply the patch, build.
#
# Usage:
#   ./2-miner.sh                 # light RandomX mode, 2 threads (safe on 3.5 GB RAM)
#   THREADS=1 ./2-miner.sh
#   ADDR=Pa... ./2-miner.sh
set -euo pipefail

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }

case "$(uname -m)" in
  aarch64|arm64) ;;
  *) echo "This script is for Termux on 64-bit ARM (aarch64). You have $(uname -m)."; exit 1 ;;
esac

WORK="$HOME"
THREADS="${THREADS:-2}"
POOL="${POOL:-pool.opacra.org:4242}"
XMRIG_TAG=v6.26.0
XMRIG_COMMIT=b2ca72480c58d197e18c885d9fc1a0c8d517e60a
PATCH_URL=https://raw.githubusercontent.com/opacra/opacra-xmrig/main/opacra-xmrig.patch

# ---- address -------------------------------------------------------------------------------
ADDR_FILE="$WORK/mainnet-address.txt"
if [ -n "${ADDR:-}" ]; then
  ADDR=$(printf '%s' "$ADDR" | tr -d '[:space:]')
else
  [ -s "$ADDR_FILE" ] || {
    echo "No address. Create it once with:"
    echo "  echo 'Pa...' > $ADDR_FILE"
    echo "or pass it inline:  ADDR=Pa... ./2-miner.sh"
    exit 1
  }
  ADDR=$(tr -d '[:space:]' < "$ADDR_FILE")
fi
case "$ADDR" in
  P*) ;;
  *) echo "That is not a mainnet address (it must start with P)."; exit 1 ;;
esac

# ---- build (skipped once the binary exists) -------------------------------------------------
if [ ! -x "$WORK/xmrig/build/xmrig" ]; then
  say "1/3  Build tools"
  pkg update -y && pkg upgrade -y
  pkg install -y git cmake make clang pkg-config openssl libuv

  command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock || true

  say "2/3  Source: XMRig $XMRIG_TAG + Opacra patch"
  cd "$WORK"
  [ -d xmrig ] || git clone --depth 1 --branch "$XMRIG_TAG" https://github.com/xmrig/xmrig.git
  cd xmrig

  HEAD_SHA=$(git rev-parse HEAD)
  [ "$HEAD_SHA" = "$XMRIG_COMMIT" ] || {
    echo "XMRig $XMRIG_TAG is at $HEAD_SHA, expected $XMRIG_COMMIT."
    echo "A moved tag would change what we build. Stop here."
    exit 1
  }

  [ -f opacra-xmrig.patch ] || curl -sL "$PATCH_URL" -o opacra-xmrig.patch
  git apply opacra-xmrig.patch

  # No hash power to XMRig's authors, same as Opacra's own build.
  sed -i 's/kDefaultDonateLevel = 1;/kDefaultDonateLevel = 0;/' src/donate.h
  sed -i 's/kMinimumDonateLevel = 1;/kMinimumDonateLevel = 0;/' src/donate.h

  say "3/3  Configure and build (20-25 min, keep the phone cool and charged)"
  rm -rf build && mkdir build && cd build
  # Exactly these three flags. WITH_HWLOC=OFF is required: Termux's hwloc ships without the
  # dev files CMake looks for. OpenCL/CUDA are off because a phone has no such device.
  cmake .. -DCMAKE_BUILD_TYPE=Release -DWITH_HWLOC=OFF -DWITH_OPENCL=OFF -DWITH_CUDA=OFF
  # -j1: the link step needs about 1 GB of RAM on its own.
  make -j1
  cd "$WORK"
fi

BIN="$WORK/xmrig/build/xmrig"
[ -x "$BIN" ] || { echo "No $BIN. Run: cd $WORK/xmrig/build && make -j1"; exit 1; }

# ---- run ------------------------------------------------------------------------------------
say "Mining  $THREADS thread(s)  ->  $ADDR"
echo "Pool:  $POOL  (1% fee, pays out from 0.33 OPCA)"
echo "Stats: https://pool.opacra.org/#$ADDR"
echo "Press h for hashrate, q to quit."
echo
# --randomx-mode=light keeps the 2.3 GB dataset off the phone: essential on 3.5 GB RAM,
# where the fast mode gets the process killed by Android within minutes.
exec "$BIN" -o "$POOL" -a rx/opca -u "$ADDR" -p termux -k \
  --threads "$THREADS" --randomx-mode=light --no-color
