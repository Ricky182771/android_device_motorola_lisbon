#!/system/bin/sh
# Generado por preparar-descifrado.py
# Copia los blobs del TEE/keymaster/boot HAL desde la partición vendor real
# al /vendor del ramdisk, para que sigan ahí cuando TWRP desmonte /vendor.
#
# TWRP monta y desmonta el vendor real sobre /vendor varias veces al arrancar
# (módulos, fstab, props). Para no chocar con eso, se escribe en el ramdisk a
# través de un bind mount de "/" (no recursivo): ahí /vendor siempre es el
# directorio del ramdisk, aunque haya algo montado encima.
LIST=/system/etc/vendor-blobs.txt
MNT=/tmp/vendor_blobs_src
ROOT=/tmp/ramdisk_root
log() { echo "copiar-blobs: $*" > /dev/kmsg; }

[ "$(getprop vendor.blobs.ready)" = "1" ] && exit 0

SUFFIX=$(getprop ro.boot.slot_suffix)
DEV=/dev/block/mapper/vendor$SUFFIX
i=0
while [ ! -e "$DEV" ] && [ $i -lt 20 ]; do sleep 0.5; i=$((i+1)); done
[ -e "$DEV" ] || { log "no existe $DEV"; exit 1; }

mkdir -p $MNT $ROOT
mount -o bind / $ROOT || { log "no pude hacer bind de /"; exit 1; }
mount -t ext4 -o ro "$DEV" $MNT || { log "no pude montar $DEV"; umount $ROOT; exit 1; }
copy_one() {
    dst="$ROOT/vendor/$1"
    mkdir -p "${dst%/*}"
    # cp -a puede devolver error al preservar atributos aunque sí copie;
    # lo que cuenta es que el archivo (o symlink) quede en su lugar
    cp -a "$MNT/$1" "$dst" 2>/dev/null || cp -L "$MNT/$1" "$dst" 2>/dev/null
    [ -e "$dst" ] || [ -L "$dst" ]
}
PEND=/tmp/vendor_blobs_pend
grep -v -e '^#' -e '^$' $LIST > $PEND
# Hasta 5 pasadas: los primeros segundos del arranque a veces falla algún cp
for pass in 1 2 3 4 5; do
    : > $PEND.next
    while IFS= read -r rel; do
        copy_one "$rel" || echo "$rel" >> $PEND.next
    done < $PEND
    mv $PEND.next $PEND
    [ -s $PEND ] || break
    sleep 1
done
fail=$(wc -l < $PEND); n=$(( $(grep -vc -e '^#' -e '^$' $LIST) - fail ))
while IFS= read -r rel; do log "falló $rel"; done < $PEND
umount $MNT

# Los fallos se registran pero no bloquean: basta con que estén los ejecutables
for b in bin/mcDriverDaemon bin/hw/android.hardware.keymaster@4.1-service.trustonic \
         bin/hw/android.hardware.gatekeeper@1.0-service bin/hw/android.hardware.boot@1.2-service; do
    [ -x "$ROOT/vendor/$b" ] || { log "falta /vendor/$b, no arranco los servicios"; umount $ROOT; exit 1; }
done
umount $ROOT
log "copiados $n archivos desde $DEV, $fail fallos"
setprop vendor.blobs.ready 1
