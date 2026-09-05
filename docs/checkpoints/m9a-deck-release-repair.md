# PrintForge M9A exported deck release repair

Status: **source and compiled-APK repair gates pass; APK and README delivered and
hash-verified on DriveFS; cloud sync and physical Android acceptance unconfirmed**

Date: 2026-09-05

Entry baseline: branch `spike/printforge-physical-ui`, `c67ce86`; affected delivered
artifact `PrintForge-Legends-0.8.7-founder-navigation-arm64-7ec8920bfd48.apk`.

Authority: the v3.2 catalog/profile rules, M3 Deck/Pre-Print contract, M8 Back and
save-atomicity contract, M9 Requirement 4 Founder sequence, and the approved M9A
portrait visual family. This checkpoint supersedes only the prior claim that desktop,
editor, and static-package evidence established a usable exported Founder-to-battle
deck path. It does not reopen the approved atlas, simplified Plan -> Run Cycle loop,
card art, or card back.

Approval status: **no user approval is outstanding**. The existing art family and
simplified battle loop remain approved; this repair introduces no new human gate.

## Reported regression and bounded diagnosis

The delivered Android build can present card backs instead of usable owned card
fronts, preventing the player from building a legal deck and starting a bot match.
Static inspection confirms that the original APK's inventory remains 611 entries and
its packaged catalog still contains all 57 card records. It also confirms one export
mismatch: `filament_ring` refers directly to
`res://assets/cards/v3/filament_ring_art_v1.png`; the APK lacks that raw PNG while its
Godot import metadata/payload is present, and current catalog validation uses a direct
`FileAccess.file_exists` check whose error makes `cards()` reject the whole catalog.
The shipped-APK compiled extraction probe confirmed the runtime cause: PID `53392`,
2026-09-05 07:25:03.556-07:25:04.884 CT, exit `0`, reported
`file_exists=false`, `resource_exists=true`,
`validation_errors=["v3 non-creature direct art path is invalid: filament_ring"]`,
and `card_count=0`. Retain its attributed log at
`build/evidence/deck-export-repair-20260905/shipped-assets/build/evidence/deck-export-repair-20260905/shipped-catalog-probe-v1/engine.log`.

The repair is outcome-bound. It must make resource validation export-safe without
weakening card identity, catalog schema, or required-art checks. Any genuine missing
or invalid catalog/required-presentation content is a blocking read-only package
error before profile normalization or writes; it must never become an empty catalog,
a face-down owned collection, or a reason to create, migrate, repair, or overwrite a
profile.

## Confirmed repair and source evidence

- The bounded catalog correction uses an import-aware resource existence check. All
  57 required catalog resources/fronts pass in the source fixture while strict genuine-
  missing-content rejection remains active.
- A genuine catalog or required-presentation failure now enters the pre-normalization,
  read-only package-error state with native content-unavailable/update guidance, safe
  Exit, and no New Maker or save write.
- Startup also exposed an independent persistence regression: comparing normalized
  in-memory JSON integer/float representations caused an unnecessary rewrite of an
  otherwise valid save. The bounded correction compares JSON values, preserves valid
  save bytes, and still persists a real missing-field migration. The source fixture
  ran as PID `61256` and exited `0`.
- Root-confirmed source suites pass for all-57 resource/front integrity, rules,
  Founder progression, the no-Ad contract, all `18/18` Back routes, Back transaction
  atomicity, and live controls.
- Affected incomplete Founder saves exposed a second, narrowly related issue:
  while the old package recorded receipts, its empty catalog prevented ownership
  grants. The existing completed-Founder repair already restored the earned deck
  on restart. The repair now runs in the same atomic third-Keep candidate, only for
  `founder_v1` with `entitled == 3` and `kept == 3`, after clearing the receipt.
  Earlier Keeps and paid packs are unchanged. No new grant rule or schema was added.
  Root PID `36036` passed immediate legal-40 recovery, duplicate-Keep rejection,
  repeat-ensure equivalence, saved-profile reload, and failed-storage atomicity.
- Final source candidate checks passed on 2026-09-05: missing-grant recovery
  (`36036`), valid-save byte preservation and real migration (`61676`), unified
  rules (`59880`), Founder progression (`62308`), and rendered all-three-starter /
  all-five-paid-pack input (`45656`, Windows Forward+). Mobile-rendered Deck input
  passed at 576 (`63308`) and 720 (`7688`): actual plus/minus controls build a legal
  second slot, Save activates it exactly once, reload retains it, and bot opening
  hand plus remaining deck match the same 40-card multiset.
