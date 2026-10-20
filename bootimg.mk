# Copyright (C) 2017 The LineageOS Project
# Copyright (C) 2026 Tab S3 ROM Builder
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

# SM-T820 uses boot header v0 with appended device trees. Its Samsung
# bootloader also expects the marker preserved by hardware/samsung on LOS 21.
$(INSTALLED_BOOTIMAGE_TARGET): $(MKBOOTIMG) $(INTERNAL_BOOTIMAGE_FILES) $(BOOTIMAGE_EXTRA_DEPS) $(INSTALLED_KERNEL_TARGET) $(COMMON_PATH)/write_samsung_boot_id.py
	$(call pretty,"Target Samsung boot image: $@")
	$(hide) $(MKBOOTIMG) --kernel $(call bootimage-to-kernel,$@) $(INTERNAL_BOOTIMAGE_ARGS) $(INTERNAL_MKBOOTIMG_VERSION_ARGS) $(BOARD_MKBOOTIMG_ARGS) --output $@
	$(hide) /usr/bin/python3 $(COMMON_PATH)/write_samsung_boot_id.py $@
	$(hide) printf SEANDROIDENFORCE >> $@
	$(hide) $(call assert-max-image-size,$@,$(BOARD_BOOTIMAGE_PARTITION_SIZE),raw)

$(INSTALLED_RECOVERYIMAGE_TARGET): $(MKBOOTIMG) $(recovery_ramdisk) $(recovery_kernel) $(RECOVERYIMAGE_EXTRA_DEPS) $(COMMON_PATH)/write_samsung_boot_id.py
	$(call pretty,"Target Samsung recovery image: $@")
	$(hide) $(MKBOOTIMG) $(INTERNAL_RECOVERYIMAGE_ARGS) $(INTERNAL_MKBOOTIMG_VERSION_ARGS) $(BOARD_MKBOOTIMG_ARGS) --output $@
	$(hide) /usr/bin/python3 $(COMMON_PATH)/write_samsung_boot_id.py $@
	$(hide) printf SEANDROIDENFORCE >> $@
	$(hide) $(call assert-max-image-size,$@,$(BOARD_RECOVERYIMAGE_PARTITION_SIZE),raw)
