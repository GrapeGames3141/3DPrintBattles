#!/usr/bin/env python3
"""Create review-only RGBA battle-facing atlas candidates from approved source PNGs.

This utility is deliberately offline and uses the bundled Pillow runtime for PNG I/O.
It does not draw,
inpaint, resize, or invent creature pixels. It removes only an explicitly selected
external matte, derives alpha with an edge ramp, and records every registration
decision in metadata. Outputs belong under docs/art until art/UI review approves
promotion.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
from collections import deque
from pathlib import Path
from typing import Iterable

from PIL import Image

SHEET_SIZE = (1536, 1024)
CELL_SIZE = (384, 512)
CELL_COUNT = 8
GUTTER = 2


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def load_png(path: Path) -> tuple[int, int, int, bytearray]:
    """Read RGB/RGBA PNG via the bundled Pillow runtime."""
    with Image.open(path) as image:
        if image.mode not in ("RGB", "RGBA"):
            raise ValueError(f"expected RGB/RGBA PNG, found {image.mode}: {path}")
        channels = 3 if image.mode == "RGB" else 4
        return image.width, image.height, channels, bytearray(image.tobytes())


def write_png(path: Path, width: int, height: int, channels: int, pixels: bytes) -> None:
    if channels not in (3, 4) or len(pixels) != width * height * channels:
        raise ValueError("invalid image dimensions")
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.frombytes("RGB" if channels == 3 else "RGBA", (width, height), bytes(pixels)).save(path, format="PNG", compress_level=9)


def rgb_at(pixels: bytearray, channels: int, pixel: int) -> tuple[int, int, int]:
    index = pixel * channels
    return pixels[index], pixels[index + 1], pixels[index + 2]


def luminance(color: tuple[int, int, int]) -> float:
    return color[0] * .2126 + color[1] * .7152 + color[2] * .0722


def chroma(color: tuple[int, int, int]) -> int:
    return max(color) - min(color)


def matte_distance(color: tuple[int, int, int], matte: tuple[int, int, int]) -> float:
    return math.sqrt(sum((component - reference) ** 2 for component, reference in zip(color, matte)))


def is_protected_hue(color: tuple[int, int, int], protected_hues: set[str]) -> bool:
    red, green, blue = color
    # Runestag's opaque violet chest/inner ears sit close enough to magenta to
    # confuse a naive key. This range preserves that authored material while
    # still letting its high-magenta anti-aliased silhouette transition key out.
    if "purple" in protected_hues and 70 <= red <= 200 and 20 <= green <= 140 and 100 <= blue <= 245 and 18 <= blue - red <= 125 and red - green >= 25:
        return True
    return False


def is_matte_candidate(color: tuple[int, int, int], matte_mode: str, reference: tuple[int, int, int] | None = None, protected_hues: set[str] | None = None) -> bool:
    if protected_hues and is_protected_hue(color, protected_hues):
        return False
    if matte_mode == "magenta":
        # Constrain to the measured matte itself. A broad "pink" predicate can
        # incorrectly tunnel through red/orange creature pixels at the silhouette.
        # The b-g gate admits the actual magenta->blue/cream anti-alias transition
        # while excluding Cinderpaw's red/orange body surface.
        return matte_distance(color, reference if reference is not None else (255, 0, 255)) <= 235.0 and color[2] - color[1] >= 60
    if matte_mode == "green":
        # Pyraxis uses a pure green matte while its authored creature material
        # includes magenta/purple. Keep the key directional to avoid touching it.
        return matte_distance(color, reference if reference is not None else (0, 255, 0)) <= 235.0 and color[1] - color[0] >= 60
    if matte_mode == "checkerboard":
        # Checkerboard colors are high-value low-chroma neutrals. These are only
        # removed after a cell-edge flood, so enclosed cream eyes/muzzles survive.
        return luminance(color) >= 184 and chroma(color) <= 42
    raise ValueError(f"unsupported matte mode: {matte_mode}")


def cell_bounds(frame: int) -> tuple[int, int, int, int]:
    x = (frame % 4) * CELL_SIZE[0]
    y = (frame // 4) * CELL_SIZE[1]
    return x, y, CELL_SIZE[0], CELL_SIZE[1]


def _cell_border_indices(x0: int, y0: int, width: int, height: int) -> Iterable[int]:
    for x in range(x0, x0 + width):
        yield y0 * SHEET_SIZE[0] + x
        yield (y0 + height - 1) * SHEET_SIZE[0] + x
    for y in range(y0 + 1, y0 + height - 1):
        yield y * SHEET_SIZE[0] + x0
        yield y * SHEET_SIZE[0] + x0 + width - 1


def seed_matte_reference(pixels: bytearray, channels: int, matte_mode: str) -> tuple[int, int, int]:
    if matte_mode == "checkerboard":
        return (238, 238, 238)
    samples: list[tuple[int, int, int]] = []
    for frame in range(CELL_COUNT):
        x0, y0, cell_width, cell_height = cell_bounds(frame)
        for x, y in ((x0, y0), (x0 + cell_width - 1, y0), (x0, y0 + cell_height - 1), (x0 + cell_width - 1, y0 + cell_height - 1)):
            samples.append(rgb_at(pixels, channels, y * SHEET_SIZE[0] + x))
    return tuple(sorted(color[channel] for color in samples)[len(samples) // 2] for channel in range(3))


def external_matte_mask(pixels: bytearray, channels: int, matte_mode: str, protected_hues: set[str]) -> tuple[bytearray, tuple[int, int, int]]:
    """Return 0 foreground, 1 true near-matte core, 2 a <=2px matte edge band.

    The magenta path is deliberately spatially bounded.  A color-only matte key can
    reach violet/pink authored material anywhere in the cell; only a true matte core
    is transparent and only its immediate key-connected boundary can be partial.
    """
    width, height = SHEET_SIZE
    mask = bytearray(width * height)
    candidates = bytearray(width * height)
    reference = seed_matte_reference(pixels, channels, matte_mode)
    for pixel in range(width * height):
        if is_matte_candidate(rgb_at(pixels, channels, pixel), matte_mode, reference, protected_hues):
            candidates[pixel] = 1
    if matte_mode in ("magenta", "green"):
        # Exact/near-exact key color is the only transparent core. The much broader
        # candidate predicate is reserved for two raster steps of anti-aliasing.
        core = bytearray(width * height)
        for pixel in range(width * height):
            color = rgb_at(pixels, channels, pixel)
            if not is_protected_hue(color, protected_hues) and matte_distance(color, reference) <= 92.0:
                core[pixel] = 1
        for frame in range(CELL_COUNT):
            x0, y0, cell_width, cell_height = cell_bounds(frame)
            queue: deque[tuple[int, int]] = deque()
            # Matte can be trapped inside negative spaces under a body or between
            # legs. Exact/near-exact measured key islands are background wherever
            # they occur in the cell; authored near-key materials require an
            # explicit protected hue and never enter this core.
            for y in range(y0, y0 + cell_height):
                for x in range(x0, x0 + cell_width):
                    pixel = y * width + x
                    if not core[pixel]:
                        continue
                    mask[pixel] = 1
                    for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                        if nx >= x0 and nx < x0 + cell_width and ny >= y0 and ny < y0 + cell_height:
                            neighbor = ny * width + nx
                            if not core[neighbor] and candidates[neighbor]:
                                queue.append((pixel, 0))
                                break
            while queue:
                pixel, distance = queue.popleft()
                y, x = divmod(pixel, width)
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if nx < x0 or nx >= x0 + cell_width or ny < y0 or ny >= y0 + cell_height:
                        continue
                    neighbor = ny * width + nx
                    if core[neighbor] and not mask[neighbor]:
                        mask[neighbor] = 1
                        queue.append((neighbor, distance))
                    elif distance < 2 and not mask[neighbor] and candidates[neighbor]:
                        mask[neighbor] = 2
                        queue.append((neighbor, distance + 1))
        return mask, reference
    for frame in range(CELL_COUNT):
        x0, y0, cell_width, cell_height = cell_bounds(frame)
        queue: deque[int] = deque()
        for pixel in _cell_border_indices(x0, y0, cell_width, cell_height):
            if candidates[pixel] and not mask[pixel]:
                mask[pixel] = 1
                queue.append(pixel)
        while queue:
            pixel = queue.popleft()
            y, x = divmod(pixel, width)
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if nx < x0 or nx >= x0 + cell_width or ny < y0 or ny >= y0 + cell_height:
                    continue
                neighbor = ny * width + nx
                if candidates[neighbor] and not mask[neighbor]:
                    mask[neighbor] = 1
                    queue.append(neighbor)
    return mask, reference


def derive_alpha(pixels: bytearray, channels: int, matte_mode: str, background: bytearray, matte: tuple[int, int, int]) -> tuple[bytearray, bytearray, dict[str, int], tuple[int, int, int]]:
    """Create alpha and RGBA RGB. Only partial edge pixels are decontaminated."""
    width, height = SHEET_SIZE
    alpha = bytearray(width * height)
    output_rgb = bytearray(width * height * 3)
    partial_edges = fully_opaque = transparent = 0
    for pixel in range(width * height):
        color = rgb_at(pixels, channels, pixel)
        destination = pixel * 3
        if not background[pixel]:
            value = 255 if channels == 3 else pixels[pixel * channels + 3]
        elif matte_mode in ("magenta", "green") and background[pixel] == 1:
            value = 0
        elif matte_mode in ("magenta", "green"):
            # Estimate coverage from the three ways a foreground pixel departs
            # from measured magenta. A short Euclidean ramp incorrectly made
            # half-matte anti-alias pixels opaque and left a purple halo.
            coverage = max(
                abs(color[0] - matte[0]) / 255.0,
                abs(color[1] - matte[1]) / (220.0 if matte_mode == "magenta" else 255.0),
                abs(color[2] - matte[2]) / 255.0,
            )
            value = max(1, min(254, int(round(max(0.0, min(1.0, coverage)) * 255))))
        else:
            # The cell-edge connected checkerboard itself is transparent. A
            # neutral candidate that joins it is background, not an eye/cream hole.
            value = 0
        alpha[pixel] = value
        if value == 0:
            transparent += 1
            output_rgb[destination : destination + 3] = bytes(color)
        elif value == 255:
            fully_opaque += 1
            output_rgb[destination : destination + 3] = bytes(color)
        else:
            partial_edges += 1
            # Reverse compositing against the declared matte to prevent a colored
            # fringe on dark review surfaces. This changes only edge RGB.
            inverse = 255 - value
            corrected = []
            for component, matte_component in zip(color, matte):
                corrected.append(max(0, min(255, int(round((component * 255 - matte_component * inverse) / value)))))
            output_rgb[destination : destination + 3] = bytes(corrected)
    return alpha, output_rgb, {"transparent": transparent, "partial_edge": partial_edges, "opaque": fully_opaque}, matte


def rgba_from_rgb_alpha(rgb: bytearray, alpha: bytearray) -> bytearray:
    result = bytearray(len(alpha) * 4)
    for pixel, value in enumerate(alpha):
        result[pixel * 4 : pixel * 4 + 3] = rgb[pixel * 3 : pixel * 3 + 3]
        result[pixel * 4 + 3] = value
    return result


def remove_external_noise(alpha: bytearray, rgb: bytearray, max_component_pixels: int = 96) -> int:
    """Remove only tiny detached opaque specks; authored anatomy remains connected."""
    removed = 0
    width = SHEET_SIZE[0]
    for frame in range(CELL_COUNT):
        x0, y0, cell_width, cell_height = cell_bounds(frame)
        visited = bytearray(cell_width * cell_height)
        for local_y in range(cell_height):
            for local_x in range(cell_width):
                local = local_y * cell_width + local_x
                pixel = (y0 + local_y) * width + x0 + local_x
                if visited[local] or alpha[pixel] <= 8:
                    continue
                component: list[int] = []
                queue: deque[tuple[int, int]] = deque([(local_x, local_y)])
                visited[local] = 1
                while queue:
                    x, y = queue.popleft()
                    member = (y0 + y) * width + x0 + x
                    component.append(member)
                    for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                        if nx < 0 or nx >= cell_width or ny < 0 or ny >= cell_height:
                            continue
                        neighbor_local = ny * cell_width + nx
                        neighbor = (y0 + ny) * width + x0 + nx
                        if not visited[neighbor_local] and alpha[neighbor] > 8:
                            visited[neighbor_local] = 1
                            queue.append((nx, ny))
                if len(component) <= max_component_pixels:
                    for member in component:
                        alpha[member] = 0
                    removed += len(component)
    return removed


def alpha_edge_audit(alpha: bytearray, rgb: bytearray, matte_mode: str) -> dict[str, int]:
    partial = 0
    matte_like_partial = 0
    reference = (255, 0, 255) if matte_mode == "magenta" else ((0, 255, 0) if matte_mode == "green" else (238, 238, 238))
    for pixel, value in enumerate(alpha):
        if 0 < value < 255:
            partial += 1
            if matte_distance((rgb[pixel * 3], rgb[pixel * 3 + 1], rgb[pixel * 3 + 2]), reference) < 20:
                matte_like_partial += 1
    return {"partial_alpha_pixels": partial, "partial_alpha_pixels_with_near_matte_rgb": matte_like_partial}


def composite(rgb: bytearray, alpha: bytearray, background: tuple[int, int, int]) -> bytearray:
    result = bytearray(len(rgb))
    for pixel, value in enumerate(alpha):
        inverse = 255 - value
        for channel in range(3):
            result[pixel * 3 + channel] = (rgb[pixel * 3 + channel] * value + background[channel] * inverse + 127) // 255
    return result


def contact_review(rgb: bytearray, alpha: bytearray) -> bytearray:
    """Alternate restrained board colors by cell for native-scale contact review."""
    result = bytearray(len(rgb))
    backgrounds = ((20, 33, 48), (54, 42, 34), (33, 49, 49), (39, 29, 47))
    for frame in range(CELL_COUNT):
        color = backgrounds[frame % len(backgrounds)]
        x0, y0, cell_width, cell_height = cell_bounds(frame)
        for y in range(y0, y0 + cell_height):
            for x in range(x0, x0 + cell_width):
                pixel = y * SHEET_SIZE[0] + x
                value = alpha[pixel]
                inverse = 255 - value
                for channel in range(3):
                    result[pixel * 3 + channel] = (rgb[pixel * 3 + channel] * value + color[channel] * inverse + 127) // 255
    return result


def phone_slot_proof(rgba: bytearray, phone_width: int) -> tuple[int, int, bytes]:
    """Render the six native battle slots at phone scale for offline visual QA.

    This is evidence only: it mirrors the stage's 941x1672 design-space slot
    rectangles and TextureRect keep-aspect fitting, but never feeds runtime.
    """
    design_width, design_height = 941, 1672
    scale = phone_width / design_width
    phone_height = round(design_height * scale)
    proof = Image.new("RGB", (phone_width, phone_height), (15, 24, 35))
    atlas = Image.frombytes("RGBA", SHEET_SIZE, bytes(rgba))
    slots = (
        ((90, 380, 190, 305), 0), ((375, 380, 190, 305), 1), ((660, 380, 190, 305), 3),
        ((60, 680, 210, 305), 4), ((365, 680, 210, 305), 5), ((670, 680, 210, 305), 7),
    )
    for (x, y, width, height), frame in slots:
        source_x, source_y, _, _ = cell_bounds(frame)
        sprite = atlas.crop((source_x, source_y, source_x + CELL_SIZE[0], source_y + CELL_SIZE[1]))
        slot_width, slot_height = round(width * scale), round(height * scale)
        factor = min(slot_width / CELL_SIZE[0], slot_height / CELL_SIZE[1])
        sprite = sprite.resize((round(CELL_SIZE[0] * factor), round(CELL_SIZE[1] * factor)), Image.Resampling.LANCZOS)
        left = round(x * scale) + (slot_width - sprite.width) // 2
        top = round(y * scale) + (slot_height - sprite.height) // 2
        proof.paste(sprite, (left, top), sprite)
    return phone_width, phone_height, proof.tobytes()


def alpha_bounds(alpha: bytearray, frame: int) -> list[int] | None:
    x0, y0, cell_width, cell_height = cell_bounds(frame)
    found: list[tuple[int, int]] = []
    for y in range(y0, y0 + cell_height):
        for x in range(x0, x0 + cell_width):
            if alpha[y * SHEET_SIZE[0] + x] > 8:
                found.append((x - x0, y - y0))
    if not found:
        return None
    return [min(x for x, _ in found), min(y for _, y in found), max(x for x, _ in found), max(y for _, y in found)]


def gutter_is_clear(alpha: bytearray, frame: int) -> bool:
    x0, y0, cell_width, cell_height = cell_bounds(frame)
    for y in range(y0, y0 + cell_height):
        for x in range(x0, x0 + cell_width):
            if x - x0 < GUTTER or x0 + cell_width - 1 - x < GUTTER or y - y0 < GUTTER or y0 + cell_height - 1 - y < GUTTER:
                if alpha[y * SHEET_SIZE[0] + x] != 0:
                    return False
    return True


def parse_anchors(path: Path | None) -> dict[str, dict[str, object]]:
    if path is None:
        return {}
    parsed = json.loads(path.read_text(encoding="utf-8"))
    records = parsed.get("frames", []) if isinstance(parsed, dict) else []
    result: dict[str, dict[str, object]] = {}
    for record in records:
        if not isinstance(record, dict) or "frame" not in record:
            raise ValueError("anchor metadata requires frames with an integer frame field")
        result[str(int(record["frame"]))] = record
    return result


def apply_registration(alpha: bytearray, rgb: bytearray, anchors: dict[str, dict[str, object]]) -> tuple[bytearray, bytearray, bool]:
    """Translate named cells only; reject clipping instead of silently cropping art."""
    width, height = SHEET_SIZE
    moved_alpha = bytearray(width * height)
    moved_rgb = bytearray(width * height * 3)
    reclaimed_source = bytearray(width * height)
    source_nonzero = sum(1 for value in alpha if value != 0)
    source_alpha_sum = sum(alpha)
    applied = False
    # Some source masters let a single complete pose overhang one cell boundary.
    # Reclaim its explicit measured source bounds before ordinary per-cell moves so
    # the pose is copied once, the donor fragment is cleared, and no anatomy is cut.
    for frame in range(CELL_COUNT):
        record = anchors.get(str(frame), {})
        bounds = record.get("source_bounds") if isinstance(record, dict) else None
        if not isinstance(bounds, list) or len(bounds) != 4:
            continue
        x_min, y_min, x_max, y_max = (int(value) for value in bounds)
        dx, dy = (int(value) for value in record.get("translation", [0, 0]))
        x0, y0, cell_width, cell_height = cell_bounds(frame)
        if x_min > x_max or y_min > y_max or x_min < 0 or y_min < 0 or x_max >= width or y_max >= height:
            raise ValueError(f"frame {frame} source_bounds are invalid")
        if x_min + dx < x0 + GUTTER or x_max + dx > x0 + cell_width - 1 - GUTTER or y_min + dy < y0 + GUTTER or y_max + dy > y0 + cell_height - 1 - GUTTER:
            raise ValueError(f"frame {frame} source_bounds translation would clip its complete pose")
        for y in range(y_min, y_max + 1):
            for x in range(x_min, x_max + 1):
                source = y * width + x
                if alpha[source] == 0:
                    continue
                if reclaimed_source[source]:
                    raise ValueError(f"frame {frame} source_bounds overlap another reclaimed component")
                destination = (y + dy) * width + x + dx
                if moved_alpha[destination] != 0:
                    raise ValueError(f"frame {frame} reclaimed component overlaps existing art")
                moved_alpha[destination] = alpha[source]
                moved_rgb[destination * 3 : destination * 3 + 3] = rgb[source * 3 : source * 3 + 3]
                reclaimed_source[source] = 1
        applied = True
    for frame in range(CELL_COUNT):
        record = anchors.get(str(frame), {})
        translation = record.get("translation", [0, 0]) if isinstance(record, dict) else [0, 0]
        dx, dy = int(translation[0]), int(translation[1])
        applied = applied or dx != 0 or dy != 0
        x0, y0, cell_width, cell_height = cell_bounds(frame)
        for y in range(cell_height):
            for x in range(cell_width):
                source = (y0 + y) * width + x0 + x
                if alpha[source] == 0 or reclaimed_source[source]:
                    continue
                destination_x, destination_y = x + dx, y + dy
                if destination_x < 0 or destination_x >= cell_width or destination_y < 0 or destination_y >= cell_height:
                    raise ValueError(f"frame {frame} translation [{dx}, {dy}] would clip nontransparent source pixels")
                destination = (y0 + destination_y) * width + x0 + destination_x
                if moved_alpha[destination] != 0:
                    raise ValueError(f"frame {frame} registration overlaps existing art")
                moved_alpha[destination] = alpha[source]
                moved_rgb[destination * 3 : destination * 3 + 3] = rgb[source * 3 : source * 3 + 3]
    if sum(1 for value in moved_alpha if value != 0) != source_nonzero or sum(moved_alpha) != source_alpha_sum:
        raise ValueError("registration did not preserve every nonzero-alpha source pixel exactly once")
    return moved_alpha, moved_rgb, applied


def cell_metadata(alpha: bytearray, anchors: dict[str, dict[str, object]], registration_applied: bool) -> list[dict[str, object]]:
    records: list[dict[str, object]] = []
    for frame in range(CELL_COUNT):
        bounds = alpha_bounds(alpha, frame)
        anchor = anchors.get(str(frame), {})
        requested = anchor.get("foot_root") if isinstance(anchor, dict) else None
        translation = anchor.get("translation", [0, 0]) if isinstance(anchor, dict) else [0, 0]
        if not isinstance(requested, list) or len(requested) != 2:
            requested = None
        if not isinstance(translation, list) or len(translation) != 2:
            raise ValueError(f"frame {frame} translation must be [x, y]")
        records.append({
            "frame": frame,
            "row_direction": "front_rival" if frame < 4 else "rear_friendly",
            "pose": ("idle_a", "idle_b", "windup", "contact")[frame % 4],
            "alpha_bounds": bounds,
            "transparent_gutter_2px": gutter_is_clear(alpha, frame),
            "requested_foot_root": requested,
            "translation": [int(translation[0]), int(translation[1])],
            "registration_mode": "pixel_translation_from_explicit_metadata" if registration_applied else "metadata_only_no_pixels_translated",
        })
    return records


def validate(alpha: bytearray, frames: list[dict[str, object]]) -> list[str]:
    errors: list[str] = []
    if len(alpha) != SHEET_SIZE[0] * SHEET_SIZE[1]:
        errors.append("alpha dimensions are not 1536x1024")
    for frame in frames:
        number = int(frame["frame"])
        if frame["alpha_bounds"] is None:
            errors.append(f"cell {number} is empty")
        if not bool(frame["transparent_gutter_2px"]):
            errors.append(f"cell {number} has opaque pixels in its required 2px gutter")
    return errors


def run(source: Path, creature_id: str, matte_mode: str, output_dir: Path, anchors_path: Path | None, protected_hues: set[str], apply_registration_metadata: bool) -> dict[str, object]:
    width, height, channels, source_pixels = load_png(source)
    if (width, height) != SHEET_SIZE:
        raise ValueError(f"expected 1536x1024 source, found {width}x{height}")
    background, seed_reference = external_matte_mask(source_pixels, channels, matte_mode, protected_hues)
    alpha, cleaned_rgb, counts, reference_matte = derive_alpha(source_pixels, channels, matte_mode, background, seed_reference)
    removed_noise = remove_external_noise(alpha, cleaned_rgb)
    counts["detached_noise_removed"] = removed_noise
    counts["transparent"] += removed_noise
    counts["opaque"] -= removed_noise
    opaque_source_rgb_mismatches = sum(
        1
        for pixel, value in enumerate(alpha)
        if value == 255 and cleaned_rgb[pixel * 3 : pixel * 3 + 3] != source_pixels[pixel * channels : pixel * channels + 3]
    )
    opaque_source_rgb_matches = sum(
        1
        for pixel, value in enumerate(alpha)
        if value == 255 and cleaned_rgb[pixel * 3 : pixel * 3 + 3] == source_pixels[pixel * channels : pixel * channels + 3]
    )
    anchors = parse_anchors(anchors_path)
    registration_applied = False
    if apply_registration_metadata:
        alpha, cleaned_rgb, registration_applied = apply_registration(alpha, cleaned_rgb, anchors)
    frames = cell_metadata(alpha, anchors, registration_applied)
    errors = validate(alpha, frames)
    stem = f"{creature_id}-battle-facing-cleaned-v1"
    output_dir.mkdir(parents=True, exist_ok=True)
    rgba_path = output_dir / f"{stem}.png"
    light_path = output_dir / f"{stem}-light-composite.png"
    dark_path = output_dir / f"{stem}-dark-composite.png"
    contact_path = output_dir / f"{stem}-contact-review.png"
    phone_576_path = output_dir / f"{stem}-phone-slot-proof-576x1024.png"
    phone_720_path = output_dir / f"{stem}-phone-slot-proof-720x1280.png"
    manifest_path = output_dir / f"{stem}-manifest.json"
    write_png(rgba_path, width, height, 4, rgba_from_rgb_alpha(cleaned_rgb, alpha))
    write_png(light_path, width, height, 3, composite(cleaned_rgb, alpha, (238, 226, 202)))
    write_png(dark_path, width, height, 3, composite(cleaned_rgb, alpha, (15, 24, 35)))
    write_png(contact_path, width, height, 3, contact_review(cleaned_rgb, alpha))
    rgba = rgba_from_rgb_alpha(cleaned_rgb, alpha)
    for phone_width, phone_path in ((576, phone_576_path), (720, phone_720_path)):
        proof_width, proof_height, proof_pixels = phone_slot_proof(rgba, phone_width)
        write_png(phone_path, proof_width, proof_height, 3, proof_pixels)
    report = {
        "approval_state": "review_candidate_only_not_runtime_promoted",
        "creature_id": creature_id,
        "tool": {"path": "tools/clean_battle_facing_atlas.py", "python": sys.version.split()[0], "png_io": "Pillow bundled with Codex runtime"},
        "source": {"path": str(source), "sha256": sha256(source), "bytes": source.stat().st_size, "dimensions": [width, height], "channels": channels, "matte_mode": matte_mode},
        "algorithm": {
            "matte": "near-exact measured key core is removed anywhere in each cell (including enclosed negative spaces); only the non-key partial edge band is spatially capped",
            "keyed_edge": "only true near-matte exterior core is transparent; partial alpha is limited to a two-pixel exterior-connected edge band with reverse-composite decontamination",
            "checkerboard": "bright low-chroma edge-connected pixels only; enclosed neutral creature details remain",
            "protected_hues": sorted(protected_hues),
            "pixel_policy": "no drawing, inpainting, resizing, anatomy changes, or pose changes; opaque source RGB stays byte-identical",
            "registration": "explicit per-frame pixel translations only" if registration_applied else "per-frame metadata only; no source pixels translated",
        },
        "alpha_counts": counts,
        "measured_matte_rgb": list(reference_matte),
        "alpha_edge_audit": alpha_edge_audit(alpha, cleaned_rgb, matte_mode),
        "pre_registration_opaque_source_pixels_rgb_byte_identical": opaque_source_rgb_matches,
        "pre_registration_opaque_source_rgb_mismatches": opaque_source_rgb_mismatches,
        "pre_registration_opaque_source_rgb_equality_pass": opaque_source_rgb_mismatches == 0,
        "frames": frames,
        "validation_errors": errors,
        "outputs": {},
    }
    for name, path, proof_size, channels_out in (("rgba", rgba_path, [width, height], 4), ("light_composite", light_path, [width, height], 3), ("dark_composite", dark_path, [width, height], 3), ("contact_review", contact_path, [width, height], 3), ("phone_slot_proof_576", phone_576_path, [576, 1024], 3), ("phone_slot_proof_720", phone_720_path, [720, 1280], 3)):
        report["outputs"][name] = {"path": str(path), "sha256": sha256(path), "bytes": path.stat().st_size, "dimensions": proof_size, "channels": channels_out, "purpose": "offline native-slot-scale proof only; not an actual runtime capture" if name.startswith("phone_slot") else "candidate artifact"}
    manifest_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    report["outputs"]["manifest"] = {"path": str(manifest_path), "sha256": sha256(manifest_path), "bytes": manifest_path.stat().st_size}
    return report


def self_test() -> None:
    # These fixtures encode the production failure modes: enclosed key islands,
    # near-key violet material, and green-key sources with magenta body detail.
    width, height = SHEET_SIZE
    for mode, background_color in (("magenta", (255, 0, 255)), ("green", (0, 255, 0)), ("checkerboard", (238, 238, 238))):
        pixels = bytearray(background_color * (width * height))
        for y in range(170, 300):
            for x in range(120, 264):
                pixel = y * width + x
                pixels[pixel * 3 : pixel * 3 + 3] = bytes((240, 193, 90))
        if mode == "magenta":
            pixels[(200 * width + 119) * 3 : (200 * width + 119) * 3 + 3] = bytes((248, 77, 189))
        elif mode == "green":
            pixels[(200 * width + 119) * 3 : (200 * width + 119) * 3 + 3] = bytes((120, 224, 45))
        # Enclosed neutral/highlight patch must remain protected by the colored shell.
        for y in range(210, 235):
            for x in range(175, 210):
                pixel = y * width + x
                pixels[pixel * 3 : pixel * 3 + 3] = bytes((235, 235, 235))
        protected_hues: set[str] = set()
        if mode == "magenta":
            # A trapped matte island under/inside a silhouette must be zero alpha.
            for y in range(245, 265):
                for x in range(182, 202):
                    pixel = y * width + x
                    pixels[pixel * 3 : pixel * 3 + 3] = bytes((255, 0, 255))
            # Runestag-like violet falls inside the raw key distance but is authored.
            for y in range(180, 205):
                for x in range(125, 155):
                    pixel = y * width + x
                    pixels[pixel * 3 : pixel * 3 + 3] = bytes((180, 25, 205))
            protected_hues.add("purple")
        if mode == "green":
            # Pyraxis-style magenta/purple material must not be touched by green keying.
            for y in range(180, 205):
                for x in range(125, 155):
                    pixel = y * width + x
                    pixels[pixel * 3 : pixel * 3 + 3] = bytes((190, 35, 210))
        mask, reference = external_matte_mask(pixels, 3, mode, protected_hues)
        alpha, rgb, _counts, _matte = derive_alpha(pixels, 3, mode, mask, reference)
        if alpha[220 * width + 190] != 255 or alpha[20] != 0:
            raise AssertionError(f"{mode} synthetic external matte calibration failed")
        if mode == "magenta":
            island = 250 * width + 190
            violet = 190 * width + 135
            if alpha[island] != 0:
                raise AssertionError("enclosed magenta negative-space island was not removed")
            if alpha[violet] != 255 or rgb[violet * 3 : violet * 3 + 3] != bytes((180, 25, 205)):
                raise AssertionError("solid protected violet material was not preserved byte-identically")
        if mode == "green":
            purple = 190 * width + 135
            if alpha[purple] != 255 or rgb[purple * 3 : purple * 3 + 3] != bytes((190, 35, 210)):
                raise AssertionError("green key damaged magenta/purple authored material")
        if mode in ("magenta", "green"):
            if not any(value == 2 for value in mask):
                raise AssertionError(f"{mode} synthetic blend did not exercise partial-alpha edge handling")
            for pixel, value in enumerate(mask):
                if value != 2:
                    continue
                y, x = divmod(pixel, width)
                if not any(
                    0 <= x + dx < width and 0 <= y + dy < height and matte_distance(rgb_at(pixels, 3, (y + dy) * width + x + dx), reference) <= 92.0
                    for dx in range(-2, 3) for dy in range(-2, 3) if abs(dx) + abs(dy) <= 2
                ):
                    raise AssertionError(f"{mode} partial alpha exceeded its two-pixel key edge band")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--creature-id", required=True)
    parser.add_argument("--matte", choices=("magenta", "green", "checkerboard"), required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--anchors", type=Path, help="optional per-frame JSON registration metadata; translations apply only with --apply-registration")
    parser.add_argument("--apply-registration", action="store_true", help="apply only explicit per-frame anchor translations; reject clipping")
    parser.add_argument("--protect-hue", choices=("purple",), action="append", default=[], help="preserve an explicitly approved near-matte material hue")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    report = run(args.source, args.creature_id, args.matte, args.output_dir, args.anchors, set(args.protect_hue), args.apply_registration)
    print(json.dumps({"creature_id": args.creature_id, "validation_errors": report["validation_errors"], "outputs": report["outputs"]}, indent=2))
    return 0 if not report["validation_errors"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
