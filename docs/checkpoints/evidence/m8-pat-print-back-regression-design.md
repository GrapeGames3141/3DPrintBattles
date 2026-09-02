# M8 Pat print/back regression design checkpoint

Status: decision-complete acceptance contract; implementation evidence ready for
read-only UI review; Android/device/export/Drive evidence pending

Date: 2026-09-01

Authority: committed M1-M7 gameplay/UI/save contracts, Pat's current print/back
feedback, the approved v2 blueprint family, and current route semantics. This M8
checkpoint changes presentation/navigation orchestration only.

## Locked boundaries and supersession

- No catalog, combat value, ownership, legal-deck, three Pre-Print, print cost,
  reward, economy, profile, or save-schema change.
- Existing exactly-once transactions and print, awaken, attack, and result animations
  remain finite and authoritative. Battle remains Plan -> Run Cycle.
- Portrait only; native dynamic text/accessibility; 48/56-logical-pixel targets; 150%
  text, high contrast, reduced motion, and safe-area behavior remain required.
- No AdMob SDK/path/identifier/permission/metadata/creative/placeholder or reserved
  strip. Production bottom reserve remains `0`.
- This checkpoint supersedes the earlier active-print visual allowance that showed
  the entire unprinted upper creature as wireframe. Blueprint remains the pre-print
  identity and wireframe remains an extrusion cue, but the printer stage may show
  only a narrow local preview immediately above the scan line. No complete creature
  silhouette may appear on the bed before completion.

## Contract 1: progressive First Print reveal

- **Entry:** A valid starter has been committed exactly once and First Print opens
  before any print job is accepted, or an accepted print job is restored at its
  authoritative progress/generation.
- **Player decision:** Review the docked blueprint, start the existing print
  transaction, watch/skip presentation where already legal, or use the caller-safe
  Back contract below. The player never chooses reveal geometry or a new print value.
- **Result:** Before start, the printer bed contains no creature body: only a small
  blueprint/wireframe footprint seed at the build plane may appear. During progress
  `0 < p < 100`, solid/raw fused-filament pixels exist strictly below the scan line.
  Wireframe/layer preview may exist only in one contiguous band immediately above the
  scan line whose height is no more than 8% of the creature's printable vertical
  bounds. All creature pixels above that band are transparent. The stage therefore
  reveals the creature incrementally and never shows a complete solid, raw,
  wireframe, outline, shadow, glow, or animated silhouette before completion. At
  authoritative 100%, the final layer may complete the raw form; only then may the
  existing finite raw-hold -> awaken -> animated-creature sequence begin.
- **Failure:** A finished/raw/animated creature at start; any full-height wireframe;
  solid pixel on or above the scan line; preview detached from the scan band or taller
  than 8%; full silhouette before 100%; early field duplicate; scan/reveal mismatch;
  skipped completion transaction; or nonfinite awaken keeps the regression open.
  Missing art shows a recoverable native error and never substitutes a finished
  creature or grants twice.
- **Disabled:** Start remains disabled until existing prerequisites pass. Completion/
  claim/awaken remains disabled before authoritative 100%. The full docked blueprint
  reference may remain visible on its separate cartridge/paper surface, but it cannot
  be projected as a full figure onto the bed.
- **Feedback:** Native progress, material/layer state, one scan line, local preview,
  physical instrument plates, and Back state remain readable at 100%/150%, high
  contrast, and reduced motion. Reduced motion uses the same progressive masks as
  held frames; it cannot jump visually to a complete creature before completion.
- **Progression:** Pre-start inspect/Back and presentation frames are zero-mutation.
  Starting, completing, granting, and saving remain their existing exactly-once
  transactions. Presentation retry resumes the same job/generation and cannot replay
  a grant.

### Deterministic print acceptance

`test_m8_progressive_first_print_reveal` evaluates progress `0`, `1`, `25`, `60`,
`99`, raw-complete, awaken, and animated-departure fixtures. For every `p < 100`, it
asserts:

