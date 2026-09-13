# Native Battle — active implementation

Collection is accepted and remotely verified at
`4a55da5e4cb109dcda72bb15cb3e2fc002aa3187`. See its final validation checkpoint;
the earlier UI-suite resource leak was a test-only unattached Control and is fixed.

The sole Terra writer is implementing
`team-prototype-native-battle-implementation-20260913.md` and its referenced exact
registration/14-case acceptance plan. Main owns tools, reviews and final commits;
Terra owns serial audited Godot runs until explicit handoff. No engine is running
under main ownership. Bounded subset passes are listed below; no full native Battle
acceptance, new default entry or APK is claimed.

## Primary early source review

These are existing contract details, not new product decisions. Verify them again
at freeze; preliminary files are not acceptance evidence:

- Cursor/Skip APIs take the existing canonical Run receipt request ID, never a new
  cursor/skip transaction ID.
- Terminal Skip must acknowledge only up to Result, with zero generic Skip calls.
  Continue alone acknowledges the visible terminal Result.
- A completed terminal current match remains `has_current=true`; use `resume` and
  `can_start` to distinguish Resume from New Battle.
- Provisional equipment needs a checked baseline without tactical fields to resolve
  legal default/explicit fabrication, then authoritative eligible target IDs. Do not
  require a target in order to discover targets.
- Clear/revalidate consumed local choices on accepted new revisions/new match;
  retain only the unaccepted same-revision draft. Receipt-read errors must halt
  presentation instead of leaving an old receipt/cursor running.
- Visual bay roots must use the same roster-record seating as their native owners,
  not a separately packed Ready list. Use registered active202.6/380 scale and
  audited idleA/B/windup roots, including native two-view Voltwig motion.
- Shared stage clock owns finite beat/progress/pause; per-frame passive visuals
  update existing nodes without Runtime.view/imageIO/tree reconstruction.
- The first presenter scaffold has manual NEXT STAGE and no finished fabrication
  pipeline; it is not the playable vertical slice. Automatic clock, Print/Awaken/
  Enter/Fit, attack, replacement and zero-event stage settlement are required.
- Use actual `V3Catalog.card(id)` art definitions. A fabricated id/name dictionary
  makes SupportCardView fall back to card backs. Equipment eligibility returns
  canonical String IDs, not dictionaries. Derive labels from projected members.
- Give each of the three roster records one seating owner; do not stack all Unspent
  hits on the single docket. Empty nonterminal Result is not a terminal Result UI.
  Render receipt.opening at cursor0 and preserve all registered normal/150 geometry.

Main added the new Battle controller compiled resource to the APK audit required
paths, plus the actual Battle presenter/visual filenames. Additional entry paths
will be confirmed after that separate batch. Primary verified the promoted BA-R1
runtime copy at2068110bytes and SHA
`F967088054521889012A5C63D989DE74EA71AB8AA4DB644709CD65918977EA99`, and quadruped
EQ-R1 at2482928bytes and SHA
`6C8DC945F0809E2B46E9A9C86274F4B3418BA84D932BCADB7E0D240AF458262C`.
They exactly match approved source masters; this is not rendered acceptance.
The standard DriveFS H: release directory is still mounted. Current latest Drive
APK remains0.8.11; do not relabel it as this new prototype. No ad identifiers were
found in the current scripts/scenes/project/export source scan (not an APK audit).

## Current bounded controller gate

Before more visual expansion, Terra is correcting the controller against real
Runtime/Store fixtures, not only the initial mock PASS. Required targeted tests:
target baseline clears all tactical fields; terminal-event detection distinguishes
the Result stage present in every receipt; Skip stops before terminal Result and
refreshes partial nonterminal cursor progress; cursor failure latches until explicit
Retry; reduced-motion Print keeps1.60seconds; a new match/Run/cursor identity resets
the clock even if its numeric cursor is unchanged. Cache stage metadata at that
boundary instead of deep-copying snapshots per frame. Designer is auditing exact
existing real-fixture recipes read-only. No native Battle visual pass is claimed.

