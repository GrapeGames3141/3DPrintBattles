# Native team-prototype vertical slice

Primary architecture/interaction plan, 2026-09-12. This implements the approved M0
atlas at `docs/art/team-prototype-20260912/INDEX.md`, not the historical six-slot
printer-damage game. Entry is gated on accepted Match Session/file adapter and the
cleaned Voltwig source. No new concept generation or mechanics approval is needed.

## Sole-writer components

Terra owns new `scripts/team_ui/` components and `scenes/team_prototype.tscn`:

- Shell/router: one runtime facade, route stack, shared visible/system Back, modal
  focus, explicit action requests and errors. No rule or grant arithmetic.
- Chassis/widgets: uniform portrait composition and reusable native text, transparent
  hardware hits, authored controls, blueprint imprints and support face regions.
- Collection screens: Workshop, Starter/Inspect, first Forge/grant, Team/Support Kit,
  compatible read-only recovery and minimal native Settings.
- Battle screen: Plan selection and viewer-safe projections only.
- Battle presentation: finite stage playback, rooted directional sprites, printer
  clipping/wireframe/scan, equipment and contact shadows.

Split scripts by these responsibilities rather than adding another large branch to
`scripts/ui/main.gd`. Reuse existing physical control/navigation/blueprint helpers,
facing cache, raw-filament and wireframe shaders and Forge sequence primitives.
The old Main and combat authority are not prototype dependencies.

## One composition owner

Use the exact masters and registration coordinates in
`team-prototype-m3-reuse-audit-20260912.md` and the final approved atlas CSS, including
its last accessibility overrides. Promote only the reviewed Team/Battle masters and
accepted armor RGBA into runtime assets. Keep all reference atlases/docs out of APK.

Design space is 941x1672. Fit uniformly inside the viewport's safe content rectangle;
never stretch a tall screen. Convert platform safe area from physical display space
to viewport coordinates once; use explicit synthetic insets only in tests. Remaining
space is inert workshop-colored letterbox. Additional production ad reserve is zero.
Reflow on size/safe-area/text changes, preserving draft, selected card, receipt and
focus identity. Minimum touch size is 48 logical pixels (56 primary); maintain those
minimums in final viewport units, not mistaken 941px source pixels.

Static hardware owns its image once. Put transparent native hit/focus/disabled
glazes over already-painted hardware. Use the shared generated control family only
where the master has no control. Labels, values and accessibility names stay native.
No opaque generic app panels, duplicate book/card imagery or baked dynamic labels.
Blueprint imprints use the approved v2 transparent ink family on parchment.

## First session and collection

- Read-only opening decides compatible route from actual Collection state. Missing
  profile/namespace does not grant or save. Starter portrait carousel has three
  choices and working previous/next, Inspect, Choose and Back actions.
- Choose calls the accepted `choose_starter` action once. The chosen license,
  voucher and two guaranteed common prints are shown truthfully. No RNG or packs.
- Start First Print persists `begin_starter_print` before animation. Show empty bed
  at 0%, progressive raw solid below scan/wire above, then raw-complete. Commit
  `complete_starter_print` once at its authority boundary before showing Awaken or
  grant success. If commit fails, stay raw-complete with explicit Retry; no finished
  living figure or false grant. Retry retains the attempted request ID.
- Back during print leaves a resumable pending voucher; reopening Forge may restart
  its presentation without adding a print or support entitlement. A settled voucher
  shows its existing grant receipt, never calls completion again.
- Grant Continue acknowledges the same receipt and opens Team with recommended
  Team/Kit as an unsaved draft. One explicit Apply saves 3 unique printed companions,
  reserve priority and the 15-card recommended Kit. The first battle requires this
  valid applied loadout, not grind or luck.
- Team slots select owned eligible companions; no duplicate stacking. Priority is
  an explicit reorder. Kit editor exposes all five support types/counts, plus/minus,
  ownership limit, 15 total, and Restore Recommended. Paging may reuse four authored
  card slots, but the fifth type must be reachable and counted. Inspect explains
  support effects. Invalid Apply disables with a reason; Cancel/Back writes nothing.
