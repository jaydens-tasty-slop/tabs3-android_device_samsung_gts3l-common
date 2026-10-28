#!/usr/bin/env python3
"""Patch Samsung's primary audio HAL to stop a stream-close use-after-free."""

import os
import struct
import sys
import tempfile
from pathlib import Path


# adev_close_output_stream() frees the 96-byte Samsung per-stream state at
# out+0x2024 right after unregistering the stream, then runs standby and
# offload teardown, and finally reloads that dangling pointer to free and clear
# its +0x20 member.  When the heap reuses the block in between, free() receives
# garbage and the HAL crashes in je_free during boot-time stream churn.  Drop
# the early free and release the member and then the state itself at the end.
# r10 keeps &out->state for the whole function; free(NULL) is a no-op.
PATCHES = (
    (
        0x17FF8,
        bytes.fromhex(
            "24 00 02 e3 00 00 ba e7 00 00 50 e3 00 00 00 0a 57 c9 ff eb"
        ),
        bytes.fromhex(
            "24 00 02 e3 00 00 ba e7 00 00 50 e3 00 00 00 0a 00 f0 20 e3"
        ),
    ),
    (
        0x18334,
        bytes.fromhex(
            "00 00 9a e5 20 00 90 e5 00 00 50 e3 03 00 00 0a "
            "88 c8 ff eb 00 00 9a e5 00 10 a0 e3 20 10 80 e5"
        ),
        bytes.fromhex(
            "00 00 9a e5 00 00 50 e3 04 00 00 0a 20 00 90 e5 "
            "88 c8 ff eb 00 00 9a e5 86 c8 ff eb 00 f0 20 e3"
        ),
    ),
)


def file_offset(data: bytes, vaddr: int) -> int:
    phoff, = struct.unpack_from("<I", data, 0x1C)
    phentsize, phnum = struct.unpack_from("<HH", data, 0x2A)
    for index in range(phnum):
        p_type, p_offset, p_vaddr, _, p_filesz = struct.unpack_from(
            "<5I", data, phoff + index * phentsize
        )
        if p_type == 1 and p_vaddr <= vaddr < p_vaddr + p_filesz:
            return vaddr - p_vaddr + p_offset
    raise SystemExit(f"{vaddr:#x} is not in a PT_LOAD segment")


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: {Path(sys.argv[0]).name} ELF")

    path = Path(sys.argv[1])
    data = bytearray(path.read_bytes())
    if data[:4] != b"\x7fELF" or data[4] != 1:
        raise SystemExit(f"{path}: not a 32-bit ELF file")

    changed = False
    for vaddr, original, replacement in PATCHES:
        offset = file_offset(data, vaddr)
        actual = bytes(data[offset : offset + len(original)])
        if actual == replacement:
            continue
        if actual != original:
            raise SystemExit(
                f"{path}: unexpected close_output_stream block at {vaddr:#x}: "
                f"{actual.hex(' ')}"
            )
        if data.count(original) != 1:
            raise SystemExit(f"{path}: block at {vaddr:#x} is not unique")
        data[offset : offset + len(original)] = replacement
        changed = True

    if not changed:
        return 0

    fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as temporary:
            temporary.write(data)
            temporary.flush()
            os.fsync(temporary.fileno())
        os.chmod(temporary_name, path.stat().st_mode)
        os.replace(temporary_name, path)
    finally:
        if os.path.exists(temporary_name):
            os.unlink(temporary_name)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