## Verified foundation evidence, not Battle acceptance

Real Runtime/Store controller checks passed26 assertions in
`build/evidence/team-battle/20260913-032326-1b05c898cab54853906d10ebef7f0e05`.
Primary inspected the log and process ledger: PID140264, exit0,56.6seconds,
empty stderr, unchanged QA manifest, no surviving processes or windows. These
checks include the exact canonical Cinderpaw equipment target; accepted partial
cursor progress after interrupted Skip; failure latching across focus changes;
terminal Skip stopping before Result; and failed/retried Continue preserving the
actual wallet, reward record, and ledger bytes. The initial terminal setup helper's
false-positive success check was corrected before this evidence.

The suite is now split by `-BattleCase preflight|foundation|terminal` (default all),
forwarded to the test scene as `--native-battle-case`. Runner syntax passed. Future
additions must keep genuine persistence while staying under each60second run bound.
This does not prove all14 native interaction cases or a finished animation pipeline.

The later foundation-only run
`20260913-033345-f771ad4ae2f2472190866e49e422cb91` passed22 checks in4.6seconds,
PID155924, exit0, with unchanged QA manifest and no survivors. It additionally
covers reduced-motion Print duration/bands and a new Run identity clock reset.

Primary also flagged the Shell's failure-boundary feedback: failed automatic
acknowledgement returns changed=false, so the presenter must rebuild once on the
new error/pause boundary to expose Retry. A stage-boundary render must not feed the
old projection's visual a new stage, and per-frame visual lookup should be cached.

## Remaining delivery

### First native Plan capture — not approved

Primary inspected the actual first-session native Plan capture from
`20260913-034209-45ce1b201bdb4d39aeb174fc1a68c686` (PID146004, writer-reported
clean exit). Its low-contrast text and ornate duplicate Unspent controls are not
acceptable against registered styling. UI review is early feedback only; Enter,
attack and replacement presentation is still incomplete at this capture.

[Early native Battle Plan](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-034209-45ce1b201bdb4d39aeb174fc1a68c686/captures/battle-plan-576x1024.png>)

Primary viewed later controller-driven Print/Enter evidence from
`20260913-040238-314a54200d9341378b1498af2c5511df`. Partial raw printing and inward
facing are visible, but queue/stage text overlaps, active captions remain off their
registered centered owners, and the hand tray disappears during receipt playback.
These captures are **not visual acceptance**. The file named Print60 actually has
progress5000 in its metadata, so it is50percent; the next capture must assert6000.

- [Early Battle print at50percent (filename says60)](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-040238-314a54200d9341378b1498af2c5511df/captures/battle-print-60-576x1024.png>)
- [Early Battle entry movement](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-040238-314a54200d9341378b1498af2c5511df/captures/battle-enter-mid-576x1024.png>)

### Later native stage evidence

The later normal576 set `20260913-040945-7dbbe23564044626af4cf602ffe1e27c`
has six current controller-stage captures, now with asserted Print6000. Primary
verified its ledger: PID134264, exit0,8.5seconds, unchanged QA manifest, no failure
or process survivors. Queue text and disabled visible hand are improved; contact
still visibly crosses the rival HP caption and the queue wording calls pending
equipment "printing" during AttackLock. Read-only review is pending; this remains
partial native evidence, not full visual acceptance.

- [Corrected Battle print60](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-040945-7dbbe23564044626af4cf602ffe1e27c/captures/battle-print-60-576x1024.png>)
- [Early Battle contact frame](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-040945-7dbbe23564044626af4cf602ffe1e27c/captures/battle-attack-contact-576x1024.png>)

### Later finite attack and real input checks

`20260913-041953-4c126a61c4eb42d690bf232e1cc78038` passes29 foundation assertions,
including real Runtime native pointer actions for docket fabrication, hand selection
and Clear Plan, with unchanged ledger bytes on local selection. Other14-case native
acceptance requirements remain in progress;29 does not mean the whole matrix passed.

