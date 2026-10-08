/*
 * Copyright (C) 2019 The LineageOS Project
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

#define LOG_TAG "vendor.lineage.touch-service.gts3l"

#include <android-base/logging.h>
#include <android/binder_manager.h>
#include <android/binder_process.h>
#include "KeyDisabler.h"

using aidl::vendor::lineage::touch::KeyDisabler;

int main() {
    ABinderProcess_setThreadPoolMaxThreadCount(0);
    auto keyDisabler = ndk::SharedRefBase::make<KeyDisabler>();
    const std::string instance = std::string(KeyDisabler::descriptor) + "/default";
    const auto status = AServiceManager_addService(keyDisabler->asBinder().get(), instance.c_str());
    CHECK_EQ(status, STATUS_OK) << "Failed to register " << instance;
    ABinderProcess_joinThreadPool();
    return 1;
}
