#!/usr/bin/env python3
"""Download south-facing idle PNGs from PixelLab character rotations."""

import json
import os
import sys
import urllib.error
import urllib.request

ROOT = os.path.join(os.path.dirname(__file__), "..")
MANIFEST = os.path.join(ROOT, "data", "pixellab_characters.json")
OUT_DIR = os.path.join(ROOT, "assets", "sprites")
API_BASE = "https://api.pixellab.ai/mcp/characters"


def load_token() -> str:
    token = os.environ.get("PIXELLAB_API_KEY", "").strip()
    if token:
        return token
    env_path = os.path.join(ROOT, ".env")
    if os.path.isfile(env_path):
        with open(env_path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("PIXELLAB_API_KEY="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    return ""


def fetch_character(token: str, character_id: str) -> dict:
    url = f"{API_BASE}/{character_id}"
    req = urllib.request.Request(
        url,
        headers={"Authorization": f"Bearer {token}", "Accept": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def download(url: str, dest: str) -> None:
    req = urllib.request.Request(url, headers={"User-Agent": "PrintForge-Legends/1.0"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = resp.read()
    with open(dest, "wb") as f:
        f.write(data)


def main() -> int:
    token = load_token()
    if not token:
        print("ERROR: Set PIXELLAB_API_KEY to sync idle sprites.", file=sys.stderr)
        return 1

    with open(MANIFEST, encoding="utf-8") as f:
        manifest = json.load(f)

    os.makedirs(OUT_DIR, exist_ok=True)
    ok = 0
    pending = 0

    for creature_id, char_uuid in manifest.items():
        dest = os.path.join(OUT_DIR, f"{creature_id}_idle.png")
        try:
            data = fetch_character(token, char_uuid)
        except urllib.error.HTTPError as e:
            print(f"  {creature_id}: HTTP {e.code}", file=sys.stderr)
            pending += 1
            continue

        status = data.get("status", data.get("character", {}).get("status", "unknown"))
        if status != "completed":
            print(f"  {creature_id}: still {status}")
            pending += 1
            continue

        rotations = data.get("rotations", {})
        south_url = rotations.get("south") if isinstance(rotations, dict) else None
        if not south_url and "rotation_urls" in data:
            south_url = data["rotation_urls"].get("south")
        if not south_url:
            print(f"  {creature_id}: no south rotation URL", file=sys.stderr)
            pending += 1
            continue

        print(f"Downloading {creature_id}_idle.png...")
        download(south_url, dest)
        ok += 1

    print(f"Done — {ok} idle sprites synced, {pending} pending.")
    return 0 if pending == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