Primary verified capture `20260913-042227-0765ee5f590146d395687382cf7f528d`:
PID120084, exit0,8.4seconds, unchanged QA manifest, no survivors/failure. Its seven
images now span Queue, Print6000, Awaken, Enter, windup, Damage contact and return.
Attack is one phase across existing AttackLock/Damage durations, with prior
projected lock matched on beat and target. Captions are visually suppressed during
the brief paired beat while native damage feedback remains on the left summary.
Queued Suit is correctly named; final read-only closure is pending.

[Corrected finite Damage/contact](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-042227-0765ee5f590146d395687382cf7f528d/captures/battle-damage-contact-576x1024.png>)

### Equipment evidence and bounded terminal fixture setup

Read-only review closed the three normal-Cinder P1s in042227. This is only the
examined normal576 first-cycle subset, not the full Battle gate.

Primary inspected approved Suit Fit in
`20260913-042803-90454686af734dd8b69b16b54886350b`: PID146480, exit0, unchanged QA,
no failure/survivors. Suit appears only in the printer; no extra creature or pasted
costume. Remaining native feedback must expose projected armor/gem state after Fit.

[Native quadruped Suit fitting](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-042803-90454686af734dd8b69b16b54886350b/captures/battle-suit-fit-mid-576x1024.png>)

Terminal run042400 printed7 passing checks but took61.06seconds and the harness
correctly rejected its60second timeout. It is not accepted evidence. Main prepared
two separate real-engine invocations per outcome: `terminal-setup` completes
sequence1 through real Runtime/Store and closes; the selected terminal case copies
exactly profile/ledger/cursor primaries into a new isolated fixture, opens the real
Runtime and executes sequence2 seed0/14/44. Setup source bytes must stay unchanged.
No mocked persistence or edited authority may replace this fixture. Test-side setup
implementation is pending with the sole Terra writer; runner syntax passed.

The native runner also exposes bounded `interactions` and `playback` groups and
rejects zero-assertion/mismatched-case success. `ui-battle/all` serially invokes all
groups, with the separate setup for each outcome; do not run before every matching
test group is implemented. Main owns no engine; Terra retains serial run ownership.

### Primary correction of split-test report

The writer initially reported split Win as passed, but primary found043206 was
only its setup (3checks/PID156620). Selected case
`043235-f1613d66b1cf41fba5201bae7971328a` failed2 assertions plus a script error;
PID145452 was cleaned up. Do not count it as a terminal pass. The test helper failed
to normalize Windows handoff separators and then unconditionally rewrote the copied
profile when opening it. Terra is correcting those test-only seams, adding immediate
failure returns, exact outcome/reward checks, and unchanged setup-source checks.
No runtime Store or gameplay-schema change is authorized for this correction.

### Strengthened terminal and maintainability review

Primary verified selected Win evidence
`20260913-044429-3461d7bcd0394cd88e56b6e49ab01d13`:8 assertions, PID160148,
exit0,41.8seconds, unchanged QA manifest, no failure/windows/survivors. Setup was
`20260913-044353-1a812c492eb645188d6f7f13b0bfbf41`. The selected case now checks
the requested exact Win30coins/40XP, settled reward/ledger/wallet stability around
Skip and failed/successful Continue, `can_start` boundary, and byte-identical source
primaries. Primary also verified strengthened Loss
`20260913-044624-8dda8f1f3a9d43f99eaef42c223e1719` (PID136024,8 assertions,
41.8seconds) and Draw `20260913-044823-630384a0d88c49a4aa838bb0ba375cd9`
(PID122604,8 assertions,42.8seconds). Both selected cases exit0, no failure or
survivors, QA bytes unchanged. Draw setup is
`20260913-044752-4af2e1996a1341a88e5270cf33fc82bf`. Win/Loss/Draw cursor/reward
invariants pass; actual native Result control/large-text coverage is still open.