- The read-only reviewer passed the 576/720 Deck, bot-opening, and corrected package
  error captures with no P0/P1. The initial detached Exit was retained as failed
  evidence and corrected onto the existing cream action plate. Corrected guard
  PIDs `55180` / `58612` passed geometry, parsed touch Exit, and no-save-write checks.
- These source results are separate from the compiled-APK proof recorded below.
  Affected-player physical-device upgrade and Android acceptance remain unverified;
  no desktop result has been labeled as a physical-phone pass.

### Durable source review images

- [576 Deck](<E:/AI Projects/games/3d print battler/build/evidence/deck-export-repair-20260905/deck-input-source-576-mobile-v2/qa-save/deck-export-second-slot-legal-576x1024.png>) and [576 bot opening](<E:/AI Projects/games/3d print battler/build/evidence/deck-export-repair-20260905/deck-input-source-576-mobile-v2/qa-save/deck-export-bot-opening-hand-576x1024.png>).
- [720 Deck](<E:/AI Projects/games/3d print battler/build/evidence/deck-export-repair-20260905/root-final-input-v2/test_deck_export_input-720/qa/deck-export-second-slot-legal-720x1280.png>) and [720 bot opening](<E:/AI Projects/games/3d print battler/build/evidence/deck-export-repair-20260905/root-final-input-v2/test_deck_export_input-720/qa/deck-export-bot-opening-hand-720x1280.png>).
- [Corrected 576 package error](<E:/AI Projects/games/3d print battler/build/evidence/deck-export-repair-20260905/root-candidate-validation-v1/test_catalog_package_guard-576/qa/catalog-package-unavailable-576x1024.png>) and [corrected 720 package error](<E:/AI Projects/games/3d print battler/build/evidence/deck-export-repair-20260905/root-candidate-validation-v1/test_catalog_package_guard-720/qa/catalog-package-unavailable-720x1280.png>).
- [Retained failed 720 Exit placement](<E:/AI Projects/games/3d print battler/build/evidence/deck-export-repair-20260905/root-final-input-v2/test_catalog_package_guard-720/qa/catalog-package-unavailable-720x1280.png>) — not the release candidate.

All process records, logs, profiles, and captures are durable under
`build/evidence/deck-export-repair-20260905/`. Invalid wrapper/argument-order and
timed-out attempts are not counted as passes. Final source engines were direct,
hidden task-owned launches with isolated E: saves and logs; no task-owned Godot or
Windows crash-report process survived the root cleanup inspection. The Android SDK
reported no connected device. Desktop Mobile renderer evidence is not Android OS,
touch-device, lifecycle, or no-data-clear install evidence.

## Packaged candidate evidence — 0.8.8 / 4c78ed6df9e6

APK export PID `50004` completed cleanly (08:35:54–08:36:20 CT). Package version is
`0.8.8-deck-export-fix`, code `104`, arm64 portrait, no ads. The signing certificate
is unchanged from 0.8.7. Static package, launcher alias, 16 KB alignment, v2/v3 signing,
stock native/DEX dependency, exclusion, and advertising-absence checks all pass.

The APK is **241391544 bytes**, SHA-256
`AA446B261FF38A003D97A4640E6D8F1917D4E543E0EDD73E572D29AD52C83D97`.
All **611** extracted runtime entries (**211097758 bytes**) matched their original
APK bytes and hashes both before and after every probe. Only isolated QA harnesses
were added to extracted `build/evidence`; no authoring image or source runtime was
injected. The maintained runner is `tools/run_catalog_export_probe.ps1 -RunDeckInput`.

| Actual packaged-runtime check | PID | Result |
| --- | --- | --- |
| All 57 front resources and type ledger | 55092 | PASS |
| 576 rendered Deck edits, exact save/reload, bot entry | 57444 | PASS |
| 720 rendered Deck edits, exact save/reload, bot entry | 62212 | PASS |
| Affected Founder save recovery / atomic final Keep | 55208 | PASS |
| Unchanged-save bytes and real migration | 63520 | PASS |
| 720 genuine-content fault / no-write / parsed touch Exit | 61836 | PASS |

Every listed process exited `0` and was confirmed cleaned up. The first supplemental
save-fixture attempt (`61464`) used an excessively nested Windows QA directory; its
261-character fixture directories could not be opened for save promotion. It is
retained as failed harness evidence. The unchanged compiled runtime and byte-identical
test scripts passed with shorter, still-isolated E: QA roots (`q-mg`, `q-up`, `q-guard`).
This does not establish or imply an Android storage defect.

