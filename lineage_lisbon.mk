#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from device
$(call inherit-product, device/motorola/lisbon/device.mk)

# Inherit some common LineageOS stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Device identifier. This must come after all inclusions.
PRODUCT_NAME := lineage_lisbon
PRODUCT_DEVICE := lisbon
PRODUCT_BRAND := motorola
PRODUCT_MODEL := moto g60s
PRODUCT_MANUFACTURER := motorola

PRODUCT_GMS_CLIENTID_BASE := android-motorola

# TODO: copiar los valores exactos del stock:
#   adb shell getprop ro.vendor.build.fingerprint
#   adb shell getprop ro.build.description   (o ro.vendor.build.description)
#   adb shell getprop ro.product.vendor.name
PRODUCT_BUILD_PROP_OVERRIDES += \
    DeviceProduct=lisbon_reteu
#   BuildDesc="lisbon_reteu-user 12 S3RLS32.114-25-13 <hash> release-keys"
#   BuildFingerprint=motorola/lisbon_reteu/lisbon:12/S3RLS32.114-25-13/<hash>:user/release-keys
