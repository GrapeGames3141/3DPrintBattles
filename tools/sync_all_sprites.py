#!/usr/bin/env python3
"""Sync all creature sprites from existing PixelLab characters + objects (no API key needed)."""

import json
import os
import shutil
import urllib.request

ROOT = os.path.join(os.path.dirname(__file__), "..")
MAP_PATH = os.path.join(ROOT, "data", "pixellab_sprite_map.json")
OUT_DIR = os.path.join(ROOT, "assets", "sprites")


def download(url: str, dest: str) -> None:
    req = urllib.request.Request(url, headers={"User-Agent": "PrintForge-Legends/1.0"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = resp.read()
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "wb") as f:
        f.write(data)


def copy_hit_frames(source_creature: str, target_creature: str) -> int:
    copied = 0
    i = 0
    while True:
        src = os.path.join(OUT_DIR, f"{source_creature}_hit_{i:02d}.png")
        if not os.path.isfile(src):
            break
        dst = os.path.join(OUT_DIR, f"{target_creature}_hit_{i:02d}.png")
        if not os.path.isfile(dst):
            shutil.copy2(src, dst)
            copied += 1
        i += 1
    return copied


def main() -> int:
    with open(MAP_PATH, encoding="utf-8") as f:
        data = json.load(f)

    os.makedirs(OUT_DIR, exist_ok=True)
    idle_count = 0

    for section in ("characters", "objects"):
        for creature_id, entry in data.get(section, {}).items():
            dest = os.path.join(OUT_DIR, f"{creature_id}_idle.png")
            print(f"  {creature_id}_idle.png ← {section}")
            download(entry["image_url"], dest)
            idle_count += 1

    hit_count = 0
    for creature_id, urls in data.get("hit_animations", {}).items():
        for i, url in enumerate(urls):
            dest = os.path.join(OUT_DIR, f"{creature_id}_hit_{i:02d}.png")
            print(f"  {creature_id}_hit_{i:02d}.png")
            download(url, dest)
            hit_count += 1

    alias_count = 0
    for section in ("characters", "objects"):
        for creature_id, entry in data.get(section, {}).items():
            hit_src = entry.get("hit_creature", creature_id)
            if hit_src == creature_id:
                continue
            n = copy_hit_frames(hit_src, creature_id)
            if n:
                print(f"  {creature_id}: aliased {n} hit frames from {hit_src}")
                alias_count += n

    print(f"\nDone — {idle_count} idle sprites, {hit_count} hit frames downloaded, {alias_count} hit aliases copied.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
