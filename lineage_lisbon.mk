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

# Valores del stock S3RLS32.114-25-13 (getprop)
PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="lisbon_retail-user 12 S3RLS32.114-25-13 cdb96c release-keys" \
    BuildFingerprint=motorola/lisbon_retail/lisbon:12/S3RLS32.114-25-13/cdb96c:user/release-keys \
    DeviceProduct=lisbon_retail
