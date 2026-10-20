#!/usr/bin/env python3
"""Patch Samsung's AF set-parameter handler to preserve sync ownership."""

import os
import sys
import tempfile
from pathlib import Path


# af_port_handle_set_parm_event() hands af_msg to q3a_af_thread_en_q_msg(),
# then reads af_msg->sync_flag to decide whether the producer must free a
# synchronous message.  The asynchronous AF worker can consume and free the
# message before that read.  Qualcomm's later source fixes the race by copying
# sync_flag before enqueue.  Preserve it in callee-saved r5 and use that copy
# afterward.  The address-load rewrite creates the two bytes needed for the
# extra load while resolving the identical af_port->thread_data address.
PRE_ENQUEUE_OFFSET = 0x2E872
PRE_ENQUEUE_ORIGINAL = bytes.fromhex(
    "49 f6 28 40 21 46 c0 f2 01 00 59 f8 00 00"
)
PRE_ENQUEUE_REPLACEMENT = bytes.fromhex(
    "65 68 21 46 09 f5 c8 30 d0 f8 28 0c 00 bf"
)

POST_ENQUEUE_OFFSET = 0x2E8AE
POST_ENQUEUE_ORIGINAL = bytes.fromhex(
    "60 68 01 28 02 d1 20 46 23 f0 e5 fb"
)
POST_ENQUEUE_REPLACEMENT = bytes.fromhex(
    "28 46 01 28 02 d1 20 46 23 f0 e5 fb"
)

PATCHES = (
    (PRE_ENQUEUE_OFFSET, PRE_ENQUEUE_ORIGINAL, PRE_ENQUEUE_REPLACEMENT),
    (POST_ENQUEUE_OFFSET, POST_ENQUEUE_ORIGINAL, POST_ENQUEUE_REPLACEMENT),
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
            raise SystemExit(
                f"{path}: instruction signature is not unique: {original.hex(' ')}"
            )
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