Read-only UI review accepted normal576 Suit Fit in
`20260913-043318-d5bb5b3a95eb47fea668e7d4aa7587f7`: native27HP/Armor8, truthful
Fit/empty-head feedback, no pasted costume and no P0/P1 in that bounded image.

Primary source review requires a shared priority-aware seating helper for visual,
controls and previous roots; registered150percent geometry/ink/short card labels;
accessible HP retained while attack captions are visually suppressed; and event/
texture configuration cached at stage boundaries with one pose-update owner.
Ambiguous attack-pair context must fail rooted rather than choose a duplicate lock.
These are corrections within the accepted design, not new gameplay.

Native interaction source review also found that generic modal Back currently clears
only Shell's unrelated support field, not the Battle controller's provisional gear
selection, and the gear picker does not register return focus or lock underlying
keyboard focus. Correct these through a common cancellation path and exercise real
Back/Cancel/target/retap pointer actions. Failed Run copy must describe the preserved
save boundary and Retry, not incorrectly say the Plan changed.

Audited runner now forwards validated `-BattleCreature` as `--battle-creature` for
native captures, default Cinderpaw. Test-side all-four first-print fixture support
remains with Terra. PowerShell syntax passed; no capture pass is implied by tooling.

Shared seating/cache slice passed primary log review: foundation
`20260913-045757-152cdfc1519f48b1bfd106532a0303cf`,32 assertions/PID124768;
playback `20260913-045741-c81f502d9ce04b5896ae0e0564263387`,10 assertions/PID150580.
Both exit0, no failure/survivors and unchanged QA manifest. This playback group is
only seating/cache coverage so far, not full lifecycle. The idle test still needs
an actual Atlas region transition assertion rather than elapsed time alone.
Next slice is native input/large-text registration; Ready captions are now precisely
recorded beneath living minis in the amended interaction registration.

Designer confirmed receipt-rail correction: while resolving, display only Filament
from the current displayed opening/stage projection plus current event feedback.
Do not call checked Plan on final authority or show its future Spend/After/Next.
Restore all four checked forecast rows at editable Plan. This changes presentation
only, with no new save field, forecast API or rule. Source-derived real Runtime
Gem/Ready/Swap/Defeat/Replace/HOLD fixture guidance is being recorded separately.

Runner also has bounded `-BattleCaptureCase result` for later actual Win Result
captures: genuine sequence-one setup followed by rendered sequence two in a fresh
three-primary fixture. It is not yet capture-side implemented or accepted. Each
Godot operation keeps its existing60second bound.

### Native large-text capture review in progress

Primary verified normal `20260913-050642-f050e6f3fa6e40fc861fae114662039b`
(PID142252) and150 `20260913-050831-5fa5a227ae05499b916c12b6402a505b`
(PID64192): clean exits, no failure/survivors, unchanged QA. Nine lifecycle images
each do not yet cover Preflight/modal/Ready/Result. Primary viewed150 Queue and
found the long rival-hand count wrapping behind backs and short card pairs needing
their deliberate two-line layout. Full read-only review is pending; not accepted.

[Early native150 Queue review](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-050831-5fa5a227ae05499b916c12b6402a505b/captures/battle-queue-576x1024.png>)

Read-only review rejected that150 set for rival count/docket/title overflow and
token/card/active-caption density. Primary accepted those corrections and recorded
the extra faithful large-copy owners in the registration. Reviewer request to show
four forecast rows during receipts was declined in favor of the designer's explicit
F4 current-snapshot-only rail; four checked rows remain required at editable Plan.

Primary verified interactions `20260913-051510-c4954ad17ac64c5c89a53d4f76f1a3e2`
(13 assertions/PID148828) and foundation
`20260913-050901-e3b4317c5ba242d081aac76a9fbbffca` (32/PID24044), clean exits,
no failure/survivors, unchanged QA. The13-check interaction subset still uses a
direct Back method and emitted target signal; replace those with actual native
input, verify source focus and Cancel/underlying-focus lock, and finish Start/Run
failure/Result control coverage before full acceptance.

