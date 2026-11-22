#!/system/bin/sh
# Generado por preparar-descifrado.py
# Copia los blobs del TEE/keymaster/boot HAL desde la partición vendor real
# al /vendor del ramdisk, para que sigan ahí cuando TWRP desmonte /vendor.
LIST=/system/etc/vendor-blobs.txt
MNT=/tmp/vendor_blobs_src
log() { echo "copiar-blobs: $*" > /dev/kmsg; }

[ "$(getprop vendor.blobs.ready)" = "1" ] && exit 0

SUFFIX=$(getprop ro.boot.slot_suffix)
DEV=/dev/block/mapper/vendor$SUFFIX
i=0
while [ ! -e "$DEV" ] && [ $i -lt 20 ]; do sleep 0.5; i=$((i+1)); done
[ -e "$DEV" ] || { log "no existe $DEV"; exit 1; }

# Si TWRP tiene montado el vendor real en /vendor, esperar a que lo suelte
i=0
while grep -q " /vendor " /proc/mounts && [ $i -lt 40 ]; do sleep 0.25; i=$((i+1)); done
grep -q " /vendor " /proc/mounts && { log "/vendor sigue montado, no copio"; exit 1; }

mkdir -p $MNT
mount -t ext4 -o ro "$DEV" $MNT || { log "no pude montar $DEV"; exit 1; }
n=0; fail=0
while IFS= read -r rel; do
    case "$rel" in ''|'#'*) continue ;; esac
    mkdir -p "/vendor/${rel%/*}"
    if cp -a "$MNT/$rel" "/vendor/$rel"; then n=$((n+1)); else fail=$((fail+1)); log "falló $rel"; fi
done < $LIST
umount $MNT
log "copiados $n archivos desde $DEV, $fail fallos"
[ $fail -eq 0 ] && setprop vendor.blobs.ready 1
