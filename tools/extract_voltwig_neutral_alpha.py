#!/usr/bin/env python3
"""Create a review-only Voltwig alpha derivative from the approved RGB candidate.

The source's checkerboard is a pair of near-neutral background clusters, not an
alpha channel.  This extractor classifies those clusters, keeps only components
anchored by high-confidence creature colour, and preserves the source RGB bytes
in the full-resolution RGBA derivative.  It deliberately does not repaint,
redraw, crop, or generate poses.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import platform
import sys
from collections import deque
from pathlib import Path
from statistics import median
from typing import Any

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ART_DIR = ROOT / "docs/art/team-prototype-20260912/voltwig-neutral-facing"
DEFAULT_SOURCE = ART_DIR / "voltwig-neutral-facing-v1.png"
DEFAULT_OUTPUT = ART_DIR / "cleaned-v3"
REVIEWED_SOURCE_SHA256 = "B713B090FAE2E648CF6BEC0FEA8807EEC4DF7A74C002D762DC1A2D6A934FA216"

CELL_WIDTH = 768
CELL_HEIGHT = 1024
ATLAS_CELL_WIDTH = 384
ATLAS_CELL_HEIGHT = 512
COMMON_SCALE = 0.454
SOURCE_ROOT = (384, 950)
ATLAS_ROOT = (192, 455)
MIN_SIDE_CLEARANCE = 30
MIN_TOP_CLEARANCE = 24
MIN_BOTTOM_CLEARANCE = 30
HARD_ALPHA = 240

# Distances are Euclidean sRGB distances from either sampled checker cluster.
# The bridge threshold is intentionally below foreground seed threshold: cream
# highlights can stay attached to a yellow/charcoal seed, while unseeded soft
# cast shadows and checkerboard remain background.
BACKGROUND_CLUSTER_BRIGHTNESS = 235
BRIDGE_DISTANCE = 28.0
SEED_DISTANCE = 70.0
MIN_COMPONENT_PIXELS = 64

# Fixed transparent locations for this SHA-locked source: the gaps between ear
# forms, tail/body, and legs.  These keep the evidence honest about interior
# negative spaces rather than only checking transparent image corners.
NEGATIVE_SPACE_SAMPLES = {
    "front_ear_gap": (384, 120),
    "front_inner_ear_gap": (384, 250),
    "front_tail_body_gap": (150, 650),
    "front_leg_gap": (620, 700),
    "rear_ear_gap": (1152, 120),
    "rear_inner_ear_gap": (1152, 250),
    "rear_side_gap": (900, 700),
    "rear_leg_gap": (1380, 700),
}

# Warm cream is intentionally close to the white checker cluster.  These
# SHA-locked source locations exercise exposed and enclosed cream details so a
# topology change cannot silently carve them away while clearing the checker.
CREAM_PROTECTION_SAMPLES = {
    "front_left_eye_ring": (300, 480),
    "front_right_eye_ring": (500, 480),
    "front_muzzle": (430, 544),
    "front_left_toes": (254, 896),
    "front_right_toes": (493, 897),
    "rear_tail_cream": (1120, 684),
    "rear_right_toes": (1260, 910),
}

# These source rectangles were independently reviewed as fully foreground.  The
# v3 topology assertion checks every pixel, not a hand-picked point, to catch
# cream-ring, muzzle, and tail holes before a review image is presented.
INTERIOR_OPAQUE_ROIS = {
    "front_left_eye": (295, 460, 350, 505),
    "front_right_eye": (446, 466, 498, 517),
    "front_muzzle": (350, 542, 451, 578),
    "rear_tail": (1097, 689, 1150, 730),
}

LIGHT_CREAM = (244, 235, 214, 255)
DARK_NAVY = (20, 31, 47, 255)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source_file:
        for chunk in iter(lambda: source_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest().upper()


def rgb_distance(pixel: tuple[int, int, int], colour: tuple[int, int, int]) -> float:
    return sum((channel - reference) ** 2 for channel, reference in zip(pixel, colour)) ** 0.5


def checker_clusters(rgb: Image.Image) -> list[tuple[int, int, int]]:
    """Sample the clean top band, before the ear tips, into light/dark clusters."""
    samples: list[tuple[int, int, int]] = []
    for y in range(12):
        for x in range(rgb.width):
            samples.append(rgb.getpixel((x, y)))
    grouped = [
        [pixel[channel] for pixel in samples if sum(pixel) / 3 < BACKGROUND_CLUSTER_BRIGHTNESS]
        for channel in range(3)
    ]
    dark = tuple(int(median(values)) for values in grouped)
    grouped = [
        [pixel[channel] for pixel in samples if sum(pixel) / 3 >= BACKGROUND_CLUSTER_BRIGHTNESS]
        for channel in range(3)
    ]
    light = tuple(int(median(values)) for values in grouped)
    if not all(grouped) or not all(dark):
        raise AssertionError("The expected two checkerboard clusters were not available in the clean top band.")
    return [dark, light]


def source_distances(rgb: Image.Image, clusters: list[tuple[int, int, int]]) -> list[float]:
    return [min(rgb_distance(pixel, cluster) for cluster in clusters) for pixel in rgb.get_flattened_data()]


def kept_components(distances: list[float], width: int, height: int) -> tuple[bytearray, dict[str, Any]]:
    """Keep only bridge components which contain enough unmistakable creature colour."""
    total = width * height
    candidates = bytearray(distance >= BRIDGE_DISTANCE for distance in distances)
    visited = bytearray(total)
    kept = bytearray(total)
    components: list[dict[str, Any]] = []
    for start in range(total):
        if not candidates[start] or visited[start]:
            continue
        queue: deque[int] = deque([start])
        visited[start] = 1
        pixels: list[int] = []
        has_seed = False
        maximum_distance = 0.0
        left, right = width, -1
        top, bottom = height, -1
        while queue:
            index = queue.popleft()
            pixels.append(index)
            distance = distances[index]
            has_seed = has_seed or distance >= SEED_DISTANCE
            maximum_distance = max(maximum_distance, distance)
            y, x = divmod(index, width)
            left, right = min(left, x), max(right, x)
            top, bottom = min(top, y), max(bottom, y)
            for neighbour in (index - 1, index + 1, index - width, index + width):
                if neighbour < 0 or neighbour >= total or visited[neighbour] or not candidates[neighbour]:
                    continue
                neighbour_y, neighbour_x = divmod(neighbour, width)
                if abs(neighbour_x - x) + abs(neighbour_y - y) != 1:
                    continue
                visited[neighbour] = 1
                queue.append(neighbour)
        retain = has_seed and len(pixels) >= MIN_COMPONENT_PIXELS
        if retain:
            for index in pixels:
                kept[index] = 1
        components.append(
            {
                "pixels": len(pixels),
                "seeded": has_seed,
                "retained": retain,
                "max_distance": round(maximum_distance, 3),
                "bounds": [left, top, right + 1, bottom + 1],
            }
        )
    retained = [component for component in components if component["retained"]]
    return kept, {
        "candidate_component_count": len(components),
        "retained_component_count": len(retained),
        "retained_components": retained,
    }


def exterior_non_core_mask(core: bytearray, width: int, height: int) -> tuple[bytearray, dict[str, int]]:
    """Flood every non-core pixel from the source perimeter.

    The core holds the two high-confidence Voltwig silhouettes.  Nothing about a
    weak pixel's colour decides whether it is an interior identity detail: if it
    is enclosed by a core silhouette it remains opaque; if it can reach the image
    edge it is checkerboard, cast shadow, or genuine open negative space.
    """
    total = width * height
    exterior = bytearray(width * height)
    queue: deque[int] = deque()
    for x in range(width):
        queue.extend((x, (height - 1) * width + x))
    for y in range(1, height - 1):
        queue.extend((y * width, y * width + width - 1))
    while queue:
        index = queue.popleft()
        if exterior[index] or core[index]:
            continue
        exterior[index] = 1
        y, x = divmod(index, width)
        for neighbour in (index - 1, index + 1, index - width, index + width):
            if neighbour < 0 or neighbour >= width * height or exterior[neighbour]:
                continue
            neighbour_y, neighbour_x = divmod(neighbour, width)
            if abs(neighbour_x - x) + abs(neighbour_y - y) == 1 and not core[neighbour]:
                queue.append(neighbour)
    return exterior, {
        "core_pixels": sum(core),
        "edge_reachable_non_core_pixels": sum(exterior),
        "enclosed_non_core_pixels_restored": total - sum(core) - sum(exterior),
    }


def remove_thin_checker_spikes(alpha: bytearray, distances: list[float], width: int, height: int) -> dict[str, int]:
    """Remove isolated near-checker one-pixel edge spikes without touching gold prongs."""
    removed = 0
    for _ in range(2):
        pass_removed = []
        for y in range(1, height - 1):
            for x in range(1, width - 1):
                index = y * width + x
                if alpha[index] != 255 or distances[index] >= 55.0:
                    continue
                neighbour_values = [
                    alpha[(y + offset_y) * width + (x + offset_x)]
                    for offset_y in (-1, 0, 1)
                    for offset_x in (-1, 0, 1)
                    if offset_x or offset_y
                ]
                opaque_neighbours = sum(value == 255 for value in neighbour_values)
                if opaque_neighbours <= 2:
                    pass_removed.append(index)
        for index in pass_removed:
            alpha[index] = 0
        removed += len(pass_removed)
        if not pass_removed:
            break
    return {"passes": 2, "removed_near_checker_thin_spikes": removed, "distance_ceiling": 55.0}


def alpha_from_checker_aware_components(rgb: Image.Image) -> tuple[Image.Image, dict[str, Any]]:
    clusters = checker_clusters(rgb)
    width, height = rgb.size
    distances = source_distances(rgb, clusters)
    core, component_audit = kept_components(distances, width, height)
    exterior_non_core, topology_audit = exterior_non_core_mask(core, width, height)
    alpha = bytearray(width * height)
    for index in range(width * height):
        if not exterior_non_core[index]:
            alpha[index] = 255
    spike_audit = remove_thin_checker_spikes(alpha, distances, width, height)
    audit = {
        "checker_clusters_srgb": clusters,
        "thresholds": {
            "background_cluster_brightness": BACKGROUND_CLUSTER_BRIGHTNESS,
            "bridge_distance": BRIDGE_DISTANCE,
            "foreground_seed_distance": SEED_DISTANCE,
            "partial_alpha_boundary": "disabled: v3 removes only thin near-checker opaque spikes from the exterior boundary, preventing a white matte fringe without repainting RGB",
            "minimum_component_pixels": MIN_COMPONENT_PIXELS,
        },
        "component_audit": component_audit,
        "binary_edge_seeded_non_core_topology": topology_audit,
        "boundary_spike_cleanup": spike_audit,
        "alpha_counts": {
            "zero": sum(value == 0 for value in alpha),
            "partial": sum(0 < value < 255 for value in alpha),
            "opaque": sum(value == 255 for value in alpha),
        },
    }
    return Image.frombytes("L", rgb.size, bytes(alpha)), audit


def alpha_bounds(alpha: Image.Image, threshold: int = HARD_ALPHA) -> list[int]:
    bounding = alpha.point(lambda value: 255 if value >= threshold else 0).getbbox()
    if bounding is None:
        raise AssertionError("Alpha extraction removed all creature support.")
    return list(bounding)


def rgba_preserving_rgb(source: Image.Image, alpha: Image.Image) -> Image.Image:
    rgba = source.convert("RGBA")
    rgba.putalpha(alpha)
    if rgba.convert("RGB").tobytes() != source.tobytes():
        raise AssertionError("The full-resolution RGBA derivative changed source RGB bytes.")
    return rgba


def composite(rgba: Image.Image, colour: tuple[int, int, int, int]) -> Image.Image:
    background = Image.new("RGBA", rgba.size, colour)
    return Image.alpha_composite(background, rgba).convert("RGB")


def atlas_from_full_rgba(rgba: Image.Image) -> tuple[Image.Image, dict[str, Any]]:
    """Uniformly transform both source cells by one common root-aligned scale."""
    resized_size = (round(CELL_WIDTH * COMMON_SCALE), round(CELL_HEIGHT * COMMON_SCALE))
    offset = (
        round(ATLAS_ROOT[0] - SOURCE_ROOT[0] * COMMON_SCALE),
        round(ATLAS_ROOT[1] - SOURCE_ROOT[1] * COMMON_SCALE),
    )
    atlas = Image.new("RGBA", (ATLAS_CELL_WIDTH * 2, ATLAS_CELL_HEIGHT), (0, 0, 0, 0))
    cell_bounds: list[dict[str, Any]] = []
    for cell_index in range(2):
        source_cell = rgba.crop((cell_index * CELL_WIDTH, 0, (cell_index + 1) * CELL_WIDTH, CELL_HEIGHT))
        scaled = source_cell.resize(resized_size, Image.Resampling.LANCZOS)
        cell = Image.new("RGBA", (ATLAS_CELL_WIDTH, ATLAS_CELL_HEIGHT), (0, 0, 0, 0))
        cell.alpha_composite(scaled, offset)
        alpha = cell.getchannel("A")
        pre_registration_bounds = alpha_bounds(alpha)
        pre_registration_baseline = pre_registration_bounds[3] - 1
        vertical_translation = ATLAS_ROOT[1] - pre_registration_baseline
        if vertical_translation:
            registered_cell = Image.new("RGBA", (ATLAS_CELL_WIDTH, ATLAS_CELL_HEIGHT), (0, 0, 0, 0))
            registered_cell.alpha_composite(cell, (0, vertical_translation))
            cell = registered_cell
            alpha = cell.getchannel("A")
        bounds = alpha_bounds(alpha)
        planted_baseline = bounds[3] - 1
        if planted_baseline != ATLAS_ROOT[1]:
            raise AssertionError(f"Cell {cell_index} did not register to planted baseline {ATLAS_ROOT[1]}: {planted_baseline}")
        clearance = {
            "left": bounds[0],
            "top": bounds[1],
            "right": ATLAS_CELL_WIDTH - bounds[2],
            "bottom": ATLAS_CELL_HEIGHT - bounds[3],
        }
        if (
            clearance["left"] < MIN_SIDE_CLEARANCE
            or clearance["right"] < MIN_SIDE_CLEARANCE
            or clearance["top"] < MIN_TOP_CLEARANCE
            or clearance["bottom"] < MIN_BOTTOM_CLEARANCE
        ):
            raise AssertionError(f"Cell {cell_index} violates clearance contract: {clearance}")
        for edge_name, values in {
            "top": [alpha.getpixel((x, y)) for y in range(2) for x in range(ATLAS_CELL_WIDTH)],
            "bottom": [alpha.getpixel((x, y)) for y in range(ATLAS_CELL_HEIGHT - 2, ATLAS_CELL_HEIGHT) for x in range(ATLAS_CELL_WIDTH)],
            "left": [alpha.getpixel((x, y)) for x in range(2) for y in range(ATLAS_CELL_HEIGHT)],
            "right": [alpha.getpixel((x, y)) for x in range(ATLAS_CELL_WIDTH - 2, ATLAS_CELL_WIDTH) for y in range(ATLAS_CELL_HEIGHT)],
        }.items():
            if any(values):
                raise AssertionError(f"Cell {cell_index} lacks a two-pixel hard alpha gutter on {edge_name}.")
        atlas.alpha_composite(cell, (cell_index * ATLAS_CELL_WIDTH, 0))
        cell_bounds.append(
            {
                "cell": cell_index,
                "direction": "front" if cell_index == 0 else "rear",
                "hard_alpha_bounds": bounds,
                "clearance_pixels": clearance,
                "pre_registration_hard_alpha_bounds": pre_registration_bounds,
                "pre_registration_baseline": pre_registration_baseline,
                "vertical_translation_pixels": vertical_translation,
                "planted_baseline": planted_baseline,
                "root_target": list(ATLAS_ROOT),
            }
        )
    return atlas, {
        "dimensions": list(atlas.size),
        "cell_dimensions": [ATLAS_CELL_WIDTH, ATLAS_CELL_HEIGHT],
        "layout": "2x1: front column 0, rear column 1; no action or extra pose cells",
        "common_uniform_scale": COMMON_SCALE,
        "nominal_source_root": list(SOURCE_ROOT),
        "atlas_root": list(ATLAS_ROOT),
        "registration": "Each complete cell keeps the common scale and is translated vertically only so its measured hard-alpha planted-foot baseline lands at y=455.",
        "resized_source_cell_dimensions": list(resized_size),
        "per_cell": cell_bounds,
    }


def silhouette_proof(atlas: Image.Image, width: int, colour: tuple[int, int, int, int]) -> Image.Image:
    """Show the two atlas cells at an exact intended creature width on one background."""
    height = round(ATLAS_CELL_HEIGHT * width / ATLAS_CELL_WIDTH)
    proof = Image.new("RGBA", (width * 2, height), colour)
    for cell_index in range(2):
        cell = atlas.crop((cell_index * ATLAS_CELL_WIDTH, 0, (cell_index + 1) * ATLAS_CELL_WIDTH, ATLAS_CELL_HEIGHT))
        proof.alpha_composite(cell.resize((width, height), Image.Resampling.LANCZOS), (cell_index * width, 0))
    return proof.convert("RGB")


def root_guide_proof(atlas: Image.Image) -> Image.Image:
    """Review-only navy proof showing both exact y=455 planted-foot guide lines."""
    canvas = Image.new("RGBA", atlas.size, DARK_NAVY)
    draw = ImageDraw.Draw(canvas)
    guide = (67, 220, 229, 180)
    for cell_index in range(2):
        cell_left = cell_index * ATLAS_CELL_WIDTH
        draw.line((cell_left, ATLAS_ROOT[1], cell_left + ATLAS_CELL_WIDTH - 1, ATLAS_ROOT[1]), fill=guide, width=1)
        draw.line((cell_left + ATLAS_ROOT[0], 0, cell_left + ATLAS_ROOT[0], ATLAS_ROOT[1]), fill=guide, width=1)
        draw.ellipse(
            (
                cell_left + ATLAS_ROOT[0] - 2,
                ATLAS_ROOT[1] - 2,
                cell_left + ATLAS_ROOT[0] + 2,
                ATLAS_ROOT[1] + 2,
            ),
            fill=(255, 210, 83, 255),
        )
    canvas.alpha_composite(atlas)
    return canvas.convert("RGB")


def output_paths(output_dir: Path) -> dict[str, Path]:
    return {
        "rgba_full_resolution": output_dir / "voltwig-neutral-facing-alpha-v3.png",
        "full_light_composite": output_dir / "voltwig-neutral-facing-alpha-v3-light.png",
        "full_navy_composite": output_dir / "voltwig-neutral-facing-alpha-v3-navy.png",
        "runtime_ready_atlas": output_dir / "voltwig-neutral-facing-2x1-384x512-v3.png",
        "atlas_light_proof": output_dir / "voltwig-neutral-facing-2x1-384x512-v3-light.png",
        "atlas_navy_proof": output_dir / "voltwig-neutral-facing-2x1-384x512-v3-navy.png",
        "atlas_root_guide_proof": output_dir / "voltwig-neutral-facing-2x1-384x512-v3-root-guide.png",
        "silhouette_80_navy": output_dir / "voltwig-neutral-facing-silhouette-80-navy-v3.png",
        "silhouette_80_cream": output_dir / "voltwig-neutral-facing-silhouette-80-cream-v3.png",
        "silhouette_96_navy": output_dir / "voltwig-neutral-facing-silhouette-96-navy-v3.png",
        "silhouette_96_cream": output_dir / "voltwig-neutral-facing-silhouette-96-cream-v3.png",
        "provenance": output_dir / "provenance.json",
        "approval_record": output_dir / "approval-record.md",
    }


def output_metadata(path: Path) -> dict[str, Any]:
    with Image.open(path) as image:
        return {
            "path": str(path.relative_to(ROOT)).replace("\\", "/"),
            "bytes": path.stat().st_size,
            "sha256": sha256_file(path),
            "dimensions": list(image.size),
            "mode": image.mode,
        }


def validate_source(source: Image.Image, source_path: Path) -> None:
	if source.mode != "RGB" or source.size != (CELL_WIDTH * 2, CELL_HEIGHT):
		raise ValueError("Voltwig neutral candidate must remain the approved 1536x1024 RGB source.")
	if source_path.resolve() != DEFAULT_SOURCE.resolve():
		raise ValueError("This deterministic derivation accepts only the reviewed Voltwig neutral v1 source.")
	if sha256_file(source_path) != REVIEWED_SOURCE_SHA256:
		raise ValueError("Voltwig neutral candidate bytes changed from the reviewed source SHA-256.")


def write_approval_record(path: Path) -> None:
    path.write_text(
        "# Voltwig neutral-facing cleanup v3 — review record\n\n"
        "- User authorization: **Yes—clean up Voltwig and continue** (2026-09-12).\n"
        "- Scope exercised: deterministic checkerboard/soft-shadow alpha extraction only; the RGB candidate remains unchanged and is not overwritten.\n"
        "- Layout: one front and one rear neutral cell, front column 0 and rear column 1. No action, idle expansion, or invented poses were created.\n"
        "- Status: **review-only derivative pending primary and read-only UI review**. It is not a runtime asset promotion, Godot integration, build, export, staging, or commit authorization.\n",
        encoding="utf-8",
    )


def derive(source_path: Path, output_dir: Path) -> dict[str, Any]:
    if output_dir.exists():
        raise FileExistsError(f"Refusing to overwrite existing review evidence: {output_dir}")
    with Image.open(source_path) as opened:
        source = opened.copy()
    validate_source(source, source_path)
    output_dir.mkdir(parents=True)
    alpha, extraction = alpha_from_checker_aware_components(source)
    rgba = rgba_preserving_rgb(source, alpha)
    negative_space_alpha = {
        name: alpha.getpixel(coordinate)
        for name, coordinate in NEGATIVE_SPACE_SAMPLES.items()
    }
    if any(negative_space_alpha.values()):
        raise AssertionError(f"Checkerboard survived in verified negative spaces: {negative_space_alpha}")
    cream_protection_alpha = {
        name: alpha.getpixel(coordinate)
        for name, coordinate in CREAM_PROTECTION_SAMPLES.items()
    }
    if any(value < HARD_ALPHA for value in cream_protection_alpha.values()):
        raise AssertionError(f"Cream identity detail was not preserved as opaque support: {cream_protection_alpha}")
    interior_roi_alpha = {
        name: {
            "rect": list(rectangle),
            "minimum_alpha": min(alpha.crop(rectangle).get_flattened_data()),
            "non_opaque_pixels": sum(value < HARD_ALPHA for value in alpha.crop(rectangle).get_flattened_data()),
        }
        for name, rectangle in INTERIOR_OPAQUE_ROIS.items()
    }
    if any(result["non_opaque_pixels"] for result in interior_roi_alpha.values()):
        raise AssertionError(f"Interior foreground ROIs contain alpha holes: {interior_roi_alpha}")
    atlas, atlas_audit = atlas_from_full_rgba(rgba)
    paths = output_paths(output_dir)
    rgba.save(paths["rgba_full_resolution"])
    composite(rgba, LIGHT_CREAM).save(paths["full_light_composite"])
    composite(rgba, DARK_NAVY).save(paths["full_navy_composite"])
    atlas.save(paths["runtime_ready_atlas"])
    composite(atlas, LIGHT_CREAM).save(paths["atlas_light_proof"])
    composite(atlas, DARK_NAVY).save(paths["atlas_navy_proof"])
    root_guide_proof(atlas).save(paths["atlas_root_guide_proof"])
    silhouette_proof(atlas, 80, DARK_NAVY).save(paths["silhouette_80_navy"])
    silhouette_proof(atlas, 80, LIGHT_CREAM).save(paths["silhouette_80_cream"])
    silhouette_proof(atlas, 96, DARK_NAVY).save(paths["silhouette_96_navy"])
    silhouette_proof(atlas, 96, LIGHT_CREAM).save(paths["silhouette_96_cream"])
    write_approval_record(paths["approval_record"])
    source_rgb = source.tobytes()
    output_rgb = rgba.convert("RGB").tobytes()
    provenance = {
        "status": "review_only_deterministic_cleanup_pending_primary_and_read_only_ui_review",
        "user_authorization": "Yes—clean up Voltwig and continue (2026-09-12).",
        "source": {
            "path": str(source_path.relative_to(ROOT)).replace("\\", "/"),
            "sha256": sha256_file(source_path),
            "dimensions": list(source.size),
            "mode": source.mode,
            "source_rgb_sha256": sha256_bytes(source_rgb),
        },
        "algorithm": {
            "name": "edge_seeded_binary_non_core_topology_alpha_extraction",
            "description": "Top-band sampled checker clusters establish two seeded Voltwig cores. A binary flood clears only non-core pixels reachable from the source perimeter, restoring every enclosed interior pixel regardless of colour; thin near-checker exterior spikes are then removed without repainting RGB. No global grayscale/saturation key is used.",
            "source_rgb_preserved_byte_for_byte_in_full_resolution_rgba": output_rgb == source_rgb,
            "no_crop_repaint_redraw_or_pose_generation": True,
            "extraction": extraction,
        },
        "full_resolution_alpha": {
            "dimensions": list(rgba.size),
            "mode": rgba.mode,
            "hard_alpha_bounds": alpha_bounds(alpha),
            "corner_alpha": [
                alpha.getpixel((0, 0)),
                alpha.getpixel((alpha.width - 1, 0)),
                alpha.getpixel((0, alpha.height - 1)),
                alpha.getpixel((alpha.width - 1, alpha.height - 1)),
            ],
            "verified_negative_space_alpha": negative_space_alpha,
            "verified_cream_identity_alpha": cream_protection_alpha,
            "verified_interior_opaque_rois": interior_roi_alpha,
        },
        "atlas": atlas_audit,
        "outputs": {
            name: output_metadata(path)
            for name, path in paths.items()
            if name not in {"provenance", "approval_record"}
        },
        "approval_record": str(paths["approval_record"].relative_to(ROOT)).replace("\\", "/"),
        "tool": {
            "path": "tools/extract_voltwig_neutral_alpha.py",
            "python": sys.version.split()[0],
            "pillow": Image.__version__,
            "platform": platform.platform(),
        },
        "non_promotion": [
            "No source candidate was overwritten.",
            "No runtime, Godot, build, export, staging, or commit change was made.",
            "Primary and read-only UI review are required before any promotion decision.",
        ],
    }
    paths["provenance"].write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
    return provenance


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    provenance = derive(args.source.resolve(), args.output_dir.resolve())
    print(
        "VOLTWIG_NEUTRAL_ALPHA source_sha256=%s atlas_sha256=%s scale=%.3f"
        % (
            provenance["source"]["sha256"],
            provenance["outputs"]["runtime_ready_atlas"]["sha256"],
            COMMON_SCALE,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
