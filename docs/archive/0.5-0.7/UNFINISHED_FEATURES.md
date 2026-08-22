# PrintForge Legends — unfinished-feature roadmap (archived 0.5–0.7)

> Historical roadmap. Its legacy battle, save, and progression assumptions are
> superseded by the v3.1 design reference and current architecture document.

**Audit date:** 2026-08-15  
**Source baseline:** `SolBranch-Clean` at `8f4a4fb`  
**Scope rule:** This is a prioritized implementation and product-decision backlog, not permission to expand scope. Complete an item only after its listed Definition of Done (DoD) is demonstrated with source-controlled tests, focused visual/device evidence where relevant, and release evidence. Do not revive an item in **Product decisions required** unless it is explicitly accepted first.

## Already verified — do not redo

- [x] Credential-free internal alpha loop: onboarding, permanent starter, economy, blueprint/print, two-creature team, 15-card deck, deterministic win, one reward, and save/journal reload are exercised by `tests/test_alpha_loop.tscn`; see `docs/ALPHA_ACCEPTANCE.md` and `docs/VALIDATION.md`.
- [x] All 24 catalog creatures have accepted living 4x2 sheets and raw-print pairs, with source contract coverage in `tests/test_art_batch_20.tscn` and manifest evidence in `docs/ART_BATCH_20.md`.
- [x] Arcane Forge is transaction-safe and visually staged (preview, print, raw hold, awakening, departure), with pure/UI coverage in `tests/test_checkpoint6.tscn` and `tests/test_ui_checkpoint6.tscn`.
- [x] Responsive sensor-orientation shell and portrait Forge captures are present in `project.godot`, `tests/capture_checkpoint2.gd`, and `docs/VALIDATION.md`; this is not a complete device/accessibility matrix.
- [x] Revisioned local hot-seat and credential-free local escrow trade are covered by `scripts/battle/local_battle_authority.gd`, `scripts/online/local_trade_authority.gd`, `tests/test_checkpoint5.tscn`, `tests/test_ui_checkpoint5.tscn`, and `tests/test_save_recovery.tscn`.
- [x] Offline primary/backup save recovery and journal acknowledgement are covered by `scripts/core/save_service.gd` and `tests/test_save_recovery.tscn`.
- [x] Spatial Workshop navigation is complete for the current 2D direction: matched v4 landscape/portrait plates use ten transparent, accessible direct-object hotspots for the pictured printer, drawers, team display, equipment cubby, Battle Arena, card deck, terminal panels, and calibration dial. The overview has no Door/Yard route or hotspot boxes; its printer opens the unified Arcane Forge directly, with an idle in-screen learned-blueprint cartridge selector and no printer close-up or separate tray. The dial claims in place, Support Card Archive retains `Edit Deck`, and the Battle Arena Hub preserves the existing proving logic. Legacy focused Maker close-ups retain bounded portrait panning, compact drawers, reduced-motion-safe presentation, and Back/Escape behavior. See `docs/WORKSHOP_NAV_ART.md` and the current Workshop navigation section in `docs/VALIDATION.md`.

## Critical path and ordering

1. **Contain and automate safety first:** revoke the exposed historic remote credential, clean the compromised history without bringing it into `SolBranch-Clean`, and establish secret scanning/CI before any online deployment.
2. **Make the local product coherent:** fix unreachable/unfinished workshop and battle controls, then deepen collection, deck, armor, progression, and opponent loops.
3. **Choose and implement the online authority:** server BattleRules parity and database migrations must precede matchmaking, online rewards, production trade, or Steam tickets.
4. **Finish platform and content quality:** complete art/audio/accessibility/localization plus real-device platform validation before signed release distribution.
5. **Operate safely:** observability, backup/recovery rehearsal, balance telemetry, and migration compatibility gate public alpha/beta.

## P0 — correctness and security