- Workshop physical hits navigate to Forge, Team, Kit, Battle/Resume and Settings.
  Do not expose nonfunctional Market/pack/upgrade/printer-HP controls. These are not
  prototype requirements. Ineligible collection items may be inspected as excluded,
  but cannot enter Team or Kit. Preserve the existing collection entitlement.
- Settings explicitly changes text scale (100/150), contrast and reduced motion;
  persistence preserves every unrelated profile value and uses the checked file
  boundary. Merely opening Settings or moving a focus ring writes nothing.
  Keep changes as a local draft until Apply; Back discards that draft. Accept only
  `text_scale_bps` (10000/15000), Boolean `high_contrast` and `reduced_motion` here,
  preserving other settings keys. Refresh the Collection private profile after a
  successful settings write so later Collection actions cannot undo settings.

## Battle input and presentation

- Preflight reads applied 3/15, priority and deterministic seed; Start freezes one
  match through MatchSession. An unfinished match offers Resume, never replacement.
- At Plan, select optional Unspent fabrication and at most one support OR Ready
  swap. Default fabrication when needed and all affordability/queue/target checks
  come from `Rules.check_view_plan`, not UI heuristics. Tapping a selected action
  again clears it. Gear selection opens an eligible-target sheet; targets derive
  from `eligible_equipment_targets`, including a legal next fabrication.
- Display whole-number filament now, composite cost/aid, next-cycle forecast,
  FIFO contents/work and native reasons for invalid Run. Four visible hand cards
  maximum; rival hand is exact backs/count, never private card IDs or queued Plan.
- Run sends one revision-bound player Plan; MatchSession alone derives the bot.
  Disable Plan inputs during the accepted receipt. UI renders only viewer-projected
  opening/stage snapshots cached at receipt boundaries; no full authority snapshots
  or file/image reads per frame.
- Each receipt stage has bounded time, based on its events. Empty event stages may
  settle immediately. Print visibly reveals the current FIFO head from work_before
  to work_after; only that unfinished silhouette exists in its printer. Equipment
  prints approved equipment art, never a creature. Awaken changes raw to living
  material only after completion. Enter walks that same living figure into Active
  or a Ready bay; do not duplicate a home copy during motion.
- One Active on each continuous floor area, two Ready staging bays each side.
  Unspent/Printing/Defeated are native roster records, not prematurely living minis.
  Both sides keep their real inward front/rear views, including neutral two-view
  Voltwig. Finite breathing/windup/contact/return is native for Voltwig and respects
  the common planted root. Shadows follow movement and return to the same root.
  Use `team-prototype-sprite-root-audit-20260912.md` for measured per-frame root
  inputs and the airborne-contact rule; never normalize every sprite to y455.
- Both locked attacks resolve visually without changing simultaneous damage rules.
  Replacement enters the chosen ready priority automatically. A zero-active wait
  still permits the legal replenishing Run. No manual phases, printer targets,
  life/shattering animation, fatigue or artificial round-limit win condition.
- After each finite stage, persist only its cursor. Store failure pauses at that
  exact stage with Retry/Back; successful stages are not replayed on Resume. Skip
  advances checked cursor only; reduced motion uses grounded finite state changes,
  readable feedback and the same final authority. No animation grants rewards.
- Terminal Result reads the already-settled Win/Loss/Draw receipt and fixed XP/coins.
  Present completed result before allowing a next match. Back remains available.

## Back, lifecycle and input safety

One dispatcher handles native Android Back, Escape and visible Back. Close an open
inspector/target sheet first, then leave the route with its durable match preserved.
Team/Kit Back is Cancel and discards the local unsaved draft. Back from root can show a native
physical confirmation to close the application; no reset/delete/forfeit action.
Background/foreground pauses only presentation clock and resumes from accepted
authority/cursor. No mouse capture/confinement, fullscreen desktop launch or window
control helper. Every fixture uses task-owned isolated paths/processes.

## Delivery gate

