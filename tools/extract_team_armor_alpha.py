#!/usr/bin/env python3
"""Derive review-only alpha evidence from the approved EQ-R1 v2 RGB source.

This is deliberately a narrow, deterministic extraction tool. It neither paints nor
reframes the source: the RGBA output retains every source RGB byte and replaces only
alpha with the reviewed sRGB rule alpha=clamp(4R - 4B - 0.1).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import platform
import sys
from pathlib import Path
from typing import Any

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = ROOT / "docs/art/team-prototype-20260912/EQ-R1-quadruped-armor-kit-raw-draft-v2.png"
DEFAULT_OUTPUT = ROOT / "docs/art/team-prototype-20260912/armor-alpha-v1"
ALGORITHM = "sRGB alpha = clamp(4R - 4B - 0.1), quantized to 8-bit alpha"
ALPHA_SUPPORT_THRESHOLD = 16
LIGHT_PAPER = (244, 235, 214, 255)
DARK_NAVY = (20, 31, 47, 255)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source_file:
        for chunk in iter(lambda: source_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest().upper()


def alpha_from_rgb(rgb: Image.Image) -> Image.Image:
    """Return the reviewed alpha mask without changing RGB source pixels."""
    if rgb.mode != "RGB":
        raise ValueError("alpha_from_rgb requires an RGB image")
    source = rgb.tobytes()
    alpha = bytearray(len(source) // 3)
    for pixel_index in range(len(alpha)):
        offset = pixel_index * 3
        red = source[offset]
        blue = source[offset + 2]
        # (4 * (R / 255 - B / 255) - 0.1) * 255 == 4R - 4B - 25.5.
        value = 4.0 * (red - blue) - 25.5
        alpha[pixel_index] = max(0, min(255, int(value + 0.5)))
    return Image.frombytes("L", rgb.size, bytes(alpha))


def rgba_with_extracted_alpha(rgb: Image.Image) -> Image.Image:
    alpha = alpha_from_rgb(rgb)
    rgba = rgb.convert("RGBA")
    rgba.putalpha(alpha)
    return rgba


def bounds_for_alpha(alpha: Image.Image, threshold: int) -> list[int] | None:
    if alpha.mode != "L":
        raise ValueError("bounds_for_alpha requires an L image")
    width, height = alpha.size
    pixels = alpha.load()
    left = width
    top = height
    right = -1
    bottom = -1
    count = 0
    for y in range(height):
        for x in range(width):
            if pixels[x, y] >= threshold:
                count += 1
                left = min(left, x)
                top = min(top, y)
                right = max(right, x)
                bottom = max(bottom, y)
    if count == 0:
        return None
    return [left, top, right + 1, bottom + 1]


def alpha_metrics(alpha: Image.Image) -> dict[str, Any]:
    values = alpha.tobytes()
    width, height = alpha.size
    corners = [
        alpha.getpixel((0, 0)),
        alpha.getpixel((width - 1, 0)),
        alpha.getpixel((0, height - 1)),
        alpha.getpixel((width - 1, height - 1)),
    ]
    return {
        "alpha_min": min(values),
        "alpha_max": max(values),
        "transparent_pixel_count": sum(value == 0 for value in values),
        "support_pixel_count_alpha_ge_16": sum(value >= ALPHA_SUPPORT_THRESHOLD for value in values),
        "support_bounds_alpha_ge_16": bounds_for_alpha(alpha, ALPHA_SUPPORT_THRESHOLD),
        "corner_alpha": corners,
    }


def composite(rgba: Image.Image, color: tuple[int, int, int, int]) -> Image.Image:
    background = Image.new("RGBA", rgba.size, color)
    return Image.alpha_composite(background, rgba)


def proof(rgba: Image.Image, color: tuple[int, int, int, int], size: int) -> Image.Image:
    """Center a contain-scaled equipment proof at an exact intended pixel size."""
    canvas = Image.new("RGBA", (size * 2, size * 2), color)
    resized = rgba.resize((size, size), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, (size // 2, size // 2))
    return canvas


def require_synthetic_threshold_tests() -> None:
    neutral = Image.new("RGB", (1, 1), (120, 120, 116))  # R-B=4 background noise.
    if alpha_from_rgb(neutral).getpixel((0, 0)) != 0:
        raise AssertionError("Neutral checkerboard noise must become transparent.")
    shell = Image.new("RGB", (1, 1), (180, 90, 120))
    if alpha_from_rgb(shell).getpixel((0, 0)) != 215:
        raise AssertionError("Known shell color alpha regression.")
    blue_dominant = Image.new("RGB", (1, 1), (90, 120, 180))
    if alpha_from_rgb(blue_dominant).getpixel((0, 0)) != 0:
        raise AssertionError("Blue-dominant background must become transparent.")


def output_paths(output_dir: Path) -> dict[str, Path]:
    return {
        "rgba": output_dir / "EQ-R1-quadruped-armor-alpha-v1.png",
        "full_light": output_dir / "EQ-R1-quadruped-armor-alpha-v1-light.png",
        "full_dark": output_dir / "EQ-R1-quadruped-armor-alpha-v1-dark.png",
        "proof_light_80": output_dir / "EQ-R1-quadruped-armor-alpha-v1-proof-light-80.png",
        "proof_dark_80": output_dir / "EQ-R1-quadruped-armor-alpha-v1-proof-dark-80.png",
        "proof_light_96": output_dir / "EQ-R1-quadruped-armor-alpha-v1-proof-light-96.png",
        "proof_dark_96": output_dir / "EQ-R1-quadruped-armor-alpha-v1-proof-dark-96.png",
        "provenance": output_dir / "provenance.json",
    }


def output_metadata(path: Path) -> dict[str, Any]:
    with Image.open(path) as image:
        return {
            "path": str(path.relative_to(ROOT)).replace("\\", "/"),
            "mode": image.mode,
            "dimensions": list(image.size),
            "sha256": sha256_file(path),
            "bytes": path.stat().st_size,
        }


def derive(source_path: Path, output_dir: Path, overwrite: bool) -> dict[str, Any]:
    require_synthetic_threshold_tests()
    if not source_path.is_file():
        raise FileNotFoundError(source_path)
    with Image.open(source_path) as opened:
        if opened.mode != "RGB":
            raise ValueError("EQ-R1 v2 must remain the approved RGB source.")
        source = opened.copy()
    if source.size != (1254, 1254):
        raise ValueError("EQ-R1 v2 dimensions changed; extraction must not crop or resize it.")

    paths = output_paths(output_dir)
    existing = [path for path in paths.values() if path.exists()]
    if existing and not overwrite:
        joined = ", ".join(str(path) for path in existing)
        raise FileExistsError("Refusing to overwrite existing evidence: " + joined)
    output_dir.mkdir(parents=True, exist_ok=True)

    rgba = rgba_with_extracted_alpha(source)
    rgba.save(paths["rgba"])
    composite(rgba, LIGHT_PAPER).convert("RGB").save(paths["full_light"])
    composite(rgba, DARK_NAVY).convert("RGB").save(paths["full_dark"])
    proof(rgba, LIGHT_PAPER, 80).convert("RGB").save(paths["proof_light_80"])
    proof(rgba, DARK_NAVY, 80).convert("RGB").save(paths["proof_dark_80"])
    proof(rgba, LIGHT_PAPER, 96).convert("RGB").save(paths["proof_light_96"])
    proof(rgba, DARK_NAVY, 96).convert("RGB").save(paths["proof_dark_96"])

    alpha = rgba.getchannel("A")
    metrics = alpha_metrics(alpha)
    if metrics["corner_alpha"] != [0, 0, 0, 0]:
        raise AssertionError("Transparent corners are required.")
    if metrics["support_bounds_alpha_ge_16"] is None:
        raise AssertionError("Extraction lost the equipment shell.")
    bounds = metrics["support_bounds_alpha_ge_16"]
    if bounds[0] == 0 or bounds[1] == 0 or bounds[2] == source.width or bounds[3] == source.height:
        raise AssertionError("Alpha support unexpectedly reaches an image edge.")
    source_rgb = source.tobytes()
    output_rgb = rgba.convert("RGB").tobytes()
    if output_rgb != source_rgb:
        raise AssertionError("Extraction changed source RGB pixels.")

    provenance = {
        "status": "review-only deterministic alpha derivative; no runtime promotion",
        "user_approval": {
            "date": "2026-09-12",
            "text": "User explicitly approved deterministic background removal preserving exact shape.",
        },
        "source": {
            "path": str(source_path.relative_to(ROOT)).replace("\\", "/"),
            "mode": source.mode,
            "dimensions": list(source.size),
            "sha256": sha256_file(source_path),
            "rgb_bytes_sha256": sha256_bytes(source_rgb),
        },
        "algorithm": {
            "description": ALGORITHM,
            "color_space": "sRGB",
            "negative_bias": 0.1,
            "source_rgb_preserved": True,
            "no_crop_repaint_or_reshaping": True,
        },
        "verification": {
            "synthetic_threshold_tests": "passed",
            "rgba_dimensions": list(rgba.size),
            "rgba_mode": rgba.mode,
            "rgba_rgb_bytes_sha256": sha256_bytes(output_rgb),
            "rgb_matches_source": output_rgb == source_rgb,
            "alpha": metrics,
            "transparent_corners": True,
        },
        "outputs": {
            name: output_metadata(path)
            for name, path in paths.items()
            if name != "provenance"
        },
        "tool": {
            "python": sys.version.split()[0],
            "pillow": Image.__version__,
            "platform": platform.platform(),
        },
        "rejected_history": {
            "v3": "EQ-R1-quadruped-armor-alpha-attempt-v3.png remains an RGB failed-alpha draft; it was not read or used.",
            "old_humanoid": "assets/armor/raw/full_suit_raw_print_alpha_v2.png remains rejected and was not read or used.",
        },
    }
    paths["provenance"].write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
    return provenance


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    require_synthetic_threshold_tests()
    if args.self_test:
        print("TEAM_ARMOR_ALPHA synthetic_threshold_tests=passed")
        return 0
    source_path = args.source.resolve()
    if source_path != DEFAULT_SOURCE.resolve():
        raise ValueError("This approved derivation accepts only EQ-R1 quadruped armor v2.")
    provenance = derive(source_path, args.output_dir.resolve(), args.overwrite)
    print(
        "TEAM_ARMOR_ALPHA source_sha256=%s output_sha256=%s bounds=%s"
        % (
            provenance["source"]["sha256"],
            provenance["outputs"]["rgba"]["sha256"],
            provenance["verification"]["alpha"]["support_bounds_alpha_ge_16"],
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