- [ ] **Contain the historic remote credential incident.** An old remote `SolBranch` exposed a token; revoke it at the provider, invalidate dependent sessions, and remove/rewrite the credential from the remote history without fetching, merging, or otherwise contaminating `SolBranch-Clean`.
  - **DoD:** provider confirms revocation; a fresh, authorized clone/history scan finds no token; an incident note records scope and rotation completion without storing secret values.
  - **Depends on:** repository-owner authorization and provider access.

- [ ] **Add sanitized CI and secret scanning.** Protect branch checks and artifacts without embedding credentials in source, presets, logs, or test fixtures.
  - **DoD:** CI runs Godot parser/tests and `backend` checks from clean caches; secret scanner blocks known test patterns; release logs redact keystore/token material; no real secret is committed.
  - **Depends on:** P0 incident containment.

- [x] **Repair the workshop calibration-job route and define daily limits.** `ProgressionRules.complete_calibration()` and `GameManager.complete_workshop_job()` now use `last_job_day`/`daily_job_count`, a supplied YYYY-MM-DD key, a three-pattern daily cap, and a reachable Calibration Bench in `scripts/ui/main.gd`.
  - **Evidence:** `tests/test_checkpoint_a.tscn` covers atomic reward/cap/rollover and `tests/test_ui_checkpoint_a.tscn` covers Workshop reachability; economy balancing remains P3 work.

- [x] **Expose legal battle concede in the UI.** Solo and local-versus screens now require a second Concede press before submitting the existing legal rule intent, expose Cancel Concede while armed, and disarm on any other intent or private handoff; local-versus remains no-reward.
  - **Evidence:** `scripts/ui/main.gd`, `tests/test_ui_checkpoint_a.tscn`, `tests/test_ui_checkpoint_a1.tscn`, and existing `tests/test_battle_rules.tscn` preserve canonical concede resolution and first-render portrait move access.

- [x] **Harden profile/save migration compatibility.** Schema migrations preserve released profile, deck, armor, shop, settings, journal, and server-revision fields; profiles from a newer schema open read-only without a local overwrite.
  - **Evidence:** `tests/test_offline_qa.tscn` migrates representative schemas 1 through 7 idempotently and verifies future-schema GameManager startup plus byte-preserving mutation refusal. `tests/test_save_recovery.tscn` retains backup, temp-write, and journal acknowledgement coverage.
  - **Depends on:** P0 CI for recurring validation.

## P1 — production backend and online authority

- [ ] **Replace adapter placeholders with real Steam integration.** `scripts/online/steam_adapter.gd` is a seam, not a GodotSteam implementation.
  - **DoD:** GodotSteam is integrated behind the adapter; Steam App ID/ticket lifecycle is validated in an authorized test environment; offline fallback is explicit; no App ID/ticket secret is bundled in public builds.
  - **Depends on:** P0 credential/CI work, platform decision, Steam partner access.

- [ ] **Implement Nakama authentication, matchmaking, reconnect, and canonical snapshots.** `scripts/online/nakama_adapter.gd` and `backend/src/authority.ts` are credential-free scaffolding only.
  - **DoD:** authenticated player identity, match create/join, reconnect timeout, authoritative snapshot/event replay, expected-revision rejection, and disconnect recovery work against a deployed test server.
  - **Depends on:** backend hosting, authentication/privacy decision, server BattleRules parity.

- [ ] **Establish authoritative BattleRules parity.** The GDScript rules in `scripts/battle/battle_rules.gd` must have a tested server authority equivalent before online ranking/rewards.
  - **DoD:** shared fixtures prove identical integer outcomes for every legal intent, shield/armor, opening restriction, cooldown, switch, card, concede, seed, and winner; server rejects malformed/stale/wrong-seat submissions.
  - **Depends on:** chosen server runtime and contract versioning.

- [ ] **Add PostgreSQL schema, migrations, and server journal reconciliation.** Local profiles already contain `server_revision` in `scripts/core/profile_rules.gd`, but no production reconciliation exists.
  - **DoD:** migrations create account/profile/inventory/deck/match/reward/trade/audit tables; local pending events reconcile idempotently against server revision; conflict, retry, and rollback cases are integration-tested.
  - **Depends on:** authoritative service and data-retention policy.