### Corrected large-copy closure, one caption issue remains

Primary verified interactions `20260913-052427-9a645d0781ec4ff0a34f197ffc84c6b3`
(13/PID124424), foundation `20260913-052513-2b4aa1ae0f01432b96cdbce99d30c6d5`
(32/PID129532), normal capture `20260913-052228-823c9b82e9df47509e18b093979b1054`
(PID138472) and150 capture `20260913-052444-f3a7a976b16c46129623d3d86571d73e`
(PID119456). All exit0, no failure/survivors, unchanged QA. Source now dispatches
Escape and real target pointer input, verifies returned source focus and NEXT copy.
Separate Cancel/focus-lock/Start/Run/Result input requirements are still pending.

UI reviewer closed all prior rival-count/docket/token/card/FIT-title findings and
accepted F4 receipt-only Filament. One P1 remains: large active-caption line advance
pushes its second line across the floor edge. Keep exact owners,39px font and
42.48-design-pixel line advance using actual font metrics; center and contain both
lines. Reuse that bounded typography for large Ready captions to avoid the same
overflow in later Ready evidence. No geometry move or font-scale reduction.

Next bounded writer slice owns real Start/Run fault inputs, persistent native
selection rings, Preflight/Result typography and actual pending Win Result captures
through the prepared split runner. Full lifecycle/all-four/tall capture and new
default entry/export remain downstream. No new native Battle commit yet.

### Delivery still outstanding

After Battle acceptance: normal-entry quiet/read-only startup with all fixture
boundaries,0.9.0/code108 Android identity, commit/push, signed arm64 export, independent
package audit, non-overwriting APK/README DriveFS copy with byte/SHA match. No physical
Android device is available; an SDK emulator binary is also not installed. Keep
cloud synchronization separate from verified local DriveFS staging.

### Start/Run and actual Win Result input evidence

Primary reviewed actual pointer Start/Run fault tests and Result Continue/Back/Resume/
Retry source. `20260913-053839-4abb16acc2b94f2399e69e67c0a0a9ac` passed28 interaction
assertions, PID89420. Real Win selected case
`20260913-054113-fd9f53414ec94e618a7edfbf165a0732` passed12 assertions, PID149020;
its expanded native Result checks retain the original settled wallet/ledger guards.
Both exact-case markers, exit0, no failure/survivors and unchanged QA are verified.
The duplicate Run controller guard is separately exercised in foundation; the
pointer test must not claim a second tap if its physical owner has been removed.

Genuine pending Win Result capture
`20260913-054613-ce7eee94f9e241ffa712b38375f18e3d` passed, PID122144, exit0, no
failure/survivors and unchanged QA. It copies the three real prepared primaries and
plays sequence two through Runtime; the normal visual review is pending. Earlier
054336/054436 capture errors are preserved failed evidence, not acceptance.

[Actual pending Win Result, normal text](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-054613-ce7eee94f9e241ffa712b38375f18e3d/captures/battle-result-pending-576x1024.png>)

Primary controller/seating review found no new rules or save authority changes:
receipt caches update at canonical cursor identity boundaries, both lifecycle and
write-failure pause latches remain separate, and one shared priority projection
drives current/prior visual roots and native controls. Main requested exact39px
large Result typography through its helper before final visual capture.

The audited runner now separates `-BattleCase progression` and `hold`, and matching
`-BattleCaptureCase progression` and `hold`, to keep genuine F1/F2 and F3 operations
individually bounded at60seconds. These new script-side cases are not implemented
or passed yet. PowerShell parsing passed; no engine was launched by this change.

### Bounded visual closure before final lifecycle matrix

Normal Win Result054613 and150 Win Result054807 passed read-only BA-05 review with
noP0/P1. Final helper refresh150 Result
`20260913-055206-8bc04b836bfd4d0ea5e544c7d7ae36d1` is clean, PID137736. Native
interactions final rerun `20260913-055112-1d707d9846364281a1e8c141b782b8a8`
passed28, PID133052. Main verified exit0/no failure or survivors/unchanged QA.