Read-only visual review passed all four packaged Deck/bot frames; each is byte-identical
to its reviewed source counterpart. Physical Android install, touch/hardware Back,
lifecycle, performance, and no-data-clear upgrade remain unverified. No connected
device or emulator was available. This is a functional repair review, not a new art
approval request or a claim of complete Android acceptance.

### Durable compiled-APK images

- [Packaged 576 Deck](<E:/AI Projects/games/3d print battler/build/evidence/deck-export-repair-20260905/release-4c78ed6df9e6/packaged-runtime-v1/shipped-assets/build/evidence/deck-export-input/deck-shipped-576x1024/qa-save/deck-export-second-slot-legal-576x1024.png>) and [packaged 576 bot opening](<E:/AI Projects/games/3d print battler/build/evidence/deck-export-repair-20260905/release-4c78ed6df9e6/packaged-runtime-v1/shipped-assets/build/evidence/deck-export-input/deck-shipped-576x1024/qa-save/deck-export-bot-opening-hand-576x1024.png>).
- [Packaged 720 Deck](<E:/AI Projects/games/3d print battler/build/evidence/deck-export-repair-20260905/release-4c78ed6df9e6/packaged-runtime-v1/shipped-assets/build/evidence/deck-export-input/deck-shipped-720x1280/qa-save/deck-export-second-slot-legal-720x1280.png>) and [packaged 720 bot opening](<E:/AI Projects/games/3d print battler/build/evidence/deck-export-repair-20260905/release-4c78ed6df9e6/packaged-runtime-v1/shipped-assets/build/evidence/deck-export-input/deck-shipped-720x1280/qa-save/deck-export-bot-opening-hand-720x1280.png>).
- [Packaged 720 safe content error](<E:/AI Projects/games/3d print battler/build/evidence/deck-export-repair-20260905/release-4c78ed6df9e6/packaged-runtime-v1/shipped-assets/build/evidence/q-guard/catalog-package-unavailable-720x1280.png>).

## Verified release delivery

At **2026-09-05 08:50:22 CT**, the release APK and README were copied, without
overwriting existing files, to `H:\My Drive\AI Projects\PrintForge`.

- [APK on DriveFS](<H:/My Drive/AI Projects/PrintForge/PrintForge-Legends-0.8.8-deck-export-fix-arm64-4c78ed6df9e6.apk>):
  241391544 bytes; SHA-256 `AA446B261FF38A003D97A4640E6D8F1917D4E543E0EDD73E572D29AD52C83D97`.
- [README on DriveFS](<H:/My Drive/AI Projects/PrintForge/README-0.8.8-deck-export-fix-4c78ed6df9e6.md>):
  4987 bytes; SHA-256 `C106AB06F42494C48B32F82996A6A6574E50448A368584BCF479EE3749040429`.
- [Durable local APK](<E:/AI Projects/games/3d print battler/build/android/PrintForge-Legends-0.8.8-deck-export-fix-arm64-4c78ed6df9e6.apk>) and
  [local README](<E:/AI Projects/games/3d print battler/build/android/README-0.8.8-deck-export-fix-4c78ed6df9e6.md>).

Both local/DriveFS pairs match byte size and SHA-256. The delivery receipt is
`build/evidence/deck-export-repair-20260905/release-4c78ed6df9e6/drivefs-delivery.json`.
No cloud connector was available, so cloud-visible synchronization is **unconfirmed**,
not inferred from the mount. The older 0.8.7 APK and README were retained unchanged.

This candidate needs an on-device review, not another art/design approval. Install
over the same-package previous playtest without uninstalling or clearing saved data.
The runtime source is commit `4c78ed6df9e61711be380923bf5f08db37737dce`; later evidence-only
documentation commits do not change the qualified binary. The maintainability review
kept the repair at the catalog boundary, profile bootstrap, and existing final-Keep
transaction; it added no duplicated reward algorithm, save schema, assets, or ad code.

## Locked boundaries

- Keep exactly 57 catalog IDs and type counts `24/11/4/6/4/8`; change no card facts,
  Founder contents/order, ownership rule, 40-card minimum/no maximum, economy,
  Pre-Print rule, bot authority, reward, RNG, or save schema.
- Reuse the approved card fronts, blueprint family, physical portrait screens, and
  exact card back. The card back is permitted only for intentionally concealed rival
  hand/deck information; it is never a fallback for a face-up receipt, owned tray,
  Deck Workbench entry, inspector, player hand, or public card.