Only after the vertical slice works change default main entry and prototype startup
selector so both a normal source launch and Android export enter this exact mode.
Android custom feature must be `team_prototype`, not `unified_playtest`. Retain old
source for history without exposing old battle/deck routes in the new prototype.
Do not export an APK which silently launches the historical game.
At that entry change, keep prototype autoload loading strictly read-only and validate
untrusted top-level schema types before calling any legacy compatibility helper that
casts `schema_version` with `int()`. The accepted Collection projection/file boundary
must decide malformed/future profile recovery without a startup script error or
normalization. Preserve the explicit ready/future/recovered startup evidence states.

Run deterministic first-session/actions/back/resume/receipt/legality tests and actual
native captures specified in the M3 reuse audit at 576x1024, 720x1280 and 720x1600.
Read-only UI reviewer compares captures to M0, requiring no P0/P1 layout/alpha/input
issue. Primary reviews maintainability at the collection and battle boundaries:
authority not copied, geometry shared once, cached resources, finite lifecycle,
no accumulated signal/timer/node leaks, no per-frame heavy snapshots.

Physical Android input/lifecycle/performance remains unverified until a device is
available. Review-build notes must distinguish that limitation from desktop tests,
APK metadata/signing/compiled-asset checks and verified DriveFS delivery.

## Gameplay-design interaction audit

The plan matches the accepted simplified battle contract after these bounded
clarifications; no new feature or approval is required:

- Production preflight receives one stable seed from the runtime facade for the next
  sequence; UI never generates, edits, randomizes, or rerolls it. Derive the production
  default as `(next_match_sequence - 1) % 2147483648`, yielding State's supported
  range and the already approved deterministic rival rotation. Test fixtures may
  inject explicit seeds. Leaving and reopening the same uncommitted preflight keeps
  the same sequence-derived seed.
- Back is route-specific, not a promise to retain every unsaved draft. An inspector or
  equipment-target sheet closes first. Team/Kit Back is exactly Cancel: discard local
  unsaved Team, priority, and Kit edits and reload the last saved loadout, or the
  recommended draft when none is saved. Restore Recommended is also local until Apply.
  Settings Back discards uncommitted settings. Preflight Back is zero-write.
- Battle Back preserves the durable current match but does not commit an unsubmitted
  Plan. Resume returns to the same authority Plan boundary or stored presentation
  cursor; the UI may retain an unsubmitted selection only in the live route instance,
  and must revalidate or discard it after reload. Back never submits Run, abandons,
  forfeits, replaces the match, or grants a reward.
- Receipt-stage acknowledgement occurs only after that finite stage reaches its
  grounded end state. If its cursor write fails, keep the completed visual pose and
  offer Retry/Back; after process restart the unacknowledged stage may replay, but no
  authority, Rules call, entitlement, or reward may replay. “Successful stages are
  not replayed” means stages whose cursor acknowledgement was durably accepted.
- The terminal Result stage becomes presentation-complete only after its receipt is
  visibly rendered and its final cursor acknowledgement succeeds. Back before that
  point yields **Resume Result**; Back after it may expose **New Battle**. Neither path
  claims or regrants the reward, which was already settled by terminal Run.
- Grant Continue and every Retry use the retained authority request identity. Failed
  acknowledgement keeps the receipt visible with Retry/Back and does not open Team as
  though acknowledgement succeeded. A settled-but-unacknowledged grant is always
  resumable and never calls completion again.

Native acceptance must explicitly exercise visible/system Back at Starter, pending
print, raw-complete retry, grant receipt, Team/Kit dirty draft, preflight, Plan,
mid-stage, cursor failure, Result before acknowledgement, and Result after
acknowledgement. At each point assert the exact zero-write, discard, Resume, or
next-route behavior above and confirm no rival-private data reaches native controls.

## Read-only UI audit resolutions

Primary accepted these bounded implementation details after the UI agent compared
the final M0 CSS with the reusable native APIs. They fill interactive states on the
approved masters, not a new visual direction or a runtime visual sign-off.

