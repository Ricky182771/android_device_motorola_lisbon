#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Moto G60s (lisbon) — MT6785 / Helio G95
# Estrategia de arranque: kernel + dtb + vendor del firmware stock
# S3RLS32.114-25-13 (Android 12) como prebuilts. Framework LineageOS 22.2.
#

DEVICE_PATH := device/motorola/lisbon

# ---------------------------------------------------------------------------
# Arquitectura (2x Cortex-A76 + 6x Cortex-A55, igual que RM6785)
# ---------------------------------------------------------------------------
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a76

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a76

# ---------------------------------------------------------------------------
# A/B
# ---------------------------------------------------------------------------
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    product \
    system \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor
# dtbo NO va aquí: se queda el stock.

# Sin partición recovery: el recovery vive en boot.
BOARD_USES_RECOVERY_AS_BOOT := true

# ---------------------------------------------------------------------------
# Bootloader / plataforma
# ---------------------------------------------------------------------------
TARGET_BOOTLOADER_BOARD_NAME := lisbon
TARGET_NO_BOOTLOADER := true
TARGET_BOARD_PLATFORM := mt6785

# ---------------------------------------------------------------------------
# Kernel (prebuilt stock, 4.14.186; sus módulos viven en el vendor stock)
# ---------------------------------------------------------------------------
BOARD_BOOT_HEADER_VERSION := 2
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_RAMDISK_OFFSET := 0x07c08000
BOARD_KERNEL_TAGS_OFFSET := 0x0bc08000
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)

BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
# Bring-up: SELinux permisivo. Quitar cuando haya política propia.
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive

TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilts/kernel
BOARD_KERNEL_IMAGE_NAME := Image.gz
# El dtb va en el boot (header v2), igual que en el TWRP que ya funciona.
BOARD_MKBOOTIMG_ARGS += --dtb $(DEVICE_PATH)/prebuilts/dtb.img
BOARD_INCLUDE_DTB_IN_BOOTIMG :=

# El kernel solo trae CONFIG_RD_GZIP: no activar LZ4/XZ para el ramdisk.
BOARD_RAMDISK_USE_LZ4 := false

# ---------------------------------------------------------------------------
# Particiones
# ---------------------------------------------------------------------------
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432

BOARD_USES_METADATA_PARTITION := true

TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
-include vendor/lineage/config/BoardConfigReservedSize.mk

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Vendor stock (Android 12, VNDK 31) como imagen prebuilt.
# La genera tools/preparar-prebuilts.sh a partir del firmware stock.
BOARD_PREBUILT_VENDORIMAGE := $(DEVICE_PATH)/prebuilts/vendor.img

# Particiones dinámicas
# TODO: llenar con la salida de tools/leer-super.sh (lpdump del super stock).
BOARD_SUPER_PARTITION_SIZE := 11408506880
BOARD_SUPER_PARTITION_GROUPS := motorola_dynamic_partitions
BOARD_MOTOROLA_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor
BOARD_MOTOROLA_DYNAMIC_PARTITIONS_SIZE := 11404312576 # TODO: tamaño máximo real del grupo según lpdump

# ---------------------------------------------------------------------------
# Propiedades
# ---------------------------------------------------------------------------
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# ---------------------------------------------------------------------------
# Recovery (Lineage Recovery dentro de boot)
# ---------------------------------------------------------------------------
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.mt6785
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888

# ---------------------------------------------------------------------------
# Parches de seguridad
# ---------------------------------------------------------------------------
# El vendor es el stock: su parche real es 2023-08-01.
VENDOR_SECURITY_PATCH := 2023-08-01

# ---------------------------------------------------------------------------
# Verified Boot (bootloader desbloqueado; verificación desactivada)
# ---------------------------------------------------------------------------
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

# Igual que el stock: system y system_ext encadenados en vbmeta_system
# (ver avb=vbmeta_system en fstab.mt6785); vendor y product en vbmeta.
BOARD_AVB_VBMETA_SYSTEM := system system_ext
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1
