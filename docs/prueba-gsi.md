# Prueba GSI de Android 15 en lisbon

**Para qué sirve:** comprobar si el kernel stock 4.14.186 y el vendor stock
(Android 12, VNDK 31) aguantan un framework de Android 15. Es la misma
arquitectura que la ROM (vendor + kernel stock como prebuilts), así que lo que
falle aquí también fallará en la ROM.

GSI: **LineageOS 22.2 de MisterZtr**, release `v2026.01.05-lineage22.2`,
variante **VANILLA-EXT4** (arm64, A/B):
https://github.com/MisterZtr/LineageOS_gsi/releases/tag/v2026.01.05-lineage22.2

> Reglas de siempre: nada de `fastboot erase nvdata`; los respaldos de
> `~/lisbon/respaldo-particiones` deben estar al día. **Se formatea /data**, así
> que saca fotos y datos del teléfono antes (el backup de TWRP de Data
> sirve para volver a stock, pero no para pasar los datos a la GSI).

## 0. Datos previos (con Android stock arrancado)

```bash
adb shell getprop | grep -E 'ro.virtual_ab|ro.boot.dynamic_partitions|first_api_level|ro.vndk.version|ro.vendor.build.fingerprint|ro.build.description|ro.product.vendor.name|ro.sf.lcd_density|ro.boot.slot_suffix|ro.treble.enabled' | tee ~/lisbon/props-stock.txt
adb shell cat /proc/version | tee -a ~/lisbon/props-stock.txt
adb shell 'su -c "ls /sys/fs/bpf"' 2>/dev/null | tee -a ~/lisbon/props-stock.txt   # si hay root

# Super y archivos del firmware
tools/leer-super.sh ~/lisbon/fw/super.raw | tee ~/lisbon/lpdump-resumen.txt
grep -oE 'filename="[^"]+"|partition="[^"]+"' ~/lisbon/fw/flashfile.xml | sort -u
```

Con esto se llenan los TODO del tree (fingerprint, first_api_level, tamaños del super).

## 1. Preparar la imagen

```bash
mkdir -p ~/lisbon/gsi && cd ~/lisbon/gsi
# descarga el .7z VANILLA-EXT4 del release y luego:
7z x LineageOS-22.2-*-VANILLA-EXT4-GSI.7z
ls -lh *.img
```

## 2. Poner el boot stock (para tener fastbootd)

TWRP en `boot_a` no trae fastbootd; el boot stock sí (recovery-as-boot).

```bash
adb reboot bootloader
fastboot getvar current-slot          # debe decir a
fastboot flash boot_a ~/lisbon/fw/boot.img
```

## 3. Desactivar la verificación en vbmeta (bootloader)

```bash
fastboot --disable-verity --disable-verification flash vbmeta_a ~/lisbon/fw/vbmeta.img
```

## 4. Flashear la GSI (fastbootd)

```bash
fastboot reboot fastboot
fastboot getvar is-userspace          # debe decir yes
fastboot delete-logical-partition product_a   # libera espacio; se restaura con el flashfile
fastboot flash system_a ~/lisbon/gsi/<nombre>.img
fastboot erase md_udc                 # en lisbon /metadata es la partición md_udc
fastboot -w
fastboot reboot
```

`system_ext_a` se queda como está: la GSI trae `skip_mount.cfg` y no lo monta.

## 5. Qué medir

**Si arranca:**

```bash
adb shell getprop ro.build.version.release        # 15
adb shell 'dmesg | grep -iE "bpf|binder" | head -50'
adb logcat -b all -d | grep -iE 'bpfloader|netd|NetBpf|BpfUtils' | head -80
adb shell ip a
adb shell dumpsys wifi | head -30
adb shell getprop | grep -E 'gsm\.|ril\.'
adb shell lshal 2>/dev/null | head -5 ; adb shell service list | wc -l
```

Checklist: pantalla y touch, Wi-Fi, datos y llamadas (SIM), audio, cámara, BT,
sensores, huella, carga. Anota qué falla: lo del framework/BPF es problema del
kernel; lo de HALs es problema de vendor/VINTF.

**Si no arranca (bootloop o se queda en el logo):**

1. Si `adb` responde durante el bootloop:
   `adb logcat -b all > ~/lisbon/gsi/bootloop.log` y `adb shell dmesg > ~/lisbon/gsi/dmesg.log`.
2. Si no: forzar el apagado, entrar al bootloader, flashear TWRP
   (`fastboot flash boot_a ~/lisbon/twrp-lisbon-v1-coexist.img`), arrancar en
   recovery y sacar:
   ```bash
   adb pull /sys/fs/pstore ~/lisbon/gsi/pstore
   adb shell 'ls /data/tombstones /data/misc/logd 2>/dev/null'
   ```
   (/data ya está formateado y se recreó con llaves nuevas; TWRP debería
   descifrarlo igual porque usa el mismo TEE.)

## 6. Volver a stock

```bash
python3 <ruta>/flashfile2fastboot.py --slot a --skip nvdata   # restaura product_a, system_a, vbmeta, boot
```

Después se vuelve a flashear `twrp-lisbon-v1-coexist.img` en `boot_a` si se
quiere TWRP. Si /data quedó con llaves de la GSI, Android stock pedirá formatear:
eso es normal.