- Portrait only. Dynamic identity, facts, counts, legality, error copy, focus, and
  accessibility remain native controls with existing 48/56-pixel targets, 150% text,
  high contrast, reduced motion, and safe-area behavior.
- No new gameplay, card, catalog, art, visual direction, or approval gate. Do not
  generate or promote art as part of this repair.
- Add no AdMob SDK, identifier, request, creative, disclosure, reward, or blank strip.
  Production Godot bottom reserve remains `0`; if a separately approved native host
  is used later, it alone owns the banner creative and bottom safe inset outside the
  resized Godot surface.
- Do not overwrite the affected APK. Any repair delivery is a new versioned artifact
  with its own source identity and SHA-256.

## Contract 1 — exported catalog and face-up presentation integrity

- **Entry:** A source/editor run, desktop exported-content run, or installed Android
  build performs package/catalog integrity validation before it normalizes, creates,
  or writes any fresh or compatible existing v3 profile. An existing snapshot may be
  read first; the package-error path preserves that read-only data.
- **Player decision:** After a valid package passes, use the existing Continue/New
  Maker and face-up card decisions. If required content is genuinely missing or
  invalid, the only player action is safe Exit; there is no resource-repair choice.
- **Result:** The exported runtime validates and exposes all 57 stable catalog IDs,
  with every required presentation resource loadable by Godot's export-runtime
  semantics. Every face-up ID retains its authoritative native facts and approved
  front. Strict identity, catalog-schema, and required-art validation remain intact.
- **Failure:** Any genuine missing or invalid catalog or required-presentation content
  blocks startup as a read-only package error before profile normalization, creation,
  repair, migration, or persistence. It may not return an empty catalog as success,
  substitute the concealed card back, invent a generic identity, route into an empty
  deck, or touch primary/backup save data.
- **Disabled:** Continue, New Maker, Founder claim, Deck Save/Activate, bot Begin, and
  every other profile-mutating action are unavailable in the blocking package-error
  state. Safe Exit remains reachable; no new Retry or partial-catalog route is added.
- **Feedback:** One native blocking message states that an update is required and
  player data was not changed. Attributed diagnostics identify the failed stable ID
  and validation class without exposing a user path or secret. A zero-card success
  state is forbidden.
- **Progression:** Package/catalog validation and the blocking error occur before
  profile normalization or writes. They cannot alter ownership, blueprints, models,
  decks, Pre-Prints, Founder counters/receipts, currency, RNG, rewards, onboarding,
  profile revision, primary save, or backup.

## Contract 2 — fresh Founder ownership to editable legal deck to bot

- **Entry:** Empty isolated storage creates a genuine `founder_v1` profile and enters
  `choose_starter`; run independent fixtures for Cinderpaw, Aquafin, and Voltwig.
- **Player decision:** Choose and complete the free First Print; claim, page through,
  Back/reload where specified, and Keep Founder receipts 1, 2, and 3; open Deck; use
  actual visible controls to construct the exact owned 40-card Founder multiset in a
  second fixed deck slot, Save and Activate it; then begin the existing first playable
  offline bot challenge.
- **Result:** Starter choice grants one card/license and a one-card provisional deck.
  The three ordered 13-card claims atomically produce deck/owned counts `14`, `27`,
  and `40`; Keep grants no cards. Every receipt page, owned tray entry, deck entry,
  inspector, and player face-up battle card uses its real known front. The second slot
  accepts the same owned 40-card configuration, persists once, becomes active, and
  reloads legal. Bot preflight starts from that active deck; opening hand plus
  remaining deck preserve its exact 40-card multiset.
- **Failure:** Any hidden receipt card, card-back substitution, unknown/generic owned
  ID, empty owned tray, missing add/remove control, wrong count/order, over-ownership,
  partial combined Deck/Pre-Print persistence, lost active slot, illegal preflight,
  empty battle deck, crash, or return to onboarding keeps the repair open. Rejection
  preserves the last accepted profile and draft as required by the existing contract.
- **Disabled:** Next Founder claim is disabled while a receipt is pending. Deck
  Save/Activate is disabled below 40, for an unknown ID, or when any count exceeds
  ownership; an over-owned Add is disabled with its reason. Bot Begin is disabled
  until the selected active deck is saved and legal. Presentation failure cannot
  enable any of these actions.