- no connected creature mask spans the complete canonical printable bounds;
- `solid_alpha == 0` at and above the scan line;
- `wireframe_alpha == 0` above `scan_line + 8% printable_height`;
- any preview pixels form one scan-adjacent band, not a detached upper body;
- no raw-complete or animated field node/semantic state exists; and
- profile revision, owned/printed count, receipt count, and job generation change
  only at their authoritative transaction boundaries.

The fixture compares normal/reduced-motion masks at the same progress and repeats
route exit/re-entry to prove persistence without duplicate callbacks.

| Capture ID | State | Required sizes/mode |
| --- | --- | --- |
| `M8-PR-01-EmptyBedSeed` | Pre-start bed with only local footprint seed; docked blueprint separate | 576x1024, 720x1280 |
| `M8-PR-02-Progress25` | Partial solid below scan; narrow preview only | 576x1024, 720x1280 |
| `M8-PR-03-Progress60` | No complete upper silhouette; strict clip/band | 576x1024, 720x1280 |
| `M8-PR-04-Progress99` | Final top remains unrevealed before accepted completion | 576x1024, 720x1280 |
| `M8-PR-05-RawComplete` | First frame where complete raw form is legal | 576x1024, 720x1280 |
| `M8-PR-06-Awaken` | Finite transition to existing animated creature | 576x1024, 720x1280 |
| `M8-PR-07-Reduced60` | Same 60% semantic mask without sweep | 720x1280 reduced motion |

Original-resolution review fails if the stage can be read as a complete creature in
any pre-completion capture, regardless of whether that figure is solid or wireframe.

## Contract 2: caller-safe visible and Android Back

- **Entry:** A route or modal below displays a visible Back control, or Android emits
  system Back while that same state is foremost. The route stores its explicit caller
  and any local draft/transaction generation before presentation.
- **Player decision:** Activate visible Back or Android system Back once. When a dirty
  draft requires a decision, choose Save, Discard, or Stay through the existing
  confirmation; no implicit choice is made.
- **Result:** One central Back dispatcher dismisses the foremost route-owned
  inspector/confirmation first, otherwise returns to the exact prior route in the
  table. Archive detail state is dismissible only while Archive owns the foreground;
  an Archive detail retained as a Forge caller cannot absorb the first Forge Back.
  The Deck card/Pre-Print inspector is persistent workbench focus, not modal depth,
  and therefore never consumes Back before the clean/dirty workbench exit. The
  visible and Android actions produce byte-equivalent route, draft, job, profile,
  focus-return, and callback-count results. Back never exits to an OS/root surface
  while an in-game prior route exists.
- **Failure:** Dead Back, raw `screen = workshop` fallback, wrong/root route, state
  loss, unrequested draft discard, accepted-job cancellation, result rollback,
  duplicate callback/transition, transaction/revision mutation, stale timer action,
  focus loss, or visible/system mismatch keeps the regression open. A persistence or
  route failure leaves the current state visible with a native reason.
- **Disabled:** Back is disabled only while an exactly-once transaction is in its
  noninterruptible commit window. The visible control and Android Back share that
  disabled state/reason. In particular, an in-flight Market purchase cannot be
  cancelled or visually dismissed by Android Back while its visible Cancel action is
  locked. Background routes and controls cannot receive input through an inspector/
  confirmation.
- **Feedback:** Every visible Back has a native destination/cancellation label,
  accessible name, >=48x48 logical target, four-edge focus, and immediate finite
  physical pressed/dismissal feedback. Dirty and in-flight states show the exact
  consequence before mutation.
- **Progression:** Inspector/modal dismissal and clean route return are zero-mutation.
  Save applies once only after explicit Save; Discard abandons local draft only;
  active printing continues the same accepted job; committed battle results remain
  committed.

### Explicit route-back table

These stable row IDs are the acceptance ledger. A row is not executed unless every
named subcase has a deterministic trace.

