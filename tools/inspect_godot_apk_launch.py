"""Read-only, bounded ECFG launch-path audit; does not launch or extract the APK."""

import argparse
import hashlib
import json
import struct
import zipfile
from pathlib import Path


MAX_CONFIG_BYTES = 32 * 1024 * 1024


def read_strings(blob):
    if len(blob) > MAX_CONFIG_BYTES or blob[:4] != b"ECFG":
        raise ValueError("Invalid or oversized project.binary envelope")
    offset = 4

    def take(size):
        nonlocal offset
        if size < 0 or offset + size > len(blob):
            raise ValueError("Truncated project.binary")
        result = blob[offset : offset + size]
        offset += size
        return result

    def u32():
        return struct.unpack("<I", take(4))[0]

    count = u32()
    if count > 100_000:
        raise ValueError("Excessive property count")
    keys = set()
    strings = {}
    for _ in range(count):
        key_length = u32()
        if key_length > 65_536:
            raise ValueError("Excessive property key length")
        key = take(key_length).decode("utf-8", errors="strict")
        if key in keys:
            raise ValueError("Duplicate property key")
        keys.add(key)
        value_length = u32()
        value = take(value_length)
        if len(value) < 4:
            raise ValueError("Missing Variant header")
        variant_type = struct.unpack_from("<I", value)[0]
        if variant_type != 4:
            continue
        if len(value) < 8:
            raise ValueError("Truncated String Variant")
        length = struct.unpack_from("<I", value, 4)[0]
        padded_length = (length + 3) & ~3
        if len(value) != 8 + padded_length:
            raise ValueError("String Variant length mismatch")
        if any(value[8 + length :]):
            raise ValueError("Nonzero String Variant padding")
        strings[key] = value[8 : 8 + length].decode("utf-8", errors="strict")
    if offset != len(blob):
        raise ValueError("Trailing project.binary bytes")
    return strings


def inspect(apk, expected_main, expected_feature):
    with zipfile.ZipFile(apk) as archive:
        entries = archive.infolist()
        names = [entry.filename for entry in entries]
        if len(names) != len(set(names)):
            raise ValueError("Duplicate APK entry names")
        config = archive.getinfo("assets/project.binary")
        if config.file_size > MAX_CONFIG_BYTES:
            raise ValueError("Oversized packaged project.binary")
        values = read_strings(archive.read(config))
        main_scene = values.get("application/run/main_scene", "")
        features = values.get("_custom_features", "").split(",")
        if main_scene != expected_main:
            raise ValueError(f"Wrong launch scene: {main_scene!r}")
        if expected_feature not in features:
            raise ValueError(f"Missing launch feature: {expected_feature!r}")
        if expected_feature == "team_prototype" and "unified_playtest" in features:
            raise ValueError("Legacy unified_playtest feature is still enabled")
        remap = "assets/" + main_scene.removeprefix("res://") + ".remap"
        if remap not in names:
            raise ValueError("Main scene resource remap is absent")
        payload = archive.read(remap)
        if len(payload) > 65_536:
            raise ValueError("Oversized scene remap")
        targets = []
        for line in payload.decode("utf-8", errors="strict").splitlines():
            if line.startswith('path="res://') and line.endswith('"'):
                targets.append("assets/" + line[12:-1])
        if len(targets) != 1 or targets[0] not in names:
            raise ValueError("Compiled main scene remap target is absent/ambiguous")
    with Path(apk).open("rb") as source:
        digest = hashlib.file_digest(source, "sha256").hexdigest().upper()
    return {
        "apk": str(Path(apk).resolve()),
        "bytes": Path(apk).stat().st_size,
        "sha256": digest,
        "main_scene": main_scene,
        "features": features,
        "compiled_scene": targets[0],
        "passed": True,
        "scope": "Archive launch-path only; not Android execution or UI acceptance",
    }


def self_test():
    def envelope(pairs):
        result = b"ECFG" + struct.pack("<I", len(pairs))
        for key, text in pairs:
            key = key.encode()
            text = text.encode()
            value = struct.pack("<II", 4, len(text)) + text + b"\0" * (-len(text) % 4)
            result += struct.pack("<I", len(key)) + key + struct.pack("<I", len(value)) + value
        return result

    valid = envelope([("application/run/main_scene", "res://scenes/team_prototype.tscn")])
    assert read_strings(valid)["application/run/main_scene"] == "res://scenes/team_prototype.tscn"
    malformed = [b"", valid[:-1], valid + b"x", envelope([("a", "b"), ("a", "c")]),
                 envelope([("a", "b")])[:-1] + b"x"]
    for candidate in malformed:
        try:
            read_strings(candidate)
        except ValueError:
            continue
        raise AssertionError("Malformed ECFG was accepted")
    print("ECFG_SELF_TEST cases=6 failures=0")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", type=Path)
    parser.add_argument("--expect-main", default="res://scenes/team_prototype.tscn")
    parser.add_argument("--expect-feature", default="team_prototype")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    if args.apk:
        print(json.dumps(inspect(args.apk, args.expect_main, args.expect_feature), indent=2))
    elif not args.self_test:
        parser.error("Specify --apk or --self-test")