- [ ] **Move online rewards to the server.** Local one-claim rewards are correct for offline play, but online outcomes cannot trust the client.
  - **DoD:** server awards once from a resolved canonical match, client receives an idempotent receipt, duplicate/replay attempts are refused, and local/offline rules remain clearly separated.
  - **Depends on:** BattleRules parity and database migrations.

- [ ] **Build production trade pairing and escrow.** The local demo trade in `scripts/online/local_trade_authority.gd` is intentionally session-only.
  - **DoD:** authenticated pairing, dual revision locks, eligibility recheck, atomic database swap, expiry/cancel, immutable audit receipt, recovery after disconnect, and abuse-rate limits exist; trade remains kid-safe with no freeform chat.
  - **Depends on:** authentication, inventory schema, privacy/moderation policy, observability.

- [ ] **Publish privacy/data handling policy and operational safeguards.** Online identity, telemetry, trade, and backups require an explicit policy.
  - **DoD:** data inventory, retention/deletion policy, consent/age handling, incident runbook, least-privilege credentials, encrypted backups, restore rehearsal, and access audit are reviewed before external testing.
  - **Depends on:** chosen accounts, hosting regions, and legal review.

## P1 — game-loop depth

- [x] **Turn Print Yard into a playable progression station.** `ProgressionRules.visit_print_yard()` now grants one bounded deterministic day-keyed drill: Field Practice (+12 XP), Team Bond (+5 mastery to each saved-team instance), or a capacity-4+ one-shot solo Spool Warmup. `GameManager` journals the accepted choice.
  - **Evidence:** `tests/test_workshop_depth.tscn` covers the transitions and `scripts/ui/main.gd` exposes explicit state/availability. Reward tuning/tutorial work remains P3.

- [x] **Make XP and spool progress legible and consequential.** The Workshop progression strip and Print Yard show XP/current threshold; `ProgressionRules.grant_xp()` immediately converts threshold crossings into spool capacity used by battle.
  - **Evidence:** the checkpoint-A pure test forces a Print Yard threshold crossing and asserts the spool increase. Broader economy targets remain P3.

- [x] **Add an ordered offline Workshop Trial campaign.** Five authored tiers / 20 fixed encounters now unlock sequentially through `Catalog.WORKSHOP_TRIAL_TIERS` and `CampaignRules`; first clears atomically grant tier-scaled coins, XP, and per-instance current-team mastery, while replay only improves a lower best-turn record.
  - **Evidence:** `tests/test_campaign_rules.tscn` covers schema migration, locks, rewards, idempotence, replay best turns, boss unlocks, mastery, and fixed boss teams; `tests/test_ui_trials.tscn` covers Proving Door separation, locked/start states, victory return, one revision, and mastery UI. Mastery combat effects and balance tuning remain explicitly out of scope.

- [ ] **Complete opponent/team diversity and balance passes.** Training now uses the deterministic date-keyed `ProgressionRules.training_opponent()` seam rather than one hard-coded rival, with same-day/repeatable variety tests. Every catalog creature now has a deterministic signature and legal Apprentice/Craftsman/Master scoring path, but unlock bands, telemetry, and balance targets are still required.
  - **DoD:** seeded rival roster/team generator covers catalog elements/rarities within intended unlock bands; deterministic fixtures test legal decks/loadouts; balance sheet tracks win rate, turn length, opening fairness, and ability/card usage.
  - **Depends on:** stable XP/spool economy and catalog balance targets.

- [ ] **Complete multiple named deck slots and active-deck selection.** Five safe named slots can save/select legal 15-card decks and battle reads the active deck. Slot creation, duplication, deletion, and a product-approved naming policy remain unfinished.
  - **DoD:** player can create, rename from fixed/safe choices or an approved text policy, duplicate/delete/select slots, see validity/owned-copy feedback, and battle consumes the selected saved deck; migration and controller tests pass.
  - **Depends on:** product decision on freeform naming/localization.

