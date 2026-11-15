#!/usr/bin/env python3
"""Finds creature sheets that were replaced with painted art and records them.

A placeholder sheet was committed by the code that drew it (its commit carries a
"Co-Authored-By: Claude" line). When another tool pushes a painted sheet over it,
the sheet's latest commit no longer has that line: this adds the creature to
tools/catalog/painted.txt, rebuilds the catalog, refreshes art_brief/ (prompts and
the redo list) and drops its old placeholder picture.

    uv run --with pillow python tools/sync_painted.py
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
LIST = os.path.join(HERE, "catalog", "painted.txt")


def latest_commit_body(path):
    return subprocess.run(["git", "log", "-1", "--format=%B", "--", path], cwd=ROOT, capture_output=True, text=True).stdout


def main():
    sys.path.insert(0, HERE)
    import catalog.wave6  # noqa: F401
    from catalog.creatures import CREATURES
    have = set()
    with open(LIST) as f:
        have = {l.strip() for l in f if l.strip() and not l.startswith("#")}
    new = []
    for c in CREATURES:
        if c["id"] in have or c.get("art") not in ("gen",) and not str(c.get("art", "")).startswith(("rig:", "src:")):
            continue
        sheet = "assets/creatures/2d/%s_sprite_sheet.png" % c["id"]
        body = latest_commit_body(sheet)
        if body and "Co-Authored-By: Claude" not in body:
            new.append(c["id"])
    if new:
        with open(LIST, "a") as f:
            f.write("\n".join(new) + "\n")
    for cid in new:
        p = os.path.join(ROOT, "art_brief", "redo", "current_placeholders", cid + ".png")
        if os.path.exists(p):
            os.remove(p)
    subprocess.run([sys.executable, os.path.join(HERE, "catalog", "build.py")], cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
    subprocess.run([sys.executable, os.path.join(HERE, "art_prompts.py")], cwd=ROOT, check=True)
    print("newly painted:", " ".join(new) if new else "none")


if __name__ == "__main__":
    main()
