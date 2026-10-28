#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2018 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

BOARD_VENDOR := samsung

COMMON_PATH := device/samsung/gts3l-common

# Include path
TARGET_SPECIFIC_HEADER_PATH := $(COMMON_PATH)/include

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := kryo

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := msm8996
TARGET_NO_BOOTLOADER := true

# Dexpreopt
ifeq ($(HOST_OS),linux)
  ifneq ($(TARGET_BUILD_VARIANT),eng)
    WITH_DEXPREOPT_BOOT_IMG_AND_SYSTEM_SERVER_ONLY ?= false
    WITH_DEXPREOPT := true
  endif
endif

# Android 17's normal Scudo configuration favors allocator throughput. Use
# AOSP's supported low-memory configuration on this 4 GiB legacy device.
MALLOC_LOW_MEMORY := true

# Kernel
BOARD_KERNEL_BASE := 0x80000000
BOARD_KERNEL_CMDLINE := androidboot.hardware=qcom msm_rtb.filter=0x237 ehci-hcd.park=3 androidboot.bootdevice=7464900.sdhci lpm_levels.sleep_disabled=1 rcupdate.rcu_expedited=1 cma=32M@0-0xffffffff loop.max_part=7
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
BOARD_KERNEL_PAGESIZE := 4096
BOARD_MKBOOTIMG_ARGS := --ramdisk_offset 0x02200000 --tags_offset 0x02000000
BOARD_CUSTOM_BOOTIMG := true
BOARD_CUSTOM_BOOTIMG_MK := $(COMMON_PATH)/bootimg.mk
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_CLANG_COMPILE := false
TARGET_KERNEL_LLVM_BINUTILS := false
TARGET_KERNEL_VERSION := 3.18
TARGET_KERNEL_SOURCE := kernel/samsung/msm8996
TARGET_COMPILE_WITH_MSM_KERNEL := true
KERNEL_CROSS_COMPILE = CROSS_COMPILE=$(BUILD_TOP)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_CC = CC="$(KERNEL_CC_WRAPPER) $(BUILD_TOP)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-gcc"
TARGET_KERNEL_ADDITIONAL_FLAGS = \
    -j8 \
    HOSTCC="/usr/bin/gcc -B/usr/bin/" HOSTCXX="/usr/bin/g++ -B/usr/bin/" \
    HOSTAR=/usr/bin/ar HOSTLD=/usr/bin/ld \
    HOSTCFLAGS="-O2 -std=gnu89" HOSTLDFLAGS="" \
    CROSS_COMPILE_ARM32=$(BUILD_TOP)/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- \
    KBUILD_BUILD_USER=rom-builder KBUILD_BUILD_HOST=podman

# Platform
TARGET_BOARD_PLATFORM := msm8996

# Keep the original modem RFS firmware path with Qualcomm's current link modules.
$(call soong_config_set,rfs,mpss_firmware_symlink_target,firmware_modem)

# Keep APEX ext4 payloads within the kernel's declared feature masks.
$(call soong_config_set_bool,gts3l_legacy,apex_no_shared_blocks,true)

# ANT+
BOARD_ANT_WIRELESS_DEVICE := "qualcomm-hidl"

# Audio
TARGET_USES_QCOM_MM_AUDIO := true
AUDIO_FEATURE_ENABLED_AUDIOSPHERE := true
AUDIO_FEATURE_ENABLED_DS2_DOLBY_DAP := true
AUDIO_FEATURE_ENABLED_INSTANCE_ID := true
AUDIO_FEATURE_ENABLED_PROXY_DEVICE := true
USE_CUSTOM_AUDIO_POLICY := 1
# The Samsung primary HAL requires the version-0.1, 48-byte offload prefix.
$(call soong_config_set_bool,android_hardware_audio,legacy_offload_info_v1,true)
# The Android 9 primary blob predates input-stream microphone steering fields.
$(call soong_config_set_bool,android_hardware_audio,legacy_input_stream_v9,true)
# It also predates set_event_callback and later output-stream callbacks.
$(call soong_config_set_bool,android_hardware_audio,legacy_output_stream_v9,true)

# Bluetooth
BOARD_HAS_QCA_BT_ROME := true
BOARD_HAVE_BLUETOOTH_QCOM := true
QCOM_BT_USE_BTNV := true

# Camera
BOARD_QTI_CAMERA_32BIT_ONLY := true
TARGET_PROCESS_SDK_VERSION_OVERRIDE += \
    /vendor/bin/mm-qcamera-daemon=26
TARGET_USES_MEDIA_EXTENSIONS := true
USE_DEVICE_SPECIFIC_CAMERA := true

