#!/usr/bin/env python3
"""Patch Samsung's AEC event handler to avoid a post-enqueue use-after-free."""

import os
import sys
import tempfile
from pathlib import Path


# aec_port_ext_handle_module_event() reads the heap-owned q3a message twice to
# decide whether it must release a circular statistics buffer.  The second read
# happens after q3a_aecawb_thread_en_q_msg() has transferred ownership, so the
# worker can free the message first.  Preserve (message_type - 3) in callee-saved
# r4 before the enqueue and use that preserved value afterwards.  r4 held the
# mutex address earlier, but that value is dead after pthread_mutex_unlock().
OFFSET = 0x3309A
ORIGINAL = bytes.fromhex(
    "30 68 03 38 02 28 04 d8 40 46 ca f8 44 80 1f f0 e4 f9 "
    "43 f2 c8 5a 31 46 55 f8 0a 00 1f f0 1d f9 48 b9 "
    "30 68 03 38 02 28"
)
REPLACEMENT = bytes.fromhex(
    "34 68 03 3c 02 2c 04 d8 40 46 ca f8 44 80 1f f0 e4 f9 "
    "43 f2 c8 5a 31 46 55 f8 0a 00 1f f0 1d f9 48 b9 "
    "20 46 00 bf 02 28"
)


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: {Path(sys.argv[0]).name} ELF")

    path = Path(sys.argv[1])
    data = bytearray(path.read_bytes())
    if data[:4] != b"\x7fELF":
        raise SystemExit(f"{path}: not an ELF file")

    actual = bytes(data[OFFSET : OFFSET + len(ORIGINAL)])
    if actual == REPLACEMENT:
        return 0
    if actual != ORIGINAL:
        raise SystemExit(
            f"{path}: unexpected AEC instruction block at {OFFSET:#x}: "
            f"{actual.hex(' ')}"
        )
    if data.count(ORIGINAL) != 1:
        raise SystemExit(f"{path}: AEC instruction block is not unique")

    data[OFFSET : OFFSET + len(ORIGINAL)] = REPLACEMENT
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
