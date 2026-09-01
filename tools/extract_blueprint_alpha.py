#!/usr/bin/env python3
"""Create deterministic, preproduction alpha-calibration evidence for blueprint ink.

Only alpha is calibrated. Retained RGB values are copied byte-for-byte from the
selected opaque ImageGen source. The tool intentionally uses the Python standard
library only so calibration is reproducible without a graphics editor or download.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
import zlib
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def png_chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def load_rgb_png(path: Path) -> tuple[int, int, bytearray]:
    """Read the non-interlaced 8-bit RGB ImageGen PNG form without dependencies."""
    raw = path.read_bytes()
    if not raw.startswith(PNG_SIGNATURE):
        raise ValueError("not a PNG")
    cursor = len(PNG_SIGNATURE)
    width = height = 0
    bit_depth = color_type = compression = filter_method = interlace = None
    idat: list[bytes] = []
    while cursor < len(raw):
        if cursor + 12 > len(raw):
            raise ValueError("truncated PNG chunk")
        length = struct.unpack(">I", raw[cursor : cursor + 4])[0]
        kind = raw[cursor + 4 : cursor + 8]
        data = raw[cursor + 8 : cursor + 8 + length]
        if len(data) != length:
            raise ValueError("truncated PNG chunk data")
        cursor += 12 + length
        if kind == b"IHDR":
            width, height, bit_depth, color_type, compression, filter_method, interlace = struct.unpack(">IIBBBBB", data)
        elif kind == b"IDAT":
            idat.append(data)
        elif kind == b"IEND":
            break
    if (bit_depth, color_type, compression, filter_method, interlace) != (8, 2, 0, 0, 0):
        raise ValueError("expected non-interlaced 8-bit RGB PNG")
    stride = width * 3
    packed = zlib.decompress(b"".join(idat))
    if len(packed) != height * (stride + 1):
        raise ValueError("unexpected decompressed PNG length")
    output = bytearray(width * height * 3)
    previous = bytearray(stride)
    offset = 0
    for y in range(height):
        filter_type = packed[offset]
        offset += 1
        encoded = packed[offset : offset + stride]
        offset += stride
        row = bytearray(stride)
        for x, encoded_value in enumerate(encoded):
            left = row[x - 3] if x >= 3 else 0
            above = previous[x]
            upper_left = previous[x - 3] if x >= 3 else 0
            if filter_type == 0:
                value = encoded_value
            elif filter_type == 1:
                value = (encoded_value + left) & 0xFF
            elif filter_type == 2:
                value = (encoded_value + above) & 0xFF
            elif filter_type == 3:
                value = (encoded_value + ((left + above) >> 1)) & 0xFF
            elif filter_type == 4:
                p = left + above - upper_left
                pa, pb, pc = abs(p - left), abs(p - above), abs(p - upper_left)
                predictor = left if pa <= pb and pa <= pc else above if pb <= pc else upper_left
                value = (encoded_value + predictor) & 0xFF
            else:
                raise ValueError(f"unsupported PNG row filter {filter_type}")
            row[x] = value
        output[y * stride : (y + 1) * stride] = row
        previous = row
    return width, height, output


def write_png(path: Path, width: int, height: int, channels: int, pixels: bytes) -> None:
    if channels not in (3, 4) or len(pixels) != width * height * channels:
        raise ValueError("invalid RGB/RGBA PNG dimensions")
    stride = width * channels
    scanlines = bytearray()
    for y in range(height):
        scanlines.append(0)
        scanlines.extend(pixels[y * stride : (y + 1) * stride])
    color_type = 2 if channels == 3 else 6
    payload = PNG_SIGNATURE + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, color_type, 0, 0, 0)) + png_chunk(b"IDAT", zlib.compress(bytes(scanlines), 9)) + png_chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(payload)


def is_cyan_ink(r: int, g: int, b: int, cyan_delta: int) -> bool:
    return g - r >= cyan_delta and b - r >= cyan_delta and g >= 140 and b >= 140


def paper_alpha(r: int, g: int, b: int, neutral_brightness: int, neutral_chroma: int, taper_brightness: int, taper_chroma: int, cyan_delta: int) -> int:
    """Keep dark/colored ink; remove bright ivory paper even within closed contours."""
    brightness = (r + g + b) // 3
    chroma = max(r, g, b) - min(r, g, b)
    if is_cyan_ink(r, g, b, cyan_delta):
        return 255
    if brightness >= neutral_brightness and chroma <= neutral_chroma:
        return 0
    if brightness >= taper_brightness and chroma <= taper_chroma:
        chroma_coverage = (chroma - neutral_chroma) / max(1, taper_chroma - neutral_chroma)
        dark_coverage = (neutral_brightness - brightness) / max(1, neutral_brightness - taper_brightness)
        return int(round(255 * max(0.0, min(1.0, max(chroma_coverage, dark_coverage)))))
    return 255


def datum_band(rgb: bytearray, width: int, height: int, cyan_delta: int) -> tuple[list[int], int]:
    """Find one contiguous near-full-width cyan row band without a manual crop."""
    threshold = int(width * 0.72)
    rows_and_counts: list[tuple[int, int]] = []
    for y in range(height):
        count = 0
        for x in range(width):
            i = (y * width + x) * 3
            if is_cyan_ink(rgb[i], rgb[i + 1], rgb[i + 2], cyan_delta):
                count += 1
        if count >= threshold:
            rows_and_counts.append((y, count))
    bands: list[list[tuple[int, int]]] = []
    for item in rows_and_counts:
        if bands and item[0] == bands[-1][-1][0] + 1:
            bands[-1].append(item)
        else:
            bands.append([item])
    if not bands:
        return [], threshold
    best = max(bands, key=lambda band: (len(band), sum(value for _, value in band), -band[0][0]))
    return [row for row, _ in best], threshold


def illustration_bounds(rgb: bytearray, alpha: bytearray, width: int, height: int, datum_rows: set[int], cyan_delta: int) -> tuple[int, int]:
    """Derive illustration span from retained non-datum ink rather than painting a crop."""
    x_min, x_max = width, -1
    for pixel, value in enumerate(alpha):
        if value == 0:
            continue
        y, x = divmod(pixel, width)
        if y in datum_rows:
            continue
        i = pixel * 3
        if is_cyan_ink(rgb[i], rgb[i + 1], rgb[i + 2], cyan_delta):
            continue
        x_min, x_max = min(x_min, x), max(x_max, x)
    return (0, width - 1) if x_max < x_min else (x_min, x_max)


def extract_paper_through_ink(rgb: bytearray, width: int, height: int, neutral_brightness: int = 224, neutral_chroma: int = 36, taper_brightness: int = 184, taper_chroma: int = 62, cyan_delta: int = 50, datum_alpha: int = 112) -> tuple[bytearray, dict[str, object]]:
    """Apply paper-through alpha, then clip/subdue the one selected cyan datum band."""
    total = width * height
    alpha = bytearray(total)
    initial = {"zero": 0, "partial": 0, "opaque": 0}
    for pixel in range(total):
        i = pixel * 3
        value = paper_alpha(rgb[i], rgb[i + 1], rgb[i + 2], neutral_brightness, neutral_chroma, taper_brightness, taper_chroma, cyan_delta)
        alpha[pixel] = value
        initial["zero" if value == 0 else "partial" if value < 255 else "opaque"] += 1

    rows, row_threshold = datum_band(rgb, width, height, cyan_delta)
    row_set = set(rows)
    working_min, working_max = illustration_bounds(rgb, alpha, width, height, row_set, cyan_delta)
    outside_suppressed = inside_subdued = 0
    for y in rows:
        for x in range(width):
            pixel = y * width + x
            i = pixel * 3
            if not is_cyan_ink(rgb[i], rgb[i + 1], rgb[i + 2], cyan_delta):
                continue
            if x < working_min or x > working_max:
                if alpha[pixel] != 0:
                    alpha[pixel] = 0
                    outside_suppressed += 1
            else:
                alpha[pixel] = min(alpha[pixel], datum_alpha)
                inside_subdued += 1
    support_cyan = sum(1 for pixel, value in enumerate(alpha) if value > 0 and pixel // width not in row_set and is_cyan_ink(rgb[pixel * 3], rgb[pixel * 3 + 1], rgb[pixel * 3 + 2], cyan_delta))
    final = {"zero": sum(value == 0 for value in alpha), "partial": sum(0 < value < 255 for value in alpha), "opaque": sum(value == 255 for value in alpha)}
    return alpha, {"initial_alpha_counts": initial, "final_alpha_counts": final, "datum": {"row_band": rows, "row_cyan_threshold": row_threshold, "working_x": [working_min, working_max], "outside_cyan_suppressed": outside_suppressed, "inside_cyan_subdued": inside_subdued, "non_datum_cyan_preserved": support_cyan}}


def rgba_from_rgb_alpha(rgb: bytearray, alpha: bytearray) -> bytearray:
    output = bytearray(len(alpha) * 4)
    for pixel, value in enumerate(alpha):
        source, destination = pixel * 3, pixel * 4
        output[destination : destination + 3] = rgb[source : source + 3]
        output[destination + 3] = value
    return output


def parchment_composite(rgb: bytearray, alpha: bytearray, parchment: tuple[int, int, int]) -> bytearray:
    output = bytearray(len(rgb))
    for pixel, value in enumerate(alpha):
        source = pixel * 3
        inverse = 255 - value
        output[source] = (rgb[source] * value + parchment[0] * inverse + 127) // 255
        output[source + 1] = (rgb[source + 1] * value + parchment[1] * inverse + 127) // 255
        output[source + 2] = (rgb[source + 2] * value + parchment[2] * inverse + 127) // 255
    return output


def resize_bilinear_rgb(rgb: bytearray, width: int, height: int, destination: int) -> bytearray:
    """Deterministic proof resize after compositing, avoiding alpha fringe math."""
    output = bytearray(destination * destination * 3)
    for y in range(destination):
        source_y = max(0.0, min(float(height - 1), (y + 0.5) * height / destination - 0.5))
        y0 = int(source_y)
        y1, fy = min(height - 1, y0 + 1), source_y - y0
        for x in range(destination):
            source_x = max(0.0, min(float(width - 1), (x + 0.5) * width / destination - 0.5))
            x0 = int(source_x)
            x1, fx = min(width - 1, x0 + 1), source_x - x0
            for channel in range(3):
                p00 = rgb[(y0 * width + x0) * 3 + channel]
                p10 = rgb[(y0 * width + x1) * 3 + channel]
                p01 = rgb[(y1 * width + x0) * 3 + channel]
                p11 = rgb[(y1 * width + x1) * 3 + channel]
                output[(y * destination + x) * 3 + channel] = int(round((p00 * (1 - fx) + p10 * fx) * (1 - fy) + (p01 * (1 - fx) + p11 * fx) * fy))
    return output


def edge_audit(alpha: bytearray, width: int, height: int) -> dict[str, object]:
    indices = {"top": range(width), "bottom": range((height - 1) * width, height * width), "left": (y * width for y in range(height)), "right": (y * width + width - 1 for y in range(height))}
    edges: dict[str, object] = {}
    for name, edge_indices in indices.items():
        values = [alpha[index] for index in edge_indices]
        edges[name] = {"pixels": len(values), "alpha_zero": sum(value == 0 for value in values), "alpha_partial": sum(0 < value < 255 for value in values), "alpha_opaque": sum(value == 255 for value in values), "min_alpha": min(values), "max_alpha": max(values)}
    return {"corners": {"top_left": alpha[0], "top_right": alpha[width - 1], "bottom_left": alpha[(height - 1) * width], "bottom_right": alpha[-1]}, "edges": edges}


def run_self_test() -> dict[str, object]:
    """Prove enclosed paper clears, ink survives, and the datum clips/subdues by alpha."""
    width, height = 17, 11
    rgb = bytearray([250, 250, 250] * (width * height))
    def set_pixel(x: int, y: int, color: tuple[int, int, int]) -> None:
        i = (y * width + x) * 3
        rgb[i : i + 3] = bytes(color)
    for x in range(4, 13):
        set_pixel(x, 3, (116, 79, 35)); set_pixel(x, 7, (116, 79, 35))
    for y in range(3, 8):
        set_pixel(4, y, (116, 79, 35)); set_pixel(12, y, (116, 79, 35))
    for x in range(width):
        set_pixel(x, 5, (100, 230, 235))
    set_pixel(8, 4, (90, 225, 232))
    alpha, audit = extract_paper_through_ink(rgb, width, height)
    enclosed, sepia, support, datum_left, datum_inside = alpha[4 * width + 6], alpha[3 * width + 4], alpha[4 * width + 8], alpha[5 * width], alpha[5 * width + 8]
    if not (enclosed == 0 and sepia == 255 and support == 255 and datum_left == 0 and 0 < datum_inside < 255):
        raise AssertionError("paper-through synthetic alpha calibration failed")
    rgba = rgba_from_rgb_alpha(rgb, alpha)
    all_rgba_rgb = all(rgba[p * 4 : p * 4 + 3] == rgb[p * 3 : p * 3 + 3] for p in range(width * height))
    resize_fixture = bytearray((10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120))
    resized = resize_bilinear_rgb(resize_fixture, 2, 2, 4)
    resize_corners_exact = (
        resized[0:3] == resize_fixture[0:3]
        and resized[9:12] == resize_fixture[3:6]
        and resized[36:39] == resize_fixture[6:9]
        and resized[45:48] == resize_fixture[9:12]
    )
    if not all_rgba_rgb or not resize_corners_exact:
        raise AssertionError("synthetic RGB identity or clamped resize calibration failed")
    return {"passed": True, "enclosed_bright_neutral_alpha": enclosed, "sepia_alpha": sepia, "cyan_support_alpha": support, "outside_datum_alpha": datum_left, "inside_datum_alpha": datum_inside, "rgba_all_pixel_rgb_byte_identical_to_source": all_rgba_rgb, "resize_corners_exact_no_extrapolation": resize_corners_exact, "datum": audit["datum"]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--creature-id", required=True)
    parser.add_argument("--source-description", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--light-composite", type=Path, required=True)
    parser.add_argument("--dark-composite", type=Path, required=True)
    parser.add_argument("--proof-160", type=Path, required=True)
    parser.add_argument("--provenance", type=Path, required=True)
    parser.add_argument("--mode", choices=("paper-through-ink",), required=True)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    self_test = run_self_test() if args.self_test else None
    width, height, rgb = load_rgb_png(args.source)
    alpha, mask = extract_paper_through_ink(rgb, width, height)
    rgba = rgba_from_rgb_alpha(rgb, alpha)
    light, dark = parchment_composite(rgb, alpha, (231, 214, 175)), parchment_composite(rgb, alpha, (76, 58, 43))
    proof = resize_bilinear_rgb(light, width, height, 160)
    write_png(args.output, width, height, 4, rgba)
    write_png(args.light_composite, width, height, 3, light)
    write_png(args.dark_composite, width, height, 3, dark)
    write_png(args.proof_160, 160, 160, 3, proof)
    all_rgba_rgb = all(rgba[p * 4 : p * 4 + 3] == rgb[p * 3 : p * 3 + 3] for p in range(width * height))
    if not all_rgba_rgb:
        raise AssertionError("output RGBA source RGB changed")
    outputs = {"rgba": args.output, "light_parchment_composite": args.light_composite, "dark_parchment_composite": args.dark_composite, "proof_160_light_parchment": args.proof_160}
    provenance = {
        "approval_state": "preproduction_alpha_calibration_v2_pending_ui_review",
        "creature_id": args.creature_id,
        "tool": {"path": "tools/extract_blueprint_alpha.py", "python": sys.version.split()[0], "standard_library_only": True},
        "source": {"path": str(args.source), "bytes": args.source.stat().st_size, "sha256": sha256(args.source), "dimensions": [width, height], "mode": "RGB", "description": args.source_description},
        "algorithm": {"mode": args.mode, "name": "paper_through_ink_alpha_mask_with_subordinate_cyan_datum", "parameters": {"neutral_brightness_min": 224, "neutral_chroma_max": 36, "taper_brightness_min": 184, "taper_chroma_max": 62, "cyan_delta_min": 50, "datum_alpha": 112}, "guarantees": ["alpha only; RGB source bytes are untouched for every output RGBA pixel", "bright low-chroma paper is transparent even when enclosed", "sepia contours/hatching and cyan ink survive by darkness/chroma", "one detected full-width cyan datum band is clipped outside the derived illustration width and subdued"]},
        "outputs": {name: {"path": str(path), "bytes": path.stat().st_size, "sha256": sha256(path), "dimensions": [width, height] if name != "proof_160_light_parchment" else [160, 160], "mode": "RGBA" if name == "rgba" else "RGB"} for name, path in outputs.items()},
        "alpha": {"range": [min(alpha), max(alpha)], "counts": mask["final_alpha_counts"], "initial_counts_before_datum": mask["initial_alpha_counts"], "edge_and_corner_checks": edge_audit(alpha, width, height)},
        "cyan_datum": mask["datum"],
        "rgba_all_pixel_rgb_byte_identical_to_source": all_rgba_rgb,
        "synthetic_calibration_fixture": self_test,
        "manual_painting_or_redraw": False,
    }
    args.provenance.parent.mkdir(parents=True, exist_ok=True)
    args.provenance.write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"outputs": provenance["outputs"], "alpha": provenance["alpha"], "cyan_datum": provenance["cyan_datum"], "self_test": self_test}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
