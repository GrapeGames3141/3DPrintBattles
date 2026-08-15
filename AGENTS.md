# PrintForge Legends project rules

- This repository is the durable Windows Steam project for PrintForge Legends.
- Use Godot 4.7.1, GDScript, Forward+, deterministic integer combat, and catalog-driven data.
- Never place credentials, Steam app IDs, Nakama keys, builds, imports, or save journals in Git.
- `backend/` is authoritative-server scaffolding only; deployment configuration stays outside Git.
- Keep player-facing content suitable for all ages: no freeform chat or user-authored text.
- Every review build must also be delivered to the established Google Drive release
  folder using its versioned filename; never overwrite an existing release. Verify
  the destination size and SHA-256 after the copy, and report the DriveFS copy
  separately from confirmed cloud synchronization. A local verified copy alone is
  not evidence that Drive has finished syncing.
