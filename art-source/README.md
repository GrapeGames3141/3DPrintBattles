# PrintForge source-art archive

This editor-ignored hierarchy keeps non-runtime artwork separate from `assets/`:

- `source/` contains retained generation masters used by offline tools.
- `review/` contains approved visual captures.
- `concepts/`, `reference/`, and `demo/` retain non-runtime design material.

Exact runtime/source duplicates were intentionally removed on 2026-08-22. Their
single authoritative runtime copies remain under `assets/`; the archive records
their prior source role here rather than duplicating binary files:

- launcher icon, Workshop v4 landscape/portrait, fallback Workshop reference;
- support-card back and defense/offense/resources/utility source sheets;
- helmet activation atlas.

Do not put runtime resources in this directory. Dynamic runtime files belong in
`assets/runtime_asset_manifest.json`.