- **Feedback:** Founder pages remain `1/3`, `2/3`, `3/3` at five cards per page and
  visibly advance `1 -> 14 -> 27 -> 40`. Deck shows owned/current counts, legal or
  exact invalid reason, saved/active slot receipt, and caller-safe Back. Bot preflight
  names the selected legal deck; rival concealed cards alone use the approved back.
- **Progression:** Claims retain the existing atomic ownership/deck/pending/opened
  transaction; Keep increments only `kept` and clears pending. Local Deck edits do not
  mutate the profile. One accepted combined Save/Activate journals once. Preflight is
  zero-mutation, and battle uses the existing deterministic authority with no new
  grant, balance, seed, or pacing rule.

## Contract 3 — existing-save and interrupted-Founder preservation

- **Entry:** Launch the repair over isolated byte-copied valid fixtures representing
  (a) a complete unmarked pre-Founder v3 profile, (b) `founder_v1` after starter
  selection, after First Print, at each partial `opened`/`kept` boundary with and
  without a pending receipt, (c) `opened == kept == 3`, and (d) a valid profile written
  by the affected 0.8.7 build with nonempty ownership, licenses/models, saved/active
  decks, Pre-Prints, and progression.
- **Player decision:** After package validation passes, Continue; resume the exact
  pending Founder receipt or next lawful step; inspect owned fronts and decks;
  Back/reload; and Save/Activate only after an explicit legal edit. If package
  validation fails, choose safe Exit only; never use New Maker as content recovery.
- **Result:** Every valid fixture resumes its recorded route and stable IDs. Complete
  unmarked profiles remain unmarked and receive no Founder content. Partial Founder
  profiles preserve selected starter, print result, counts, pending receipt order,
  deck, and ownership, then continue only the remaining claims/acknowledgements.
  All-kept profiles remain complete. The 0.8.7 fixture retains every durable field
  while its known owned fronts and legal deck become usable again.
- **Failure:** Startup package validation failure, app upgrade, or route rebuild must
  not normalize or write a profile, call New Maker, migrate schemas, run starter-deck
  repair over an incomplete Founder profile, clear ownership, replace a deck with
  empty/default data, regrant a receipt, advance a counter, or overwrite the primary/
  backup. Existing recovery handles malformed/unsupported saves only after valid
  package content is established and without destructive fallback.
- **Disabled:** On package failure all profile actions, including Continue and New
  Maker, are unavailable; safe Exit is the only action. With valid package content,
  existing invalid/incompatible-save and recovery rules remain unchanged.
- **Feedback:** The blocking package message communicates that game content is
  unavailable, an update is required, and player data was unchanged, then offers safe
  Exit only. After package validation passes, Founder and save recovery retain their
  existing exact pending/source/status feedback and never report a reset as a
  successful repair.
- **Progression:** Startup package validation and failure are pre-profile and perform
  zero normalization/writes. Successful upgrade and inspection are byte-identical for
  all durable gameplay fields. Only the explicit remaining Founder claim/Keep or
  accepted Deck Save/Activate may mutate, exactly once.

## Contract 4 — release evidence and Android acceptance

- **Entry:** A candidate is built from one identified clean source state into a new
  portrait arm64 APK, with an exported-content test fixture and an authorized physical
  Android device available for the final device gate.
- **Player decision:** On exported content, execute Contracts 1-3 through real visible
  controls. On device, perform both a fresh-install Founder-to-bot run and an in-place
  upgrade over the affected-version preservation fixture without clearing app data.
- **Result:** Editor/source regressions and the actual exported-content runtime/APK
  contents pass independently. When an authorized device is available, the installed
  candidate also shows owned fronts, saves/activates a legal deck, starts the bot,
  survives stop/relaunch, and preserves the upgrade fixture. Portrait content fills
  the usable surface with production reserve `0`, no ad request, blank bottom band,
  or covered control.
- **Failure:** An editor-only test, loose-project run, static APK file listing, or
  desktop exported-content run is not Android acceptance. Reinstalling after clearing
  data is not upgrade preservation. Wrong source/version/hash, device crash/ANR,
  landscape, lost save, backs on face-up cards, blocked deck/bot path, or unverified
  package resources fails the release gate.
- **Disabled:** With no authorized physical device, Android install/upgrade, touch,
  lifecycle, and screenshot checks remain `BLOCKED — no authorized device`; desktop
  exported-content evidence may pass only its explicitly named lower gate. After that
  lower gate passes, Sol/root may stage and identify the candidate as a
  **device-unverified review build**, never as fully Android-accepted.
