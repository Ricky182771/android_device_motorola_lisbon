# Device tree de LineageOS 22.2 para Moto G60s (lisbon)

Rama `lineage-22.2`. El TWRP sigue en la rama `main`.

| | |
|---|---|
| Equipo | Moto G60s XT2133-2, `lisbon`, MT6785 (Helio G95) |
| Firmware base | S3RLS32.114-25-13 (Android 12), canal RETEU |
| Kernel | prebuilt stock 4.14.186 (`prebuilts/kernel`, Image.gz) + `prebuilts/dtb.img` |
| Vendor | `vendor_a` stock como `BOARD_PREBUILT_VENDORIMAGE` (VNDK 31) |
| Boot | recovery-as-boot, header v2, 32 MB, ramdisk gzip |

## Estado

Esqueleto inicial: aún no se ha compilado. Primero va la [prueba de GSI](docs/prueba-gsi.md).

Pendiente (TODO en los .mk):
- Tamaños reales del super y del grupo → `tools/leer-super.sh`.
- Fingerprint/descripción stock, `first_api_level` y densidad → `getprop`.
- Boot control HAL en el ramdisk de recovery (sideload A/B).
- Overlays (esquinas, recortes, brillo), sepolicy propia y salir de permissive.

## Compilar (VM Ubuntu 24.04)

```bash
git clone -b lineage-22.2 https://github.com/Ricky182771/android_device_motorola_lisbon ~/lisbon-tree
~/lisbon-tree/tools/vm-build.sh deps
~/lisbon-tree/tools/vm-build.sh sync
~/lisbon-tree/tools/vm-build.sh prebuilts ~/lisbon-fw/vendor_a.img   # subido desde la PC
~/lisbon-tree/tools/vm-build.sh build
```

## Flashear (después de una build)

```bash
adb reboot bootloader
fastboot flash boot_a boot.img
fastboot flash vbmeta_a vbmeta.img
fastboot flash vbmeta_system_a vbmeta_system.img
fastboot reboot fastboot
fastboot flash system_a system.img
fastboot flash system_ext_a system_ext.img
fastboot flash product_a product.img
fastboot flash vendor_a vendor.img
fastboot erase md_udc                 # en lisbon /metadata es la partición md_udc
fastboot -w
fastboot reboot
```

## Referencias

- Realme 6/7 (MT6785): `realme-mt6785-devs/android_device_realme_RM6785`. Mismos
  offsets de boot y cmdline. Usó kernel 4.14 hasta `lineage-22.2` y 4.19 en `lineage-24.0`.
- Moto oficial en Lineage 22.2 (estructura de los .mk): `LineageOS/android_device_motorola_devon`.
