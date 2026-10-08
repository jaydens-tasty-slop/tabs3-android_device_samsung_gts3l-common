/*
 * Copyright (C) 2019,2021 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/strings.h>
#include <unistd.h>

#include "KeyDisabler.h"

using ::android::base::ReadFileToString;
using ::android::base::Trim;
using ::android::base::WriteStringToFile;

namespace aidl {
namespace vendor {
namespace lineage {
namespace touch {

constexpr const char kControlPath[] = "/sys/class/sec/sec_touchkey/input/enabled";

KeyDisabler::KeyDisabler() : has_key_disabler_(!access(kControlPath, R_OK | W_OK)) {}

ndk::ScopedAStatus KeyDisabler::getEnabled(bool* enabled) {
    std::string buf;
    *enabled = false;
    if (!has_key_disabler_) return ndk::ScopedAStatus::fromExceptionCode(EX_UNSUPPORTED_OPERATION);

    if (!ReadFileToString(kControlPath, &buf, true)) {
        LOG(ERROR) << "Failed to read from " << kControlPath;
        return ndk::ScopedAStatus::fromServiceSpecificError(errno);
    }

    // This node enables the physical keys. The HAL enables their disabling.
    *enabled = Trim(buf) == "0";
    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus KeyDisabler::setEnabled(bool enabled) {
    if (!has_key_disabler_) return ndk::ScopedAStatus::fromExceptionCode(EX_UNSUPPORTED_OPERATION);

    if (!WriteStringToFile(std::to_string(!enabled), kControlPath)) {
        LOG(ERROR) << "Failed to write to " << kControlPath;
        return ndk::ScopedAStatus::fromServiceSpecificError(errno);
    }

    return ndk::ScopedAStatus::ok();
}

}  // namespace touch
}  // namespace lineage
}  // namespace vendor
}  // namespace aidl
