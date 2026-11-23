#!/usr/bin/env bash
# Genera prebuilts/vendor.img a partir del firmware stock S3RLS32.114-25-13
# y comprueba que kernel/dtb del tree coinciden con el boot.img stock.
#
# Uso:
#   tools/preparar-prebuilts.sh --super ~/lisbon/fw/super.raw [--boot ~/lisbon/fw/boot.img]
#   tools/preparar-prebuilts.sh --vendor vendor_a.img        [--boot boot.img]
#
# vendor.img pesa más de 100 MB: NO se sube a git (.gitignore); se genera
# en cada máquina de build. Desde la PC conviene subir solo vendor_a.img:
#   lpunpack -p vendor_a -o ~/lisbon/fw ~/lisbon/fw/super.raw
#   rsync -P ~/lisbon/fw/vendor_a.img vm:~/lisbon-fw/
set -euo pipefail

TREE="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$TREE/prebuilts"
super="" vendor="" boot=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --super)  super="$2";  shift 2 ;;
        --vendor) vendor="$2"; shift 2 ;;
        --boot)   boot="$2";   shift 2 ;;
        *) echo "opción desconocida: $1"; exit 1 ;;
    esac
done

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# --- vendor -----------------------------------------------------------------
if [[ -n "$super" ]]; then
    command -v lpunpack >/dev/null || { echo "falta lpunpack"; exit 1; }
    lpunpack -p vendor_a -o "$work" "$super"
    vendor="$work/vendor_a.img"
fi
[[ -n "$vendor" ]] || { echo "pasa --super o --vendor"; exit 1; }

cp --sparse=always "$vendor" "$OUT/vendor.img"
echo "tipo: $(file -b "$OUT/vendor.img")"

# Quitar el footer AVB del stock: el build pone el suyo (hashtree) encima.
AVBTOOL="$(command -v avbtool || true)"
[[ -z "$AVBTOOL" && -n "${ANDROID_BUILD_TOP:-}" ]] && AVBTOOL="python3 $ANDROID_BUILD_TOP/external/avb/avbtool.py"
if [[ -n "$AVBTOOL" ]]; then
    if $AVBTOOL info_image --image "$OUT/vendor.img" >/dev/null 2>&1; then
        $AVBTOOL erase_footer --image "$OUT/vendor.img"
        echo "footer AVB del stock eliminado"
    else
        echo "vendor.img sin footer AVB"
    fi
else
    echo "AVISO: sin avbtool; si el build se queja del footer, correr este script dentro del árbol de Lineage (después de 'source build/envsetup.sh')."
fi

# Datos útiles del vendor para el tree
if command -v debugfs >/dev/null && file -b "$OUT/vendor.img" | grep -q ext4; then
    debugfs -R 'cat /build.prop' "$OUT/vendor.img" 2>/dev/null \
        | grep -E 'fingerprint|security_patch|vndk|first_api|ro.product.vendor.(name|device|model)' || true
    echo "módulos del kernel en vendor:"
    debugfs -R 'ls -p /lib/modules' "$OUT/vendor.img" 2>/dev/null | awk -F/ '$6 ~ /\.ko$/ {n++} END {print "  " n+0 " .ko"}'
fi
ls -lh "$OUT/vendor.img"

# --- kernel / dtb -----------------------------------------------------------
if [[ -n "$boot" ]]; then
    if command -v unpack_bootimg >/dev/null; then
        unpack_bootimg --boot_img "$boot" --out "$work/boot" >"$work/boot.txt"
        grep -E 'header version|os version|os patch level|command line' "$work/boot.txt" || true
        cmp -s "$work/boot/kernel" "$OUT/kernel" && echo "kernel: igual al stock" || echo "kernel: DIFERENTE al stock"
        cmp -s "$work/boot/dtb" "$OUT/dtb.img"   && echo "dtb: igual al stock"    || echo "dtb: DIFERENTE al stock"
        echo "ramdisk stock (busca módulos de first stage):"
        mkdir -p "$work/rd" && (cd "$work/rd" && gzip -dc ../boot/ramdisk | cpio -id --quiet 2>/dev/null)
        find "$work/rd" -name '*.ko' -o -name 'modules.load*' | sed "s#$work/rd#  #" | head -20
    else
        echo "sin unpack_bootimg; omito la comparación de kernel/dtb"
    fi
fi
