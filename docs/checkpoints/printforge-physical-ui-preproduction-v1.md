# PrintForge physical UI preproduction checkpoint v1

Status: preproduction gate approved; bounded runtime milestone work may begin under the screen-first production loop

Date: 2026-08-30

Branch at preparation: spike/printforge-physical-ui

## Human direction and approval record

- The user selected concept direction 3, retained PrintForge, required a Workshop rather than engine room, and asked for physical clickable objects instead of generic buttons.
- The user required a full generated-screen workflow, new icon, and title before code/build work.
- The user selected portrait-only production.
- The user corrected battle direction so creatures print on the battlefield, awaken, and join as animated living-print sprites.
- Characters remain whimsical animal prints or fantasy creatures; no mechs or humans.
- The user accepted the coherent printer/hand/three-slot battlefield layout after iteration and requested implementation until playable.
- The user explicitly requested simplification away from manually advancing trading-card phases. The accepted player-facing loop is Plan then Run Cycle while all five deterministic phases remain internal.
- The latest instruction, “go ahead and carve out space at the bottom for admob too”, explicitly supersedes the earlier no-AdMob instruction.
- That latest instruction authorizes bottom AdMob review integration and layout validation. It does not authorize production identifiers, rewarded-ad gameplay, or ad-gated progression.

Approval result: full portrait atlas APPROVED; simplified Plan → Run Cycle APPROVED; portrait-only APPROVED; bottom AdMob review space APPROVED.

Supersession record (2026-08-31): the later active M5 goal explicitly returns
PrintForge to a completely no-AdMob delivery. The approval bullets and AdMob review
sections below are preserved as history, but their banner authorization, native
integration gate, review identifiers, and reserved-region validation are superseded
by `docs/checkpoints/printforge-physical-ui-m5-no-ad-delivery-v1.md`. Current delivery
authority permits no AdMob SDK/plugin/identifier/permission/metadata/request path and
no reserved ad strip; M1–M3 gameplay and portrait UI authority otherwise remains
unchanged.

## Approved atlas authority

Tracked masters in docs/art/printforge-physical-ui-spike-20260830 are composition targets. Every portrait master is 941x1672 and icon masters are 1254x1254. Untracked older versions, rejected variants, and landscape experiments are not approval targets.

Brand: branding-title-screen-v1.png, branding-app-icon-v1.png, branding-adaptive-icon-background-v1.png, branding-adaptive-icon-foreground-v2.png.
Onboarding/Workshop: OB-01-first-workshop-arrival-v1.png, OB-02-starter-gallery-v2.png, OB-03-starter-inspection-v1.png, OB-04-first-print-setup-v2.png, WS-01-workshop-home-v2.png, WS-02-collection-focus-transition-v1.png, 03-workshop-maker-dashboard.png.
Forge: PR-01-blueprint-selection-v1.png, PR-02-print-review-v2.png, PR-03-active-print-early-v2.png, PR-04-active-print-60-v2.png, PR-05-raw-print-complete-v2.png, PR-06-awakening-receipt-v2.png.
Battle: BA-01-challenge-board-v1.png, BA-02-battle-preflight-v2.png, BA-03-main-plan-v3.png, BA-04a-print-animation-v2.png, BA-04a2-awaken-step-off-v2.png, BA-04b-attack-animation-v2.png, BA-05-battle-result-v3.png, BA-06-card-selected-print-slot-v2.png, BA-07-printing-in-player-printer-v2.png, BA-08-awaken-deploy-to-field-v2.png, BA-09-living-print-joined-v2.png, BA-10-auto-attack-printed-sprites-v2.png.
Remaining: CO-01-collection-archive-v3.png, CO-02-creature-blueprint-detail-v2.png, CO-03-card-detail-filter-v2.png, DK-01-deck-workbench-v1.png, DK-02-preprint-selection-v1.png, DK-03-invalid-empty-deck-v1.png, MK-01-supply-cabinet-v1.png, MK-02-printer-maintenance-v1.png, RW-01-pack-counter-v1.png, RW-02-pack-opening-v2.png, RW-03-reward-level-up-v1.png, ST-01-settings-accessibility-v2.png, ST-02-accessibility-preview-v1.png, SY-01-state-sheet-v1.png, SY-02-save-recovery-v1.png.

## Screen-first build contract

Generated masters establish composition/material/hierarchy/mood only. Dynamic names, values, buttons, statuses, counts, filters, errors, focus and accessibility remain native Godot. Reuse exact existing creatures/sprite sheets/card back where viable. Runtime battlefield creatures use one animated sprite per unit. Generated placeholder creatures/baked labels are never promoted. Missing art requires a text-free reviewer brief, original master, provenance and approval. Hotspots/cards are accessible native targets at least 48x48 logical. Designer/reviewer never edit runtime.

## Route acceptance matrix