- **Feedback:** Evidence records source hash, version/code, APK bytes/SHA-256, catalog
  count/type ledger, exported resource/load result, exact fixture transitions, device
  model/API/orientation, install-vs-upgrade mode, launch/relaunch outcome, and attributed
  logs/screenshots. DriveFS copy and cloud-visible sync are reported separately.
- **Progression:** Automated and fresh-device cases use isolated data. The upgrade
  case begins from a retained deterministic fixture and compares protected fields
  before/after; validation itself grants or resets nothing.
#### Affected-player review-release checklist

- [x] Retain the original 611-entry APK inventory and shipped runtime probe that
  proves the `filament_ring` direct-file check rejected all 57 otherwise packaged
  catalog records.
- [x] Source repair uses import-aware validation, retains strict genuine-failure
  blocking, performs no pre-profile write, and preserves valid save bytes while still
  persisting real missing-field migration.
- [x] Root-confirmed source suites pass all-57 resources/fronts, rules, Founder
  progression, no-Ad, Back `18/18`, Back atomicity, and live controls.
- [x] Export a new versioned arm64 APK and prove from that packaged runtime that all 57
  identities/fronts load and genuine required-content failure remains pre-profile,
  read-only, and safe-Exit-only.
- [ ] Upgrade without uninstalling or clearing data from an isolated affected-version
  fixture. Before/after evidence must preserve every fixed deck slot and contents,
  selected/active slot, Pre-Print order, owned cards, licenses/models, Founder counters,
  and any pending receipt ID/order/caller; startup alone must not rewrite valid bytes.
- [x] In source and desktop compiled-APK fixtures, resume a pending receipt exactly
  once, save/activate the intended legal deck,
  relaunch, and start the existing bot without a duplicate grant or empty/card-back
  substitution.
- [x] After packaged-content proof passes, Sol/root may stage and deliver a
  **device-unverified review build** with physical Android explicitly pending. A real
  no-data-clear device upgrade and fresh-device Founder-to-bot run are still required
  for full Android acceptance.
- [x] Copy the new non-overwriting APK/README to DriveFS, verify bytes/SHA-256, and
  report cloud-visible synchronization separately.

## Decision-complete acceptance criteria

1. The shipped-APK probe evidence records PID `53392`, its exact CT timestamps and
   exit `0`, and the observed `file_exists=false`, `resource_exists=true`,
   `filament_ring` validation error, and `card_count=0` in the named retained log.
2. Source and actual exported-content audits expose exactly 57 unique IDs with type
   counts `24/11/4/6/4/8`, and every referenced presentation resource is loadable by
   export-runtime semantics.
3. Fault injection for any genuine missing/invalid catalog or required-presentation
   content blocks before profile normalization/write, communicates content
   unavailable/update required and data untouched, permits safe Exit only, and never
   emits an empty catalog, card back, generic identity, New Maker path, or partial-
   catalog UI.
4. Each starter independently completes the exact `1/14/27/40` Founder path through
   real controls. All 39 claimed receipt occurrences are reachable in persisted order;
   Back/reload/Keep does not hide, reroll, duplicate, or regrant one.
5. From those owned cards, real Deck controls build the exact 40-card multiset in a
   second fixed slot. Under-40 and over-owned cases reject unchanged; legal Save and
   Activate commit once, survive reload, and remain selected at bot preflight.
6. The real offline challenge starts once. Its player opening hand plus remaining deck
   equal the chosen active 40-card multiset, player/public known cards show fronts, and
   only rival-private cards show the approved back.
7. The existing-save matrix covers starter-selected, printed, every partial
   opened/kept/pending boundary, all-kept, complete unmarked, and affected-0.8.7 data.
   Protected ownership, license/model, deck, Pre-Print, receipt, progression, RNG, and
   revision fields match before/after except for one explicitly accepted transaction.
8. The candidate passes editor/source regressions and an actual exported-content run.
   Those passes remain explicitly separate from physical Android acceptance.
9. A physical Android fresh install and no-data-clear in-place upgrade both complete
   the visible Founder/owned-front/Deck/bot path, stop/relaunch without crash or ANR,
   and retain portrait/no-ad/zero-bottom-reserve behavior. Without a device this row is
   blocked, never waived by desktop or static evidence; an exported-content-passing
   candidate may be staged only with explicit device-unverified review status.
10. Release delivery uses a new non-overwriting versioned APK and README. Local and
    DriveFS copies match bytes and SHA-256; confirmed cloud visibility remains a
    separately reported state. This document does not independently authorize staging
    or commit; it leaves Sol/root's standing reviewed-checkpoint authority intact.
