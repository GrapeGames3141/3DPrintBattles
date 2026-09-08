# M11 implementation handoff — gated

This is the primary agent's inspected plan, not permission to bypass the atlas gate.
Runtime work starts after the user approves this battle-only art supplement.
The sole runtime writer is `terra_implementer`; designer owns design Markdown,
UI reviewer stays read-only, and the primary agent reviews/stages/commits.

## 1. Authority and compatibility

- Keep domain logic in `unified_battle_rules.gd` / `unified_battle_state.gd`.
  Apply 200 base HP and +50 Chassis centrally; remove stale 2,000 UI defaults/copy.
  Do not add a damage multiplier or scale creature values.
- Version actual battle snapshots and adapt the supported old scale once with the
  checkpoint's integer rounding. Validate before applying; preserve the source on
  rejection. Preserve profile ownership, journals, decks, models, and rewards.
- Auto-deploy completed creatures to the leftmost free slot, Attack by default and
  optional queued Guard. Full fields retain staging. Preserve FIFO speed/carryover,
  pauses, interruption, first-turn readiness, refunds, and exactly-once revisions.
- Queue printable equipment without a target. Complete into holding; pause for one
  currently compatible post-print fitting choice. Keep held items when none exists.
  Filament Ring remains its current immediate effect, not a printable equipment job.

## 2. Receipt-driven presentation

- Coordinator derives ordered public before/after print and deployment receipts
  from accepted authority transitions, including multiple jobs and partial work.
  No UI-generated receipt may rerun domain operations. Rival queue identities are
  already public; redact only truly private hand/deck/trap fields.
- Extract a small presentation-only sequence component rather than growing another
  parallel battle loop inside `main.gd`. It owns finite layer/raw/awaken/step-off
  beats and acknowledges one accepted receipt only after the final beat.
- Render each player and rival receipt before its wait. Presentation lock/feedback
  precedes required-choice UI; keep printers, HP, own hand, rival backs and Back
  visible. Required choices appear only after the relevant completion animation.
- Centralize durations in `battle_move_vfx.gd`; remove duplicated hardcoded Main
  durations. Skip/reduced motion changes playback only. Receipt identity includes
  generation and serial so late timers cannot settle a later action or new match.
- Stage computes visible progress from the job's actual prior/next work, not
  `pending.place`. A partial print remains partial between phases. Resolve creature
  and equipment raw art through approved mappings, with a finite diagnostic fallback.
  The current schematic shader retains the raw source alpha even between ink lines;
  make the unfinished region transparent between technical lines, not an opaque
  color-tinted finished silhouette. Align both clips and the scan to one print bound.

## 3. Physical battlefield and clarity

- Promote only the approved text-free floor, never populated concept screenshots.
  Derive all floor/HUD/chamber/hand coordinates from one design-space contract.
- Separate foot anchors/hit regions from taller unclipped sprite silhouettes.
  Reuse cached existing sheets: first row idle, second row appropriate action poses.
  No texture loads, image scans, new materials, or full UI rebuild per animation frame.
- Ground each unit with one reusable soft shadow. Perspective-size rear/front units;
  sort by feet. Native ground focus and compact state labels replace card rectangles.
  One job/unit has one owner through chamber, travel, and settled field.
- Add a read-only Next Cycle forecast based on the current public revision. State
  known order/completions and qualify possible hidden interruptions; never reveal a
  private trap or claim unknown damage as certain.
- Deck assistance produces a preview candidate from owned copies, preserves legal
  decks over 40, and commits only on existing explicit Save/Activate confirmation.
  Guided first battle uses real legal actions and rewards, not a scripted fake match.

## 4. Evidence, refactor, and delivery

- Test actual Main -> coordinator -> stage playback for both seats, not only injected
  stage fixtures: early/60%/complete, multiple jobs, duplicate card IDs, staging,
  awakening/travel/contact, gear fitting, missing art, skip/RM, Back and re-entry.
- Assert authority trace equality across playback modes, exactly-once settlement,
  no late callback unlock, successful old-snapshot conversion and failed-read rollback.
  Execute the 30-match pacing matrix; report outliers without inventing a new rule.
- Preserve M10 Founder packs, Deck real input/save/reload, Back/native Back,
  progressive Forge, catalog export, and transaction regression coverage.
- Capture actual Godot at 576x1024, 720x1280, tall portrait, 150% text/high contrast,
  reduced motion and safe insets. Concept captures cannot count as runtime evidence.
- Read-only UI review must have no P0/P1. Primary reviews ownership, allocations,
  rebuilds, timeline cancellation and source diff; Terra performs bounded refactors.
- After verified checkpoint commit, export a new version/code arm64 no-ad review APK.
  Verify compiled catalog/input path, metadata, signature, ABI, no ads, and launch.
  Device behavior is claimed only with authorized physical-device evidence.
- Deliver commit-qualified APK and README without overwriting any Drive release.
  Verify local/DriveFS byte size and SHA-256; report cloud sync separately.