| Stable row ID | Foremost state | Explicit prior route | Back result, preserved/cancelled state, and required subcases |
| --- | --- | --- | --- |
| `M8-BK-01` | Starter inspect folio | Starter gallery at the same focused creature | Close inspect only; preserve carousel focus; no starter selection/grant/save. |
| `M8-BK-02` | First Print review before accepted start | Recorded First Print caller | The First Print review is the starter-special integrated Forge `IDLE` surface. Clear only the uncommitted preview; preserve the committed starter grant and make no cost/job/print/receipt mutation. Execute `02a` immediate post-selection -> Workshop overview, `02b` Title Continue resume -> Title, and `02c` explicit caller fixture -> that recorded caller. |
| `M8-BK-03` | Forge blueprint selection | Recorded caller: Workshop printer hotspot, Archive detail, or Collection-equivalent route | Blueprint selection is an assertion on the integrated Forge `IDLE` surface, not a separate route. One Back clears uncommitted local Forge state and returns directly to the recorded caller with focus/filter/page preserved. Execute `03a` Workshop, `03b` Archive detail, and `03c` Collection-equivalent caller. |
| `M8-BK-04` | Forge print review | Same recorded caller as the integrated `IDLE` surface | A valid loaded blueprint and its review facts are the second assertion on that same `IDLE` surface. One Back exits directly to the recorded caller; it does not invent a review -> picker transition or require a second press. Preserve catalog/profile/coins/ownership. Execute loaded-blueprint and empty/recovery variants. |
| `M8-BK-05` | Forge active print | Recorded caller, normally Workshop | Execute `05a` PRINTING/RAW_HOLD/AWAKENING/DEPARTING -> leave without cancelling/completing and resume the same generation/progress; `05b` RAW_COMPLETE commit window -> both Back forms locked with reason; `05c` AWAKENED/FAILED -> Return to recorded station. Late callbacks cannot duplicate. |
| `M8-BK-06` | Archive creature/support detail | Archive folio grid | Only Archive may treat `unified_inspector_id` as dismissible foreground depth. Close detail; preserve category/filter/page/focused record; zero mutation. A retained Archive caller behind Forge/Deck cannot consume their first Back. Execute creature and support detail. |
| `M8-BK-07` | Archive folio root | Workshop archive hotspot | Return to Workshop with no filter/profile mutation. |
| `M8-BK-08` | Deck card/Pre-Print inspect | Deck Workbench with same draft | The selected-card inspector is persistent workbench focus (`m3_deck_selected_card_id`), not a modal. Do not close it or consume a Back. Execute selected creature, selected support, and Pre-Print clamp focus; Back immediately follows `M8-BK-09` or `M8-BK-10` according to dirty state. |
| `M8-BK-09` | Deck/Pre-Print root, clean | Workshop deck hotspot | Return directly in one press; preserve saved slot/deck/Pre-Print state. Execute Workshop entry and direct Archive-to-Deck entry; no stale Archive inspector may absorb the first Back. |
| `M8-BK-10` | Deck/Pre-Print root, dirty | Dirty-exit confirmation | Execute `10a` Stay -> exact draft retained, `10b` Android Back on docket -> byte-equivalent Stay, `10c` Discard -> saved deck and Pre-Print values restored on re-entry, `10d` Save -> validate and atomically persist the combined deck + Pre-Print state once before return, and `10e` injected deck or Pre-Print persistence rejection -> remain visible with zero partial mutation. |
| `M8-BK-11` | Market purchase confirmation | Same Market tab/offer/scroll position | Execute `11a` pending/not executing -> cancel request only with zero currency/ownership/receipt mutation, and `11b` in-flight -> visible Cancel and Android Back both remain locked until the exactly-once purchase resolves; neither may clear the confirmation early. |
| `M8-BK-12` | Market root | Workshop supplies/market hotspot | Return to Workshop; preserve settled market snapshot and accepted purchases. |
| `M8-BK-13` | Settings opened from Title | Title | Cancel unapplied draft and return to Title; already applied settings remain saved. |
| `M8-BK-14` | Settings opened from Workshop | Workshop settings hotspot/caller | Cancel unapplied draft and return to Workshop; already applied settings remain saved. |
| `M8-BK-15` | Battle preflight | Challenge board | Return to challenge board with selected legal deck/three Pre-Print summary intact; no battle instance/seed/reward mutation. |
| `M8-BK-16` | Challenge board root | Workshop battle dais | Return to Workshop; no battle transaction. |
| `M8-BK-17` | Battle result, committed/duplicate receipt | Workshop battle dais | Execute `17a` committed and `17b` duplicate. File/retain the existing exactly-once result and return to Workshop once; Back cannot undo or replay reward/profile settlement. |
| `M8-BK-18` | Battle result, pending/error | Same result receipt/error station | Execute `18a` pending -> Continue disabled and Back locked with reason, `18b` error -> remain with Retry as the only transaction action, `18c` retry failure -> remain error without mutation, and `18d` retry success -> transition exactly once to committed or duplicate. No fabricated settlement. |

