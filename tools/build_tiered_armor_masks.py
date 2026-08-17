"""Build deterministic blue-plate masks for PrintForge Legends armor masters.

The generator derives coverage only from the authored signature-blue material;
it writes a same-size grayscale alpha mask per registered master.  The optional
per-creature exclusions are normalized geometry for identity material, never
painted pixels.  Keep this file and its JSON audit with the output provenance.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
TIERED = ROOT / "assets" / "armor" / "tiered"
OUTPUT = TIERED / "masks"
AUDIT = ROOT / "docs" / "art" / "source" / "armor" / "tiered-plate-mask-audit-v1.json"

CREATURE_IDS = [
    "cinderpaw", "aquafin", "voltwig", "mossmunk", "frostling", "stoneback",
    "galehopper", "sparkotter", "glassdrake", "coralisk", "runestag",
    "brambleowl", "ironmaw", "aurorawing", "thunderelk", "coalgriffin",
    "tidewhale", "skyforge", "pyraxis", "verdantitan", "miragefox",
    "voidmanta", "worldcoil", "starloom",
]

# Reserved for source-approved natural blue identity regions when candidate
# topology connects them to plate material. Rectangles use x0/y0/x1/y1 in
# normalized master coordinates. The initial approved master pass requires no
# broad exclusions: the stronger signature-blue threshold keeps cyan fins and
# soft blue skin black while preserving hard plates and their antialiasing.
EXCLUSIONS: dict[str, list[tuple[float, float, float, float]]] = {}


def smoothstep(edge0: float, edge1: float, value: float) -> float:
    t = max(0.0, min(1.0, (value - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def source_path(creature_id: str) -> Path:
    suffix = "v3" if creature_id == "cinderpaw" else "v1"
    return TIERED / f"{creature_id}_tiered_armor_signature_green_alpha_{suffix}.png"


def mask_strength(red: int, green: int, blue: int, alpha: int) -> float:
    r, g, b, a = red / 255.0, green / 255.0, blue / 255.0, alpha / 255.0
    saturation = max(r, g, b) - min(r, g, b)
    blue_dominance = b - max(r, g)
    # Tighter than the old global runtime heuristic: this offline signature
    # selection avoids soft cyan identity regions while retaining blue plate
    # interiors and a feathered antialiased edge.
    return a * smoothstep(0.12, 0.28, saturation) * smoothstep(0.10, 0.24, blue_dominance)


def excluded(creature_id: str, u: float, v: float) -> bool:
    return any(x0 <= u <= x1 and y0 <= v <= y1 for x0, y0, x1, y1 in EXCLUSIONS.get(creature_id, []))


def build(creature_id: str) -> dict[str, object]:
    source = source_path(creature_id)
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    mask = Image.new("L", image.size, 0)
    source_pixels = image.load()
    mask_pixels = mask.load()
    covered = 0
    soft = 0
    for y in range(height):
        for x in range(width):
            if excluded(creature_id, x / width, y / height):
                continue
            strength = mask_strength(*source_pixels[x, y])
            value = round(strength * 255.0)
            mask_pixels[x, y] = value
            if value >= 26:
                covered += 1
            if 0 < value < 255:
                soft += 1
    destination = OUTPUT / f"{creature_id}_armor_plate_mask_v1.png"
    mask.save(destination)
    return {
        "creature_id": creature_id,
        "source": source.relative_to(ROOT).as_posix(),
        "mask": destination.relative_to(ROOT).as_posix(),
        "dimensions": [width, height],
        "covered_pixels_at_10pct": covered,
        "soft_edge_pixels": soft,
        "exclusions": EXCLUSIONS.get(creature_id, []),
    }


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    requested = sys.argv[1:]
    if requested:
        invalid = sorted(set(requested).difference(CREATURE_IDS))
        if invalid:
            raise SystemExit("Unknown creature IDs: " + ", ".join(invalid))
        # Preserve all historical audit records while replacing only explicitly
        # regenerated source entries.
        existing = {record["creature_id"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8")).get("records", [])} if AUDIT.exists() else {}
        for creature_id in requested:
            existing[creature_id] = build(creature_id)
        records = [existing[creature_id] for creature_id in CREATURE_IDS]
    else:
        records = [build(creature_id) for creature_id in CREATURE_IDS]
    AUDIT.parent.mkdir(parents=True, exist_ok=True)
    AUDIT.write_text(json.dumps({"version": 1, "records": records}, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(requested) if requested else len(records)} deterministic tiered armor plate masks.")


if __name__ == "__main__":
    main()
