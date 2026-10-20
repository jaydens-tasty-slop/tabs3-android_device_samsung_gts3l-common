#!/usr/bin/env python3
"""Patch Samsung's AF event handler to avoid a post-enqueue use-after-free."""

import os
import sys
import tempfile
from pathlib import Path


# af_port_ext_handle_module_event() copies the synchronous module-event payload
# into a heap message and hands that message to q3a_aecawb_thread_en_q_msg(). It
# then reads the handed-off buffer three more times. The consumer can free the
# message concurrently. Read those same fields from the original synchronous
# event payload (r11) instead; it remains owned by the caller until this handler
# returns. Each change is only the Thumb base register r10 -> r11.
PATCHES = (
    (0x22910, bytes.fromhex("9a ed 31 0a"), bytes.fromhex("9b ed 31 0a")),
    (0x22924, bytes.fromhex("da f8 04 01"), bytes.fromhex("db f8 04 01")),
    (0x22978, bytes.fromhex("da f8 04 11"), bytes.fromhex("db f8 04 11")),
)


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: {Path(sys.argv[0]).name} ELF")

    path = Path(sys.argv[1])
    data = bytearray(path.read_bytes())
    if data[:4] != b"\x7fELF":
        raise SystemExit(f"{path}: not an ELF file")

    changed = False
    for offset, original, replacement in PATCHES:
        actual = bytes(data[offset : offset + len(original)])
        if actual == replacement:
            continue
        if actual != original:
            raise SystemExit(
                f"{path}: unexpected bytes at {offset:#x}: {actual.hex(' ')}"
            )
        if data.count(original) != 1:
            raise SystemExit(f"{path}: instruction signature is not unique: {original.hex(' ')}")
        data[offset : offset + len(original)] = replacement
        changed = True

    if changed:
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
