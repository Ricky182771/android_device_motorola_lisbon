#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/motorola/lisbon

# ---------------------------------------------------------------------------
# API levels
# ---------------------------------------------------------------------------
# lisbon salió con Android 11. TODO: confirmar con
#   adb shell getprop ro.product.first_api_level
PRODUCT_SHIPPING_API_LEVEL := 30

# Vendor stock de Android 12 => necesita la APEX de VNDK v31
# (prebuilts/vndk/v31 viene en el manifest de lineage-22.2).
PRODUCT_EXTRA_VNDK_VERSIONS := 31

# ---------------------------------------------------------------------------
# Particiones dinámicas / A/B
# ---------------------------------------------------------------------------
PRODUCT_USE_DYNAMIC_PARTITIONS := true
# Se flashea por partición desde fastbootd; no hace falta super.img.
PRODUCT_BUILD_SUPER_PARTITION := false

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

PRODUCT_PACKAGES += \
    otapreopt_script \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

# El HAL de boot control (MTK 1.2) ya viene en el vendor stock.
# TODO(recovery): para sideload A/B desde Lineage Recovery hace falta
# su variante .recovery en el ramdisk; no viene en vendor.img.

# ---------------------------------------------------------------------------
# fstab
# ---------------------------------------------------------------------------
# En arranque normal, el first stage init hace SwitchRoot a
# /first_stage_ramdisk y monta con este fstab (lección del TWRP).
# Verificar tras el build que quedó en
#   out/target/product/lisbon/recovery/root/first_stage_ramdisk/fstab.mt6785
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.mt6785:$(TARGET_COPY_OUT_RAMDISK)/fstab.mt6785 \
    $(LOCAL_PATH)/rootdir/etc/fstab.emmc:$(TARGET_COPY_OUT_RAMDISK)/fstab.emmc

# ---------------------------------------------------------------------------
# VINTF
# ---------------------------------------------------------------------------
# El kernel 4.14 no cumple los requisitos de kernel del FCM de Android 15;
# con vendor y kernel stock no tiene sentido que el build lo bloquee.
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# ---------------------------------------------------------------------------
# Pantalla
# ---------------------------------------------------------------------------
# 1080x2460
TARGET_SCREEN_HEIGHT := 2460
TARGET_SCREEN_WIDTH := 1080

# ---------------------------------------------------------------------------
# Soong namespaces
# ---------------------------------------------------------------------------
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)