The sole150 active-caption P1 is closed by the reviewer against
`20260913-055259-c708215175944a4c851e73a67e2f1676`, PID161440, clean verified
evidence. Both lines now fit their registered owners above the floor edge. A
companion-only stage incorrectly called FIT is a separate narrow copy fix: the
registration now specifies event-aware ENTER/FIT titles. No new art or layout shift.

Writer now owns the final all-four lifecycle, native Plan/modal/Ready/Swap/Gem,
Defeat/replacement and HOLD coverage. Existing real Win/Loss/Draw outcomes and
accepted longest-Win Result geometry do not require a redundant three-outcome
visual matrix. Source entry/default Android build remains downstream.

### Final lifecycle work in progress

Aquafin native lifecycle `20260913-055707-f2742b70e893493c852379973823d699`
passed, PID122660, and read-only review accepted its raw Print, first-living Awaken,
rear-facing Enter/contact/return, alpha and grounding with noP0/P1. Print JSON names
the actual `player:member:aquafin` subject; the field is intentionally print-only.
Foundation `20260913-055836-0cdea64125534d0f9010013ae9f74ff6` passed39,
PID134744. Primary verified both exact markers, exit0/no survivors/unchanged QA.

F1 Runtime/controller progression `20260913-060344-7991a4f45f4b41a8b71a92cd880671a2`
passed18, PID129244. This proves genuine Gem Fit/Ready/swap decisions, not yet the
native Swap owner or every transition pose. Primary requested exact pre/post HP
equality and explicit absence of early Gem Fit, rather than weaker positive-HP and
queued-event assertions. The active final slice adds F2 and native visual controls.

F3 genuine low-filament HOLD `20260913-060557-d4841aea3e114186a5f661e445da5a4a`
passed4, PID156016, exit0/no failure or survivors/unchanged QA. Primary caught the
earlier test recipe missing its required equipment target and distinguished a
rival-only empty-field HOLD from the requested player low-filament boundary. No
runtime authority was edited to reach the fixture. Native HOLD visual proof remains
part of the final slice. Failed060419/060717 are not acceptance.

Primary found missing Swap animation handling in the passive visual. Writer is
adding previous-root interpolation for both canonical incoming/outgoing figures,
with grounded reduced motion and one figure/shadow per identity. Designer supplied
short native Swap/Defeat feedback; large Swap uses four contained name/status lines
and full two-seat accessibility. This is a scoped animation/feedback correction,
not a new mechanic or layout.

Real preflight/editable Plan/equipment-target surfaces are now captured in
`20260913-061152-65281e4d58014a9eb3224541cbca2465`, PID151340, exit0/no failure or
survivors/unchanged QA. Main viewed the opening Plan; read-only review of these
three new surfaces is pending. This is no longer the old Main/printer-health scene.

[Current native opening Plan](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-061152-65281e4d58014a9eb3224541cbca2465/captures/battle-opening-plan-576x1024.png>)

### All-four normal creature gate closed

Fresh normal576 Aqua061235-f73c13f1b0034930815b0ebbe0704e8b (PID122808),
Volt061258-9a456acf185441ceaab51056907079a8 (PID157604), and
Moss061320-71721dae1f42403d9bfd5819576e145c (PID153780) have verified exit0,
no failure/survivors and unchanged QA. They live beneath the same
`build/evidence/team-battle/20260913-` prefix as earlier evidence.

UI review accepted Voltwig and Mossmunk with no creature-specificP0/P1: neutral
partial prints, first living reveal at Awaken, inward-facing figures, intact ears/
tail/feet, clean alpha, planted roots. Together with Cinderpaw/Aquafin the normal
four-companion direction/print-transition gate is closed. Voltwig's legitimate
sequence1/seed2 Start produces BOTH `player:member:voltwig` and
`rival:member:voltwig` in actual Print metadata, not a reflected side-view substitute.