- [ ] **Complete armor lifecycle and presentation.** The Armor Workbench now supports atomic unequip and reassignment, with rules and UI coverage. Detailed collection/team/battle visual presentation remains unfinished.
  - **DoD:** player can unequip, move an equipped item safely, see every armor modifier in collection/team/battle, and never leaves duplicate/missing assignments; pure/profile/UI regressions cover all transitions.
  - **Depends on:** armor visual/UI pass.

## P2 — art, audio, UI, and accessibility

- [ ] **Finish final approval, VFX, and animation for all 24 living/raw creature pairs.** The pairs are accepted placeholders/production candidates, not a fully approved combat/presentation set; see `docs/ART_BATCH_20.md` and `docs/ART_GENERATION_LEDGER.md`.
  - **DoD:** each creature has approved raw/living presentation, consistent 4x2 frame semantics, combat readability, alpha/edge QA, Arcane Forge compatibility, and performance-budget evidence; no existing approved sheet is silently regenerated.
  - **Depends on:** current 2D direction remains accepted.


- [ ] **Finish the approved audio mix.** The credential-free baseline now has fixed Master/Music/SFX levels plus captioned procedural Workshop/Battle/Forge/button/impact/card tones through `scripts/ui/audio_director.gd`; approved music and final SFX are still absent.
  - **DoD:** bus layout, mute/master/music/SFX controls, safe default levels, loop/transition behavior, subtitle/caption policy for gameplay-critical sound, and no unlicensed content are validated in a mix pass.
  - **Depends on:** approved audio assets and platform QA.


- [x] **Complete offline support-card art and collection presentation.** All 30 catalog cards have cached 4x2 landscape 3:2 atlas regions (plus a private card back), a unified 2:3 workshop/navy/brass frame with explicit cost/rules/target/rarity/copy/disabled text, full-frame source art with no crop or side bars, Maker-reachable archive, deck gallery, shop integration, and horizontal portrait-card carousels in solo/local hands with discard counts. `tests/test_support_card_system.tscn` proves every card resolves and discards deterministically. See `docs/CARD_SYSTEM.md`.
  - **Remaining:** localization and a device accessibility matrix remain separate P2 work.


- [ ] **Complete UI text and localization readiness.** A shipped-text scan found no current mojibake/replacement-character match in UI/docs, including `scripts/ui/main.gd`; strings are not yet centralized and no pseudolocale pass exists.
  - **DoD:** repository scan has no known mojibake/replacement characters in shipped text; pseudolocale capture has no clipping; fixed labels and future translation IDs cover onboarding, battle, trade, Forge, settings, and errors.
  - **Depends on:** localization language/product decision.

- [ ] **Run the full portrait/touch/controller/accessibility screen matrix.** Sensor layout is verified only in focused Forge captures.
  - **DoD:** onboarding, Workshop, shop, collection, team, armor, deck, battle, hot-seat handoff, trade, settings, and Forge are captured/tested at 720x1280 and 1080x1920 plus landscape; touch targets, scroll, focus order, Escape/back, text scales, high contrast, and reduced motion meet documented criteria.
  - **Depends on:** UI completion above and physical Android testing.

## P2 — platform and release

- [ ] **Perform Android physical-device smoke and compatibility validation.** `docs/VALIDATION.md` records a signed arm64 debug APK but no attached-device install/launch.
  - **DoD:** install, cold launch, rotation, suspend/resume, touch, back navigation, save/recovery, performance, and uninstall/reinstall behavior are tested on a representative arm64 device matrix with logs/screenshots.
  - **Depends on:** current Android review APK and device access.

- [ ] **Produce Android AAB/release signing/Play readiness.** Debug signing is not a release channel.
  - **DoD:** protected release keystore process, reproducible AAB, versioning, Play Console internal track, Data safety/store listing/assets, pre-launch report, and rollback plan are approved; no signing material enters the repository.
  - **Depends on:** product/privacy policy, device matrix, Play account access.

