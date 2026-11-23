#!/usr/bin/env bash
# Compila LineageOS 22.2 para lisbon en una VM Ubuntu 24.04 (x86_64).
# Requisitos de la VM: >= 16 vCPU, >= 32 GB RAM (64 GB ideal),
# disco >= 400 GB SSD montado en $SRC (o en su carpeta padre).
#
# Uso:
#   tools/vm-build.sh deps                 # una sola vez (pide sudo)
#   tools/vm-build.sh sync                 # repo init + sync (la primera vez tarda)
#   tools/vm-build.sh prebuilts VENDOR_IMG # genera prebuilts/vendor.img
#   tools/vm-build.sh build                # m bacon
#
# Variables: SRC (default ~/lineage), JOBS (default nproc), TREE_REPO, TREE_BRANCH
set -euo pipefail

SRC="${SRC:-$HOME/lineage}"
JOBS="${JOBS:-$(nproc)}"
TREE_REPO="${TREE_REPO:-Ricky182771/android_device_motorola_lisbon}"
TREE_BRANCH="${TREE_BRANCH:-lineage-22.2}"
export USE_CCACHE=1 CCACHE_EXEC=/usr/bin/ccache CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"

deps() {
    sudo apt-get update
    sudo apt-get install -y bc bison build-essential ccache curl flex g++-multilib \
        gcc-multilib git git-lfs gnupg gperf imagemagick lib32readline-dev \
        lib32z1-dev libdw-dev libelf-dev libgnutls28-dev lz4 libsdl1.2-dev \
        libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool \
        squashfs-tools xsltproc zip zlib1g-dev protobuf-compiler python3-protobuf \
        python-is-python3 android-sdk-libsparse-utils
    mkdir -p "$HOME/bin"
    curl -sSL https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
    chmod +x "$HOME/bin/repo"
    git config --global user.name  >/dev/null || git config --global user.name  "Richi"
    git config --global user.email >/dev/null || git config --global user.email "richi@localhost"
    git lfs install
    ccache -M 50G
    echo "Listo. Agrega ~/bin al PATH si no está: export PATH=\$HOME/bin:\$PATH"
}

sync() {
    export PATH="$HOME/bin:$PATH"
    mkdir -p "$SRC/.repo/local_manifests" && cd "$SRC"
    [[ -d .repo/manifests ]] || repo init -u https://github.com/LineageOS/android.git \
        -b lineage-22.2 --git-lfs --no-clone-bundle --depth=1
    cat > .repo/local_manifests/lisbon.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <!-- Vendor y kernel son prebuilts dentro del propio tree: no hace falta más. -->
  <project path="device/motorola/lisbon" name="$TREE_REPO" remote="github" revision="$TREE_BRANCH" />
</manifest>
EOF
    repo sync -c -j"$JOBS" --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune
}

prebuilts() {
    local vimg="${1:?pasa la ruta de vendor_a.img}"
    cd "$SRC"
    # shellcheck disable=SC1091
    source build/envsetup.sh >/dev/null
    device/motorola/lisbon/tools/preparar-prebuilts.sh --vendor "$vimg"
}

build() {
    cd "$SRC"
    [[ -f device/motorola/lisbon/prebuilts/vendor.img ]] || { echo "falta prebuilts/vendor.img: corre '$0 prebuilts'"; exit 1; }
    # shellcheck disable=SC1091
    source build/envsetup.sh
    lunch lineage_lisbon-bp1a-userdebug
    m -j"$JOBS" bacon 2>&1 | tee "$SRC/build-$(date +%Y%m%d-%H%M).log"
    local o="$SRC/out/target/product/lisbon"
    echo
    echo "== Comprobaciones =="
    ls -lh "$o"/{boot,system,system_ext,product,vendor,vbmeta,vbmeta_system}.img "$o"/lineage-*.zip 2>/dev/null || true
    stat -c '%s bytes boot.img (límite 33554432)' "$o/boot.img"
    test -f "$o/recovery/root/first_stage_ramdisk/fstab.mt6785" \
        && echo "fstab en first_stage_ramdisk: OK" \
        || echo "OJO: falta first_stage_ramdisk/fstab.mt6785 (Android no montará system)"
    if command -v unpack_bootimg >/dev/null || [[ -x out/host/linux-x86/bin/unpack_bootimg ]]; then
        out/host/linux-x86/bin/unpack_bootimg --boot_img "$o/boot.img" --out /tmp/lisbon-boot \
            | grep -E 'header version|os version|os patch level|command line'
    fi
}

case "${1:-}" in
    deps) deps ;;
    sync) sync ;;
    prebuilts) shift; prebuilts "$@" ;;
    build) build ;;
    *) sed -n '2,13p' "$0"; exit 1 ;;
esac
