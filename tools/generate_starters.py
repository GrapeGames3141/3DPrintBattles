#!/usr/bin/env python3
"""Generate PrintForge starter idle sprites via PixelLab pixflux API."""

import base64
import json
import os
import sys
import urllib.error
import urllib.request

API_URL = "https://api.pixellab.ai/v2/create-image-pixflux"
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")

STARTERS = [
    (
        "cinderpaw_idle.png",
        "small fox with flame-tipped tails, 3D printed PLA plastic figurine, visible layer lines, orange and red fire colors, chibi proportions, idle standing pose, pixel art style, game sprite",
    ),
    (
        "aquafin_idle.png",
        "dolphin-shark hybrid with wave-ridged fins, 3D printed PLA figurine, visible layer lines, blue and teal water colors, chibi proportions, idle standing pose, pixel art, game sprite",
    ),
    (
        "voltwig_idle.png",
        "hedgehog-bird hybrid with spiky quill wings and coiled tail, 3D printed PLA figurine, visible layer lines, yellow and white lightning colors, chibi proportions, idle pose, pixel art, game sprite",
    ),
]


def generate_sprite(token: str, description: str) -> bytes:
    payload = {
        "description": description,
        "image_size": {"width": 128, "height": 128},
        "no_background": True,
        "view": "low top-down",
        "outline": "single color black outline",
        "shading": "medium shading",
        "detail": "medium detail",
        "text_guidance_scale": 8,
    }
    req = urllib.request.Request(
        API_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = json.load(resp)
    b64 = data["image"]["base64"]
    if b64.startswith("data:"):
        b64 = b64.split(",", 1)[1]
    return base64.b64decode(b64)


def load_token() -> str:
    token = os.environ.get("PIXELLAB_API_KEY", "").strip()
    if token:
        return token
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    if os.path.isfile(env_path):
        with open(env_path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("PIXELLAB_API_KEY="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    return ""


def main() -> int:
    token = load_token()
    if not token:
        print("ERROR: PIXELLAB_API_KEY environment variable is not set.", file=sys.stderr)
        return 1

    os.makedirs(OUT_DIR, exist_ok=True)

    for filename, prompt in STARTERS:
        out_path = os.path.join(OUT_DIR, filename)
        print(f"Generating {filename}...")
        try:
            png = generate_sprite(token, prompt)
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", errors="replace")
            print(f"ERROR generating {filename}: HTTP {e.code} — {body}", file=sys.stderr)
            return 1
        with open(out_path, "wb") as f:
            f.write(png)
        print(f"  Saved {out_path} ({len(png)} bytes)")

    print("Done — 3 starter sprites generated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