Battle Plan/Run Cycle has no ordinary Back route while a live match is resolving.
If no visible Back is offered there, Android Back is consumed with a native
`Finish or resolve this battle first` reason; it never abandons to Workshop or the OS.

### Deterministic Back acceptance

`test_m8_route_back_contract` creates all 18 stable row IDs and every named subcase
twice from the same serialized fixture. It activates the visible control in one copy
and an Android
`go_back_requested`/system-Back event through the central dispatcher in the other,
then asserts:

- exact destination route/caller and modal depth match;
- relevant draft/filter/page/focus/job/generation snapshots match;
- profile/save/revision/currency/ownership/receipt values match the table;
- callback and route-transition count is exactly one;
- no stale deferred/timer callback changes either snapshot afterward;
- disabled/in-flight behavior and native reason match; and
- every visible target is >=48x48 logical pixels and reachable at 100%/150% text.

`test_m8_back_transaction_atomicity` injects persistence rejection, repeated press,
orientation rebuild, and route replacement during each save/commit boundary. The
Deck dirty-exit Save is one combined atomic deck + Pre-Print operation: neither half
may become authoritative unless both validations and persistence steps succeed. The
test requires zero partial mutation, no duplicate settlement, an in-flight Market
Back lock identical to its visible disabled Cancel, and the current safe route to
remain visible.

| Capture ID | Visible Back state | Required sizes |
| --- | --- | --- |
| `M8-BK-01-StarterInspect` | Inspector -> same Starter focus | 576x1024, 720x1280 |
| `M8-BK-02-ForgeStates` | Selection, review, and active-print Back ownership | 576x1024, 720x1280 |
| `M8-BK-03-ArchiveDetail` | Detail -> preserved folio context | 576x1024, 720x1280 |
| `M8-BK-04-DeckDirtyExit` | Save/Discard/Stay consequences | 576x1024, 720x1280 |
| `M8-BK-05-MarketConfirmation` | Cancel purchase -> same offer context | 576x1024, 720x1280 |
| `M8-BK-06-SettingsCallers` | Native Back to Title and Back to Workshop labels | 576x1024, 720x1280 |
| `M8-BK-07-BattleReturns` | Preflight -> board and committed result -> Workshop | 576x1024, 720x1280 |
| `M8-BK-08-Back150Text` | Representative modal/root Back controls and dirty prompt | 576x1024, 720x1280 at 150% |

Static captures prove visible destination language, physical ownership, focus, and
target geometry. The system-Back equivalence, cancellation, callback count, and
zero-mutation claims require deterministic event/state traces; screenshots alone
cannot close them.

## M8 acceptance boundary

Current implementation evidence is ready for read-only UI review:

- route ledger PASS: `build/task-state/m8-route-ledger-r11/`;
- combined atomicity PASS: `build/task-state/m8-atomic-combined-r1/`;
- progressive-print prior PASS: `build/task-state/m8-r7-fix/regression-r2/`;
- visual atlas: `build/evidence/m8-pat-print-back/captures-r7-final-r2/`; and
- focus supplement: `build/evidence/m8-pat-print-back/captures-r7-final-r5-focus-refresh/`.

These paths admit the implementation to UI review; they do not replace original-
resolution review. M8 closes only when both named test groups pass from the intended
commit, all 18 stable Back rows and named subcases are present in the executed ledger,
every capture has exact dimensions and SHA manifest evidence, and read-only original-
resolution UI review reports P0 none/P1 none for progressive print and all visible
Back states. Full regression must preserve M1-M7 gameplay/save/animation behavior.

This checkpoint does not claim Android/device behavior, APK/export audit, DriveFS
copy, or cloud synchronization.