# Charger
BOARD_CHARGER_ENABLE_SUSPEND := true

# Display
MAX_VIRTUAL_DISPLAY_DIMENSION := 4096
TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS := true
TARGET_HAS_WIDE_COLOR_DISPLAY := true
TARGET_SCREEN_DENSITY := 280
TARGET_USES_C2D_COMPOSITION := true
TARGET_USES_GRALLOC1 := true
TARGET_USES_HWC2 := true
TARGET_USES_ION := true
TARGET_USES_OVERLAY := true

# The device ships a HIDL 2.1 mapper. Android 17 otherwise requires mapper 4+
# even on legacy launch devices, which makes SurfaceFlinger abort at startup.
$(call soong_config_set_bool,libui,legacy_gralloc,true)

VSYNC_EVENT_PHASE_OFFSET_NS := 2000000
SF_VSYNC_EVENT_PHASE_OFFSET_NS := 6000000

TARGET_DISABLE_POSTRENDER_CLEANUP := true

# surfaceflinger orientation
SF_PRIMARY_DISPLAY_ORIENTATION := 270

# DRM
TARGET_ENABLE_MEDIADRM_64 := true

# Filesystem
TARGET_FS_CONFIG_GEN := $(COMMON_PATH)/config.fs

# HIDL
PRODUCT_ENFORCE_VINTF_MANIFEST_OVERRIDE := true
DEVICE_MANIFEST_FILE := $(COMMON_PATH)/manifest.xml
DEVICE_MATRIX_FILE := $(COMMON_PATH)/compatibility_matrix.xml
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE := $(COMMON_PATH)/framework_compatibility_matrix.xml

# Partitions
# Android 16 defaults to A/B unless the legacy product explicitly opts out.
AB_OTA_UPDATER := false
# Reuse the filtered, audited System image for OTA packaging. Rebuilding it
# from the target-files directory also collects generated recovery resources
# and incidental outputs that were not declared product packages.
COPY_IMAGES_FOR_TARGET_FILES_ZIP := true
BOARD_BOOTIMAGE_PARTITION_SIZE := 79691776
BOARD_CACHEIMAGE_PARTITION_SIZE := 209715200
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_PERSISTIMAGE_PARTITION_SIZE := 33554432
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 79691776
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 4194304000
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_PARTITION_SIZE := 26226965504
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_FLASH_BLOCK_SIZE := 131072 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_ROOT_EXTRA_SYMLINKS := \
    /vendor/dsp:/dsp \
    /vendor/firmware-modem:/firmware-modem \
    /vendor/firmware_mnt:/firmware \
    /mnt/vendor/persist:/persist

# Root
# There is no metadata partition on this device. Init binds a Cache directory
# here before Android's post-fs aconfig initialization.
BOARD_ROOT_EXTRA_FOLDERS := efs metadata

# Init
TARGET_PLATFORM_DEVICE_BASE := "/devices/soc/"

# Keymaster
TARGET_PROVIDES_KEYMASTER := true

# Power
TARGET_HAS_NO_WLAN_STATS := true
TARGET_USES_INTERACTION_BOOST := true

# Properties
TARGET_SYSTEM_PROP += $(COMMON_PATH)/system.prop

# QCOM
BOARD_USES_QCOM_HARDWARE := true

# Recovery
TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/rootdir/etc/fstab.qcom
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Security patch level
VENDOR_SECURITY_PATCH := 2020-03-01

# SELinux
include device/qcom/sepolicy-legacy-um/SEPolicy.mk
BOARD_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy
SELINUX_IGNORE_NEVERALLOWS := true

# Shims
TARGET_LD_SHIM_LIBS := \
    /vendor/lib/hw/audio.primary.msm8996.so|libaudioprimary_shim.so \
    /vendor/lib/hw/camera.msm8996.so|libcamera_metadata_helper.so

# Verity
# Only needed for signing
BOARD_AVB_ENABLE := false

# Wifi
BOARD_HAVE_SAMSUNG_WIFI := true
BOARD_WLAN_DEVICE := qcwcn
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
HOSTAPD_VERSION := VER_0_8_X
WIFI_AVOID_IFACE_RESET_MAC_CHANGE := true
WIFI_DRIVER_FW_PATH_AP := "ap"
WIFI_DRIVER_FW_PATH_STA := "sta"
WIFI_DRIVER_FW_PATH_P2P := "p2p"
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true
# Keep legacy STA/AP modes: this driver requires explicit firmware switching.
# The AIDL HAL preserves those IDs when querying driver concurrency support.
WPA_SUPPLICANT_VERSION := VER_0_8_X
