# Internal Alpha acceptance draft (archived 0.5–0.7)

> Historical document. It describes the retired active-unit, 15-card loop and
> is retained only as provenance. See `../../design/printforge-legends-mechanics-v3.1.md` for current rules.

| Requirement | Executable evidence | Status |
|---|---|---|
| Onboarding and permanent starter | `test_alpha_loop.tscn`: new profile routes to onboarding, GameManager starter selection grants one bound Cinderpaw and one revisioned journal mutation | READY |
| Workshop economy and collection | `test_alpha_loop.tscn`: workshop job reward, catalog-priced Mossmunk blueprint purchase, and collection inventory transition | READY |
| Arcane Forge print transaction | `test_alpha_loop.tscn` drives the Main Forge from preview through raw completion; exactly one catalog print and exact coin debit; `test_ui_checkpoint6.tscn` covers cancel/failure/repeat safety | READY |
| Team and 15-card deck | `test_alpha_loop.tscn`: legal two-instance team and owned fifteen-card active deck save | READY |
| Deterministic combat and AI rules | `test_alpha_loop.tscn` completes legal opening-defense/pass/attack victory; `test_battle_rules.tscn` and `test_checkpoint4.tscn` cover legal AI intent scoring and combat boundaries | READY |
| Exactly-once battle reward | `test_alpha_loop.tscn` claims a resolved win once, verifies the second claim is refused, and checks one revisioned reward transition | READY |
| Snapshot and journal reload | `test_alpha_loop.tscn` reloads its isolated physical snapshot and journal, preserving coins, XP, revision, inventory, team, deck, and battle reward event | READY |
| Deterministic local authority | `LocalBattleAuthority`; `test_checkpoint5.tscn`; backend `authority.test.js` defensive-copy/revision cases | READY |
| Private hot-seat handoff | Workshop Local Versus route; accepted handoff and revealed-turn captures at 1280 and 1920 | READY |
| Credential-free local trade | Dual-confirm `LocalTradeAuthority`, session-only Voltwig guildmate, exact-swap/audit and UI-flow tests | READY |
| Recoverable saves | `test_save_recovery.tscn`: physical isolated backup recovery and idempotent journal acknowledgement | READY |
| Accessibility | persisted text scale, contrast, reduced motion, 44px buttons, deterministic focus, and Escape navigation | READY |
| Windows export | canonical durable `export/PrintForgeLegends.exe`: final export PID 22276 and isolated OpenGL launch PID 24820 | READY for credential-free internal alpha |
| Arcane Forge raw-print awakening | Integer `ArcaneForgeSequence`, transaction-safe printer UI, 12-second four-frame printer carriage, post-commit raw hold, crossfade/sparks/departure, checkpoint6/UI tests, and accepted 720x1280 + 1280x720 captures | READY |
| Android arm64 review export | Signed debug APK `PrintForge-Legends-0.5.1-alpha-arm64.apk`, package/version metadata, sensor orientation, launcher icon, workshop splash, arm64 archive audit, and SHA-256 in `VALIDATION.md` | READY for credential-free review |

## Credential-dependent production blockers

GodotSteam plus a Steam App ID/tickets; a Nakama runtime/SDK endpoint; PostgreSQL, hosting and signing; and approved production art/audio remain external production work. The local authority, local escrow, and offline recovery paths are credential-free substitutes.

## Credential-free internal alpha conclusion

The composed offline/internal-alpha loop is complete and verified: onboarding, workshop economy, Collection and Arcane Forge progression, team/deck building, deterministic combat/AI, one-time rewards, reload recovery, accessibility, local authority/trade, and the credential-free Windows internal export all have executable evidence. This does not represent production online/Steam readiness; the credential-dependent blockers above remain required for a production release.

## Future creature-sheet batch standard

Do **not** regenerate or alter the current four validated sheets. A future approved batch must retain the exact 4x2/eight-frame grid, friendly proportions, consistent idle/wind-up/strike/recovery/hit readability, and transparent output. Art direction should read visibly FDM-made: stronger horizontal layer ridges, deliberate part segmentation and assembly seams, occasional clean support-contact witness marks, matte PLA sheen and color variation, chunky printable wall thickness, plausible overhangs, and no soft organic or furry surfaces.

The current four sheets remain the awakened/living forms. A later non-gameplay awakening presentation seam may map each catalog creature to a separate raw, fresh-off-the-build-plate pre-awakening sprite: single-color matte PLA, strong layer ridges, segmented seams, support nubs or contacts, a small raft/brim, and a rigid dormant pose. A magic filament-spark/crossfade may then reveal the existing living sheet. This is future art/UI work only and must not alter combat state, the current sheets, or catalog gameplay IDs.

Checkpoint 6 implements the approved dedicated 2D Arcane Forge printer presentation: its four generated carriage frames reveal the raw-print sprite bottom-to-top, followed by a committed raw hold, cyan/amber sparks, living crossfade, and a short departure. Reduced motion uses calm staged fades with no rapid sweep or flash. The validated living sheets remain unedited.

The Arcane Forge/raw-print/awakening presentation is durable and verified in checkpoint 6. Future production integrations remain outside this completed credential-free internal alpha.