- Title/resume: native text; disabled no-save Continue; recovery; no destructive overwrite.
- Starter: all three; carousel/inspector; separate Inspect/Confirm; 150% text.
- First print: setup/early/60%/raw/awakening/failure; empty bed first; exactly one model/debit/revision.
- Workshop: printer, battle, archive, deck, supplies and settings accessible.
- Routine Forge: persistent stage; no early finished creature; no invented filament inventory.
- Preflight: 40 owned legal cards, legal preprints, rival privacy.
- Battle Plan: hands/printers/HP/filament/fields/queues; three slots each; no phase toolbar; Run Cycle reachable.
- Print/deploy: select/queue/printer/awaken/mode-slot/joined; FIFO head only; one living sprite; pending cannot skip.
- Attack: focus and fallback; slot-order deterministic; finite animation; no duplicate.
- Result: exactly-once result/reward.
- Collection: folio/filters/inspectors; truthful BEND/HP/support/ownership/license/model.
- Deck/preprint: valid, empty preprint, fourth creature, invalid deck; init once; all legal creatures; legal save only.
- Market: current/unavailable/insufficient; catalog values; preview zero-mutation.
- Reward: packs 1–3/pending reload/exhausted; five each; normal pity; no fourth mutation.
- Settings/recovery: 150%/contrast/reduced motion/saves; no clipping or implicit 0.7 migration.
- AdMob: Android load/failure/resize/safe inset and synthetic desktop; native owns creative/inset, production reserve zero, no blank band/coverage.

## Battle simplification checkpoint

Draw, Main, Print, Attack, Collect remain exact internal phases. Coordinator submits routine advances using existing intents. Plan exposes existing Main choices contextually. Run Cycle orchestrates existing phase/placement/attachment/discard/attack intents. Attacks resolve friendly slots 0,1,2; legal optional focus wins, otherwise lowest occupied rival slot, printer only if all rival slots empty. Events animate sequentially. Reduced motion changes presentation only. Placement/attachment/overflow pause and own focus. Skip only finishes presentation. Rejections preserve exact state; each success increments revision once.

## AdMob review checkpoint

Authorization covers a native Android bottom banner in review builds. Native Android places it outside Godot, owns creative height and navigation/gesture inset; Godot production reserve=0 and receives resized usable surface. No duplicate Ad label. Native measurement is diagnostic only. Review uses Google test app/unit configuration; production IDs unset; no rewarded ads/progression/analytics secrets. Preserve labeled positive synthetic overlay fixture. Test load, failure/no-fill, plugin unavailable, resize and safe-inset change. Require real portrait Android screenshot proving no blank band/covered hand/Run Cycle/modal/toast/accessibility target. Ad state affects no RNG, battle/Forge time, revision, currency, reward or input.

## Milestones and agent gates

M0 preproduction: designer Markdown, read-only UI review no P0, user atlas/portrait/loop/AdMob approval. Gate satisfied once these docs are applied.
M1: portrait shell, title, starter/first-print entry, Workshop, native ad boundary production reserve zero plus synthetic fixture, native text/focus/touch/150%/contrast/reduced motion. Writer captures 576x1024, 720x1280, tall synthetic; UI reviewer no P0; Sol audits architecture/node churn/textures/rebuild/safe-area/tests; Terra corrects/refactors; Sol commits.
M2: challenge/preflight/Plan/Run Cycle/printers/hands/queues/six anchors/sprite print-awaken-deploy-idle-attack-hit-defeat/context decisions/rival privacy/bounded AI. Preserve five-phase tests; capture states; reviewer; Sol audit/refactor; regression; commit.
M3: routine Forge, Collection, Deck/preprint, Market, rewards, result, settings, recovery; restore UI zero-mutation/exactly-once/failure/reward/deck/inspector tests; captures/reviewer/Sol audit/refactor/regression/commit.
M4: supported Android AdMob test integration under native-bottom contract; portrait arm64 review APK with production IDs unset; package/version/sign/launch/animations/save/banner load+failure checks; real device screenshot; reviewer; final audit; commit; commit-qualified non-overwriting APK/README to Drive; size/SHA match; cloud sync separately confirmed or pending.

## Current gate state

Design content PASS. Tracked full atlas PASS. Original master dimensions PASS. User atlas, loop, portrait, and bottom AdMob review-space approvals PASS. M1 R10 runtime and visual correction gate PASS under `docs/checkpoints/printforge-physical-ui-m1-corrections-v1.md`; its focused Godot 4.7.1 tests exited 0 and read-only UI review found no P0/P1. M2 is authorized under the screen-first production workflow. Accepted P2 polish remains tracked without reopening M1. Baseline environment warnings mean the run is not claimed stderr-clean. Real-device/native AdMob validation, Android build, and Drive delivery remain PENDING M4; production IDs are intentionally UNSET.