- Team bay taps open a focus-trapped selector on the same TM-R1 master's central
  parchment; do not invisibly cycle through companions. Use a native title at
  `(133,534,674,43)`, up to three blueprint/name row hits at y588/684/780, each
  `(133,y,674,88)`, then page studs `(133,880,92,92)` and `(718,880,92,92)` with
  a centered page readout. Rows show only eligible owned Printed companions, plus
  disabled duplicate reason when occupied elsewhere. Choosing applies to the local
  draft and closes the selector; Back closes it with no selection/write.
- Kit has four authored card slots per page at `(71.88,1042.5,596.27,248.4)`;
  page2 exposes the fifth support type with a visible page indicator. Use the same
  lower-parchment page studs above, not swipe-only navigation. A chip opens a native
  inspector on central parchment with name, effect and owned/selected counts.
  While inspecting, replace page studs with wide Minus/Plus hits
  `(150,865,250,104)` and `(541,865,250,104)`. Back closes the inspector first.
  Count changes affect the draft only. Page controls use the generated `square`
  family and +/- use `wide`, because those seats have no baked control.
- Priority order is the existing three-slot order. The default Print Order readout
  `(127.42,591.55,686.51,72.06)` is an expanded transparent48px-minimum hit opening
  a separate Print Order sheet on the central parchment. Its three rows select a
  draft index; Move Up/Move Down use the same two wide central-parchment control
  seats. Endpoints are disabled with a reason. Back closes the sheet; no save or
  drag-only dependency. The companion-selection sheet remains a separate state.
- Do not reuse `PhysicalSettingsRecoveryComponent.render_settings()` wholesale:
  it exposes unapproved 125% and audio callbacks. Build only the accepted draft on
  ST-01's normalized seats: text plate `(.222,.085,.285,.120)`, text dial
  `(.545,.085,.320,.120)`, HC `(.222,.452,.646,.090)`, RM
  `(.222,.551,.646,.090)`, preview `(.160,.670,.700,.185)`, Back
  `(.165,.886,.215,.076)`, Apply `(.474,.900,.386,.080)`. Other scenery/hardware
  remains decorative, with no interactive or accessibility control pretending to work.
- Reuse `PhysicalControlFamily.apply(...,transparent_hit=true)` over baked controls,
  `M1PhysicalUiComponent.add_inset_button_focus_ring`, Workshop-only
  `add_complete_focus_ring`, and `PhysicalNavigationComponent.configure_back`.
  Do not draw `ArcaneFoundryThemeKit.panel/button(high_contrast=true)` over masters.
- `M1PhysicalUiComponent.place_design` assumes the exact fitted design layer.
  Minimum hit size in that layer is `required_final_pixels / fit_scale`; e.g.
  48px final is78.42 design pixels at576wide. Enlarge transparent hit bounds around
  authored centers, not the art itself. All four safe insets are respected.
- `PhysicalCatalogImprint.blueprint_texture(definition)` and `add_blueprint_card`
  use normalized rects, so divide design x/w by941 and y/h by1672. Reuse only
  `SupportCardView.atlas_region(definition)` and `card_back_for_test()`; do not
  instantiate its generic framed/text card composition inside the new master.
- Use deterministic `ThemeDB.fallback_font` sans on the prototype root Theme.
  Existing Arvo display font does not match approved M0 typography. Baseline is
  26–27 design pixels; approved150% battle overrides use39.21px/42.48px line height
  from final atlas CSS, not a second content-layer scale. Ink tokens are cream
  `#fff0c8` on dark, `#24160b`/`#162536` on parchment, cyan `#8bf6ff` focus
  (white focus in HC). Required decision text cannot disappear behind ellipsis.
- Add150% overflow/focus captures for every route family at576x1024 and720x1600:
  Workshop, Starter/Inspect, Forge/Retry, Team selector/Kit inspector (fifth type),
  Grant/Result, Settings/Recovery. No clipping or sub48px final hit. These are
  runtime accessibility checks, not a request to regenerate the approved atlas.

Use `team-prototype-native-copy-20260912.md` for concise native wording. Authority
values/events win if a textual example conflicts; do not encode rules in copy helpers.