[Current Voltwig front/rear pair in battle](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-061258-9a456acf185441ceaab51056907079a8/captures/battle-suit-fit-mid-576x1024.png>)

New-surface review is not yet accepted: Preflight lever and target-sheet heading
need light native ink on their dark owners (P0); Cancel needs its generated binding
material/focus ring; docket labels belong as transparent ink on the painted paper,
not opaque panels over the printer. Exact large rival docket coordinates are being
resolved with the reviewer. Primary also found normal Active caption line advance
spilling at the lower floor edge; apply the same metric-based containment already
accepted at150, with normal27/26, without changing owners. These scoped corrections
do not reopen the approved four creature assets or authorize a redesign.

### Contrast and portrait geometry closure

Read-only UI review closed the Preflight lever, equipment heading/Cancel/focus,
transparent paper dockets, and normal/150 Active captions against normal
`20260913-062148-3db528272b124e86977a37f69458a37c` (PID10760) and150
`20260913-062210-1965a0df9fe44fce83fc623574e9382e` (PID142400). Voltwig720x1280
with synthetic safe insets `20260913-062233-40589b6aa0604972b48744465d51f4d5`
(PID130496) also passed. The tiny large default-print summary is now three lines:
Print Next / canonical name / Auto. No further art generation was required.

Main verified current foundation39 (`062125-d625205fe62145e4ae56cdfe5b16d8a4`,
PID159252), interactions28 (`063055-d3df7241d2934d4293fe0f3bff7484e4`, PID147224),
and progression25 (`062436-80b2436ac0ba41e1a6aad22e677d3e08`, PID101968). All share
the `build/evidence/team-battle/20260913-` prefix and have exact selected-case
markers, exit0, empty stderr, no survivors, and unchanged isolated QA fixture bytes.
Progression now includes real Ready-swap pointer/ring/tactical-exclusion checks,
exact preserved HP/Gem identity, and real Defeat/Replace authority.

New real F1/F2 captures `062743-ed2e438d6bb44dde916792ebf11c0c1c` (PID152280),
HOLD `062818-cc41d0f6af2a4e10b1ba55fa7504fd3f` (PID154372), and tall720x1600 with
150%/high-contrast/reduced-motion/insets `062924-5df1dec7c352416b8285259c1add3277`
(PID156380) are engine-clean and pending targeted visual review. Writer honestly
flagged Swap midpoint caption crowding rather than claiming a visual pass.
Main is adding an exact selected-capture-case/nonzero-saved-frame gate with the
writer; generic success alone must not allow a wrong capture case to pass.

The designer's final source audit found no release-blocking deviation from the
approved3/15 Team-defeat contract: no printer-health target, manual stage-stack,
second tactical choice, fabricated ownership, or reward replay. The deterministic
bot and bounded prototype catalog are accepted scope, not a new Market/upgrade
milestone. This is design acceptance only; native visual and Android gates remain.

Maintainability review retained the separate controller/presenter/passive visual
and shared Seating projection. Receipt/view copies are boundary-owned; passive
animation does not perform Runtime, file, or JSON reads each frame. Shared print
shadow geometry is optional with its old default preserved. No Rules or save-schema
change is part of this Battle UI slice. Runtime tests remain explicitly injected;
the next dedicated Entry subclass will own normal application startup.

### Final review corrections; invalid dimension evidence withdrawn

UI review found that Battle capture configured only Shell size, not the actual
Window/content viewport. The062233 supposedly720x1280 and062924 supposedly720x1600
PNGs were physically576x1024. Their dimension/safe-area acceptance is **withdrawn**;
they are not Android/tall geometry evidence. Their recorded engine success alone
does not fix that defect. Correct the driver and assert actual Image dimensions
before every save, then recapture real720 variants. Collection capture already sets
Window and content-scale size and is checked independently, not presumed invalid.

