#!/usr/bin/env python3
"""Download PixelLab hit animation frames into assets/sprites/."""

import os
import sys
import urllib.request

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")

# Frame URLs from PixelLab get_character (south-facing hit animations)
HIT_FRAMES = {
    "cinderpaw": [
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/5f3df52a-9b0e-4196-a3dc-c2800fc15849/animations/7628df61-6771-411b-b041-34d860856a7d/south/0.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/5f3df52a-9b0e-4196-a3dc-c2800fc15849/animations/7628df61-6771-411b-b041-34d860856a7d/south/1.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/5f3df52a-9b0e-4196-a3dc-c2800fc15849/animations/7628df61-6771-411b-b041-34d860856a7d/south/2.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/5f3df52a-9b0e-4196-a3dc-c2800fc15849/animations/7628df61-6771-411b-b041-34d860856a7d/south/3.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/5f3df52a-9b0e-4196-a3dc-c2800fc15849/animations/7628df61-6771-411b-b041-34d860856a7d/south/4.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/5f3df52a-9b0e-4196-a3dc-c2800fc15849/animations/7628df61-6771-411b-b041-34d860856a7d/south/5.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/5f3df52a-9b0e-4196-a3dc-c2800fc15849/animations/7628df61-6771-411b-b041-34d860856a7d/south/6.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/5f3df52a-9b0e-4196-a3dc-c2800fc15849/animations/7628df61-6771-411b-b041-34d860856a7d/south/7.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/5f3df52a-9b0e-4196-a3dc-c2800fc15849/animations/7628df61-6771-411b-b041-34d860856a7d/south/8.png",
    ],
    "aquafin": [
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/9fa458a1-fc30-4f85-a262-2e0c057d22ac/animations/0901fa87-4e69-4754-abe9-ae6a036103ee/south/0.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/9fa458a1-fc30-4f85-a262-2e0c057d22ac/animations/0901fa87-4e69-4754-abe9-ae6a036103ee/south/1.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/9fa458a1-fc30-4f85-a262-2e0c057d22ac/animations/0901fa87-4e69-4754-abe9-ae6a036103ee/south/2.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/9fa458a1-fc30-4f85-a262-2e0c057d22ac/animations/0901fa87-4e69-4754-abe9-ae6a036103ee/south/3.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/9fa458a1-fc30-4f85-a262-2e0c057d22ac/animations/0901fa87-4e69-4754-abe9-ae6a036103ee/south/4.png",
        "https://backblaze.pixellab.ai/file/pixellab-characters/12a8f0a6-fe03-486b-93c5-a2fc8425f695/9fa458a1-fc30-4f85-a262-2e0c057d22ac/animations/0901fa87-4e69-4754-abe9-ae6a036103ee/south/5.png",
    ],
}


def download(url: str, dest: str) -> None:
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "PrintForge-Legends/1.0"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = resp.read()
    with open(dest, "wb") as f:
        f.write(data)


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    total = 0
    for creature_id, urls in HIT_FRAMES.items():
        for i, url in enumerate(urls):
            dest = os.path.join(OUT_DIR, f"{creature_id}_hit_{i:02d}.png")
            print(f"Downloading {creature_id} hit frame {i}...")
            download(url, dest)
            total += 1
    print(f"Done — {total} hit frames saved to {OUT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
