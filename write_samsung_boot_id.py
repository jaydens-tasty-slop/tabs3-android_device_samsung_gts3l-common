#!/usr/bin/env python3
# Copyright (C) 2026 Tab S3 ROM Builder
# SPDX-License-Identifier: Apache-2.0
"""Preserve the legacy v0/dt_size boot ID used by the working Samsung ROM."""
import hashlib
import pathlib
import struct
import sys

path = pathlib.Path(sys.argv[1])
data = bytearray(path.read_bytes())
if len(data) < 1632 or data[:8] != b"ANDROID!":
    raise SystemExit("Not an Android boot image")
kernel, _, ramdisk, _, second, _, _, page, version = struct.unpack_from("<9I", data, 8)
if version != 0 or page != 4096 or second != 0:
    raise SystemExit("Unexpected SM-T820 boot image layout")
offset = page
digest = hashlib.sha1()
for size in (kernel, ramdisk, second):
    if offset + size > len(data):
        raise SystemExit("Truncated boot image payload")
    digest.update(data[offset:offset + size])
    digest.update(struct.pack("<I", size))
    offset += ((size + page - 1) // page) * page
# Legacy mkbootimg includes the v0 dt_size field in the boot ID, even when
# the DTBs are appended to Image.gz-dtb and dt_size is zero. The owner's
# original 20240309 ROM has this exact convention.
digest.update(struct.pack("<I", 0))
data[576:608] = digest.digest() + bytes(12)
path.write_bytes(data)
