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

## Screen-first production loop

1. `gameplay_designer` owns only Markdown design and checkpoint documents. For every
   feature it records Entry, Player decision, Result, Failure, Disabled, Feedback,
   and Progression. It never edits runtime code, scenes, project settings, or art.
2. `ui_reviewer` is read-only. It compares original-resolution generated masters and
   later captures against the approved direction; it reviews hierarchy, material,
   responsiveness, accessibility, and native dynamic text. It may supply text-free
   ImageGen briefs only.
3. Sol inspects the working tree and gives one bounded, decision-complete task to the
   sole runtime writer. The runtime writer validates but does not stage or commit.
4. Sol reviews the diff and evidence, obtains any required human approval, then stages
   and commits.

No Godot invocation, runtime edit, build, export, or runtime-art promotion may begin
until the current preproduction checkpoint's full screen atlas is present, the
read-only UI review has no P0 finding, and the user has approved both the atlas and
the simplified battle loop. Dynamic names, values, labels, states, and accessibility
text must remain native Godot controls; generated art is never a text container.
