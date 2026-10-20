#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_COMMON=
ONLY_TARGET=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-common )
                ONLY_COMMON=true
                ;;
        --only-target )
                ONLY_TARGET=true
                ;;
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
    vendor/lib64/hw/vulkan.msm8996.so)
        sed -i "s/vulkan.msm8953.so/vulkan.msm8996.so/g" "${2}"
        ;;
    vendor/lib/hw/vulkan.msm8996.so)
        sed -i "s/vulkan.msm8953.so/vulkan.msm8996.so/g" "${2}"
        ;;
    vendor/lib/hw/camera.msm8996.so)
        "${PATCHELF}" --replace-needed "libcamera_client.so" "libcamera_metadata_helper.so" "${2}"
        ;;
    vendor/lib/libbauthserver.so|vendor/lib64/libbauthserver.so)
        case "$("${PATCHELF}" --print-needed "${2}")" in
            *libbauthtzcommon_shim.so*) ;;
            *) "${PATCHELF}" --add-needed "libbauthtzcommon_shim.so" "${2}" ;;
        esac
        ;;
    vendor/lib/libwvhidl.so)
        "${PATCHELF}" --replace-needed "libprotobuf-cpp-lite.so" "libprotobuf-cpp-lite-v29.so" "${2}"
        ;;
    vendor/lib/libmmcamera2_sensor_modules.so)
        sed -i "s|/system/etc/firmware|/vendor/firmware\x0\x0\x0\x0|g" "${2}"
        ;;
    vendor/lib/libmmcamera2_stats_modules.so)
        "${PATCHELF}" --replace-needed "libandroid.so" "libsensorndkbridge.so" "${2}"
        "${PATCHELF}" --replace-needed "libgui.so" "libgui_vendor.so" "${2}"
        python3 "${MY_DIR}/patch_camera_stats_af_uaf.py" "${2}"
        python3 "${MY_DIR}/patch_camera_stats_aec_uaf.py" "${2}"
        python3 "${MY_DIR}/patch_camera_stats_af_setparm_uaf.py" "${2}"
        ;;
    vendor/lib/hw/audio.primary.msm8996.so)
        "${PATCHELF}" --replace-needed "libcutils.so" "libprocessgroup.so" "${2}"
        case "$("${PATCHELF}" --print-needed "${2}")" in
            *libaudioprimary_shim.so*) ;;
            *) "${PATCHELF}" --add-needed "libaudioprimary_shim.so" "${2}" ;;
        esac
        # patchelf can relocate PT_PHDR incorrectly for this ELF's nonzero base.
        python3 "${MY_DIR}/fixup_elf_phdr.py" "${2}"
        ;;
    vendor/lib/hw/android.hardware.gnss@1.0-impl-qti.so)
        "${PATCHELF}" --replace-needed "libcutils.so" "libprocessgroup.so" "${2}"
        ;;
    vendor/lib64/hw/android.hardware.gnss@1.0-impl-qti.so)
        "${PATCHELF}" --replace-needed "libcutils.so" "libprocessgroup.so" "${2}"
        ;;
    vendor/bin/loc_launcher)
        "${PATCHELF}" --replace-needed "libcutils.so" "libprocessgroup.so" "${2}"
        ;;
    vendor/bin/lowi-server)
        "${PATCHELF}" --replace-needed "libcutils.so" "libprocessgroup.so" "${2}"
        ;;
    vendor/bin/xtra-daemon)
        "${PATCHELF}" --replace-needed "libandroid.so" "libsensorndkbridge.so" "${2}"
        "${PATCHELF}" --replace-needed "libcutils.so" "libprocessgroup.so" "${2}"
        ;;
    lib64/com.qualcomm.qti.ant@1.0.so|vendor/lib64/com.qualcomm.qti.ant@1.0.so)
        "${PATCHELF}" --replace-needed "libhidlbase.so" "libhidlbase-v32.so" "${2}"
        ;;
    vendor/lib64/vendor.qti.hardware.tui_comm@1.0.so)
        "${PATCHELF}" --replace-needed "libhidlbase.so" "libhidlbase-v32.so" "${2}"
        ;;
    vendor/bin/hw/android.hardware.bluetooth@1.0-service-qti)
        "${PATCHELF}" --replace-needed "libhidlbase.so" "libhidlbase-v32.so" "${2}"
        ;;
    vendor/bin/hw/vendor.qti.gnss@1.0-service)
        "${PATCHELF}" --replace-needed "libhidlbase.so" "libhidlbase-v32.so" "${2}"
        ;;
    vendor/bin/hw/vendor.qti.hardware.qdutils_disp@1.0-service-qti)
        "${PATCHELF}" --replace-needed "libhidlbase.so" "libhidlbase-v32.so" "${2}"
        ;;
    vendor/bin/hw/vendor.qti.hardware.tui_comm@1.0-service-qti)
        "${PATCHELF}" --replace-needed "libhidlbase.so" "libhidlbase-v32.so" "${2}"
        ;;
    vendor/bin/hw/vendor.samsung.hardware.miscpower@1.0-service)
        "${PATCHELF}" --replace-needed "libhidlbase.so" "libhidlbase-v32.so" "${2}"
        ;;
    lib64/libpixelflinger.so)
        "${PATCHELF}" --replace-needed "libcutils.so" "libcutils-v29.so" "${2}"
        ;;
    vendor/lib/libsensorlistener.so|vendor/lib/libxt_native.so|vendor/lib64/libxt_native.so|vendor/lib64/libhypermotion_interface.so)
        "${PATCHELF}" --replace-needed "libandroid.so" "libsensorndkbridge.so" "${2}"
        ;;
    vendor/lib64/libmaet.so|vendor/lib64/libsxqk_skia.so)
        "${PATCHELF}" --replace-needed "libandroid.so" "libsensorndkbridge.so" "${2}"
        "${PATCHELF}" --replace-needed "libstdc++.so" "libstdc++_vendor.so" "${2}"
        ;;
    vendor/lib/W13QS_libTsAe.so|vendor/lib/lib_SamsungRec_06002.so|vendor/lib/libdejagging_core.so|vendor/lib/libTsAe.so|vendor/lib/libTsAccmFront.so|vendor/lib/libmmcamera_hdr_gb_lib.so|vendor/lib/W13QS_libTsAwb.so|vendor/lib/libTsAeFront.so|vendor/lib/libTsAf.so|vendor/lib/libTsAwb.so|vendor/lib/W13QS_libTsAccm.so|vendor/lib/W13QS_libTsAf.so|vendor/lib/libblurdetection.so|vendor/lib/libmmcamera_faceproc.so|vendor/lib/libimage_flashed_lls.so|vendor/lib/libTsAwbFront.so|vendor/lib/libTsAccm.so|vendor/lib/lib_SoundBooster_ver_Quad_710.so|vendor/lib/libsmartfocusengine.so|vendor/lib64/libdejagging_core.so|vendor/lib64/libblurdetection.so|vendor/lib64/libimage_flashed_lls.so|vendor/lib64/libsmartfocusengine.so)
        "${PATCHELF}" --replace-needed "libstdc++.so" "libstdc++_vendor.so" "${2}"
        ;;
    vendor/bin/pm-service)
        grep -q libutils-v33.so "${2}" || "${PATCHELF}" --add-needed "libutils-v33.so" "${2}"
        ;;
    esac
}

if [ -z "${ONLY_TARGET}" ]; then
    # Initialize the helper for common device
    setup_vendor "${DEVICE_COMMON}" "${VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${ONLY_COMMON}" ] && [ -s "${MY_DIR}/../${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../${DEVICE}/extract-files.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

    extract "${MY_DIR}/../${DEVICE}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

"${MY_DIR}/setup-makefiles.sh"