The normal Swap midpoint is also rejected: destination captions name creatures
still at their origins; final role scales appear at q0 and straight paths collide.
Use true prior/current scale/root interpolation, stagger outgoing/incoming travel
within the existing.60second stage, and suppress moving static labels. A claimed
Replace ghost requires canonical seat/identity/snapshot diagnosis, not hiding a
legitimate living opposing creature. The native150 forecast rows must use the
registered42.48 advance and summaryy709.02 rather than compressed normal rows.

Primary resolved a reviewer units correction directly against approved atlas CSS:
Active202.60 width remains; Ready86.60 normal/61.26 large are design dimensions.
The current runtime114-wide Ready was an implementation mismatch, not authority.
Gem Fit and bilateral HOLD semantics passed. No engine/build failure is concealed.

[Rejected Swap midpoint showing the exact crowding](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-062743-ed2e438d6bb44dde916792ebf11c0c1c/captures/battle-swap-mid-576x1024.png>)

Primary independently read PNG IHDR bytes: Collection024113/024147 captures are
actually720x1280/720x1600, so their earlier dimensions remain valid. Battle062233/
062924 are actually576x1024 and remain rejected. Reviewer accepted the atlas-based
Ready width correction and withdrew the unproven same-species Replace ghost claim;
canonical identity, not species appearance alone, decides whether a figure is stale.

True720x1280 normal `20260913-064643-3db7b5302fff40bd863b4e60a504f930`
(PID153376) now passes pixel-size assertion, exact12-frame capture marker, clean
engine/QA/process ledger and UI review. It has zero synthetic insets; no inset
claim is made. Interactions `20260913-064941-9f53aa36f919445eaa7f52ed0b0dd29a`
(PID122128) passes32, including real five-Support face owners and checked Heated
filament cap. A mistaken Full Suit test used its internal ID as visible copy; its
failed evidence remains retained rather than changing correct player-facing text.

True tall progression `20260913-065037-1fe717dedceb4a82a2060d044f284435`
exposed a new metric error and is rejected. Main found the exact cause: the new
forecast code passed final39px into a helper that applies150%, yielding59px. Use
base26 or explicit final39/42.48 metrics. Hand two-line labels require the same
final metric containment; long Replace/HOLD/Fit feedback needs bounded native
copy plus complete accessibility text. Main also found capture insets set after
Shell's ready-time fit; set them before mounting or explicitly refit. Actual PNG
dimensions alone are not evidence that synthetic insets were applied.

[Rejected tall Swap exposing double text scaling](<E:/AI Projects/games/3d print battler/build/evidence/team-battle/20260913-065037-1fe717dedceb4a82a2060d044f284435/captures/battle-swap-mid-720x1600.png>)

Progression `20260913-065559-6aa1fbaf687645dcbd07c675fd2b2f6e` (PID73884)
passes26 including both Swap identities visible at0/50/100%, proper incoming/outgoing
size endpoints, and separated shadow lanes. Main rejected a transient implementation
that hid both figures mid-Swap; it was removed. Final source interpolates Replace
Ready-to-Active root, scale, and continuous shadow too. The initial ghost claim was
not used to hide a valid living figure or modify the Rules snapshot.

Corrected tall progression `20260913-065628-6f8fb28163f54b1f8b96cb3c3698d61e`
(PID137060) saves6 true720x1600 frames after base26-to39 metrics and an actual fit
after synthetic inset configuration. Main verified exact markers, exit0, empty
stderr, no survivors and unchanged QA bytes for both roots. Targeted visual review
and a final tall lifecycle/Plan/modal capture remain pending.

### Final visual closure

Read-only UI review accepted final normal progression
`20260913-070847-903924ef30714fea9336a4e1d7f7edc8` (PID139776) and final tall
lifecycle `20260913-070926-115af4d026c74714bd9fd9861829a488` (PID137000).
Ready-to-Active replacement now keeps the correct scale throughout. Large-text
canonical paper names clear Back and contain no orphan ordinal. There are no
remaining P0/P1 findings in the assigned Battle matrix. This closes desktop visual
review, not physical Android validation. See the final validation checkpoint.
