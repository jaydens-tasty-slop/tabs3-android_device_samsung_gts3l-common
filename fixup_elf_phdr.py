#!/usr/bin/env python3
"""Correct patchelf's PT_PHDR address for a legacy ARM ELF with a nonzero base."""
import argparse
import pathlib
import struct


def inspect(data):
    if data[:6] != b"\x7fELF\x01\x01" or len(data) < 52:
        raise ValueError("Expected little-endian ELF32")
    if struct.unpack_from("<HH", data, 16) != (3, 40):
        raise ValueError("Expected ARM ET_DYN")
    offset = struct.unpack_from("<I", data, 28)[0]
    size, count = struct.unpack_from("<HH", data, 42)
    if size != 32 or not 1 <= count <= 128 or offset + size*count > len(data):
        raise ValueError("Invalid ELF program header table")
    entries = [(offset+i*size, struct.unpack_from("<IIIIIIII", data, offset+i*size)) for i in range(count)]
    phdrs = [(at, p) for at, p in entries if p[0] == 6]
    loads = [p for at, p in entries if p[0] == 1]
    if len(phdrs) != 1:
        raise ValueError("Expected one PT_PHDR")
    at, phdr = phdrs[0]
    owners = [p for p in loads if p[1] <= offset and offset + count*size <= p[1]+p[4]]
    if len(owners) != 1 or phdr[1] != offset or phdr[4] != count*size or phdr[5] != count*size:
        raise ValueError("PT_PHDR table is not backed by exactly one LOAD segment")
    address = owners[0][2] + offset - owners[0][1]
    for p in loads:
        if p[4] > p[5] or p[1]+p[4] > len(data) or (p[7] > 1 and p[1] % p[7] != p[2] % p[7]):
            raise ValueError("Invalid LOAD mapping")
    dynamic = [p for at, p in entries if p[0] == 2]
    if len(dynamic) != 1 or not any(p[1] <= dynamic[0][1] and dynamic[0][1]+dynamic[0][4] <= p[1]+p[4]
                                  and p[2]+dynamic[0][1]-p[1] == dynamic[0][2] for p in loads):
        raise ValueError("PT_DYNAMIC is not backed by a LOAD segment")
    return at, phdr, address


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("elf", type=pathlib.Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    path = args.elf
    if not path.is_file() or path.is_symlink():
        raise ValueError("A regular ELF file is required")
    before = path.read_bytes()
    at, phdr, address = inspect(before)
    if args.check:
        if phdr[2] != address or phdr[3] != address:
            raise ValueError("PT_PHDR address disagrees with its actual LOAD mapping")
        print("ELF PT_PHDR/PT_DYNAMIC mappings verified")
        return
    after = bytearray(before)
    struct.pack_into("<II", after, at+8, address, address)
    if after[:at+8] != before[:at+8] or after[at+16:] != before[at+16:]:
        raise ValueError("Unexpected bytes changed")
    _, corrected, expected = inspect(after)
    if corrected[2] != expected or corrected[3] != expected:
        raise ValueError("Corrected PT_PHDR did not verify")
    if after != before:
        path.write_bytes(after)
        print("Corrected only PT_PHDR virtual/physical address fields: " + hex(phdr[2]) + " -> " + hex(address))
    else:
        print("ELF PT_PHDR already correct")


if __name__ == "__main__":
    main()
