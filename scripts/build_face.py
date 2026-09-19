#!/usr/bin/env python3
"""Build the unchanged Lua face with an explicitly supplied EasyFace compiler.

Requires Python 3 and EasyFace Gen2 Compiler v4.23 (Compiler.exe and DeviceInfo.db).
On macOS/Linux, Wine is required; on Windows, the executable runs directly.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zlib

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "MiBand10BinaryDotClock.fprj"


def png(path, width, height, pixels):
    def chunk(tag, payload):
        return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", zlib.crc32(tag + payload) & 0xffffffff)
    scan = b"".join(b"\0" + bytes(pixels[y * width * 3:(y + 1) * width * 3]) for y in range(height))
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(scan)) + chunk(b"IEND", b""))


def make_preview(path):
    cfg = json.loads((ROOT / "src/watchface-config.json").read_text())
    w, h = cfg["canvas"]["width"], cfg["canvas"]["height"]
    assert (w, h) == (212, 520)
    dots = [cfg["layout"]["x"]["amPm"], *cfg["layout"]["x"]["hour"], *cfg["layout"]["x"]["minute"]]
    diameter, y = cfg["layout"]["dotDiameter"], cfg["layout"]["y"]
    pixels = bytearray(w * h * 3)
    # Representative preview at 7:25 AM; bitmap does not replace the Lua UI.
    states = [False, *[bool(7 & (1 << i)) for i in range(4)], *[bool(25 & (1 << i)) for i in range(6)]]
    for x, active in zip(dots, states):
        color = bytes.fromhex(cfg["colors"]["on" if active else "off"][1:])
        for py in range(y, y + diameter):
            for px in range(x, x + diameter):
                if (px - x - 5.5) ** 2 + (py - y - 5.5) ** 2 <= 36:
                    pixels[(py * w + px) * 3:(py * w + px) * 3 + 3] = color
    png(path, w, h, pixels)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--compiler", type=Path, required=True, help="EasyFace v4.23 Compiler.exe")
    ap.add_argument("--device-db", type=Path, help="DeviceInfo.db; defaults to Compiler.exe directory")
    args = ap.parse_args()
    compiler = args.compiler.resolve()
    db = (args.device_db or compiler.with_name("DeviceInfo.db")).resolve()
    if not compiler.is_file() or not db.is_file():
        ap.error("Compiler.exe and DeviceInfo.db from EasyFace v4.23 are required")
    device = next((d for d in ET.parse(db).getroot().findall("DeviceInfo") if d.get("Name") == "Mi Band 10"), None)
    if device is None or (device.get("Type"), device.get("Width"), device.get("Height")) != ("466", "212", "520"):
        ap.error("Compiler's device DB does not match the regular 212x520 Mi Band 10 (Type 466)")
    project = ET.parse(PROJECT)
    screen = project.getroot().find("Screen")
    widget = screen.find("Widget") if screen is not None else None
    if project.getroot().get("DeviceType") != "466" or widget is None or widget.get("Shape") != "34" or widget.get("Name") != "app_lua%2Fmain.lua":
        ap.error("unexpected FPRJ device or Lua widget; refusing to build")
    if os.name == "nt":
        runner = [str(compiler)]
    else:
        wine = shutil.which("wine")
        if not wine:
            ap.error("EasyFace's compiler is Windows-only; use Windows or install Wine locally")
        runner = [wine, str(compiler)]
    out = ROOT / "dist"
    out.mkdir(exist_ok=True)
    face = out / "MiBand10BinaryDotClock.face"
    face.unlink(missing_ok=True)
    with tempfile.TemporaryDirectory(prefix="band10-lua-") as temp:
        work = Path(temp)
        (work / "app/lua").mkdir(parents=True)
        shutil.copy2(ROOT / "app/lua/main.lua", work / "app/lua/main.lua")
        make_preview(work / "preview.png")
        # The example FPRJ declares UTF-16; write actual UTF-16 bytes for the compiler.
        project.write(work / PROJECT.name, encoding="utf-16", xml_declaration=True)
        name = "MiBand10BinaryDotClock.face"
        command = [*runner, "-b", str(work / PROJECT.name), str(out), name, "1461256429"]
        subprocess.run(command, cwd=compiler.parent, check=True)
    if not face.is_file() or face.stat().st_size < 64:
        raise SystemExit("Compiler returned without a usable .face file")
    data = face.read_bytes()
    if data[:4] != bytes.fromhex("5aa53412"):
        raise SystemExit("Unexpected face header; do not install this file")
    binary = face.with_suffix(".bin")
    shutil.copyfile(face, binary)
    print(f"{face} ({len(data)} bytes)\n{binary} (identical alias)\nSHA-256 {hashlib.sha256(data).hexdigest()}")
    print("Packaging only: device/firmware compatibility and Lua runtime remain unverified until on-band test.")


if __name__ == "__main__":
    main()