- [ ] **Rebuild/sign the current Windows/Steam release and prepare depot delivery.** Existing Windows internal export evidence is not a Steam release.
  - **DoD:** clean reproducible Windows export, code-signing decision, Steam build/depot scripts, App ID/ticket test, install/update/uninstall smoke, and artifact/SBOM/hash retention are complete.
  - **Depends on:** Steam integration, partner access, release signing policy.

## P3 — QA, balance, and operations

- [ ] **Create a performance and device matrix.** Measure rendering, memory, battery/thermal behavior, input latency, and load/save behavior across supported Windows and Android hardware.
  - **DoD:** target budgets and minimum specs are published; automated/recorded smoke results cover low/mid/high tiers; regressions block release candidates.
  - **Depends on:** stable content, telemetry/observability, physical-device access.

- [ ] **Add production observability, backup, and incident drills.** Local save recovery is covered; service operations are not.
  - **DoD:** privacy-safe metrics/logging/traces, alert thresholds, database and object-storage backups, restore test, trade/reward audit search, rate-limit monitoring, and incident ownership are documented and rehearsed.
  - **Depends on:** deployed backend and data policy.

- [ ] **Formalize balance and content QA.** Use deterministic catalog fixtures plus human playtests rather than changing integer combat rules ad hoc.
  - **DoD:** rarity/price/reward curves, element matchups, AI difficulty, support-card efficacy, armor modifiers, and opponent variety have approved target ranges; regression simulations and accessibility playtests are retained.
  - **Depends on:** game-loop depth and telemetry plan.

## P3 — refactors deliberately deferred

- [ ] **Decompose the monolithic Main screen.** `scripts/ui/main.gd` owns navigation, rendering, battle, Forge, trade, and fixtures.
  - **DoD:** feature screens/presenters have narrow typed interfaces, retain keyboard/back behavior, and pass existing capture/UI tests without visual regression.
  - **Depends on:** stable screen scope and full UI matrix.

- [ ] **Introduce typed profile and battle state models at boundaries.** Current dictionaries intentionally keep migrations flexible but increase dynamic-field risk.
  - **DoD:** schema adapters preserve saved JSON compatibility, pure rules remain deterministic, static/type checks improve, and migration fixtures prove round-trip compatibility.
  - **Depends on:** schema/version policy.

- [ ] **Persist the printer widget instead of rebuilding it each render.** The current full-render model is safe but limits richer animation composition.
  - **DoD:** persistent stage has no duplicate commit/timer/input bugs, reduced motion remains deterministic, and sequence/UI/capture regressions remain green.
  - **Depends on:** Main decomposition.

- [ ] **Split the capture harness by feature.** `tests/capture_checkpoint2.gd` carries historical modes across multiple checkpoints.
  - **DoD:** independent, bounded capture scenes share only small common helpers; each asserts dimensions/header safety and writes isolated evidence with no real-save mutation.
  - **Depends on:** stable screen ownership.

## Product decisions required — not accepted unfinished scope

The following are historical or superseded ideas. They are **not** planned backlog work until a product owner explicitly accepts them and supplies scope, audience, platform, cost, and success criteria.

- [ ] **Roster scale:** revive a historical 256-creature roster, or keep the current curated 24-creature catalog?
- [ ] **Board/printing concept:** revive historical 4x2 grid / Core Printer mechanics, or retain the current 2D support-card battler and Arcane Forge flow?
- [ ] **Platform expansion:** add HTML5, Linux, or iOS beyond the current Windows + Android review direction?
- [ ] **Educational content:** add educational quests, overworld exploration, bosses, or other curriculum-oriented loops?
- [ ] **Monetization:** add IAP, and if so what child-safe, regional, and platform-compliant constraints apply?
- [ ] **Visual direction:** replace/supplement the current 2D sprite direction with 3D GLB creatures/models, or explicitly keep 2D as the production direction?
- [ ] **Social layer:** add friends, invites, leaderboards, guilds, or other social features beyond local hot-seat and controlled trade?

**Decision DoD for any accepted historical idea:** a signed product brief explicitly replaces this “not accepted” status, identifies affected systems and privacy/platform implications, defines a bounded milestone, and adds it to the critical-path order before implementation starts.
