# Native Collection completion checkpoint

Primary implementation plan, 2026-09-13. This completes the approved M0 Collection
workflow; no gameplay, new art direction, default entry or Android export change.
Terra remains the sole runtime writer. Finish the bounded First Forge corrections
before starting this checkpoint; primary reviews and commits the result.

## Inputs and ownership

- `team-prototype-native-ui-plan-20260912.md` owns behavior and architecture.
- `team-prototype-collection-ui-registration-20260912.md` owns exact art seats.
- `team-prototype-native-copy-20260912.md` owns vocabulary and concise wording.
- Current Forge controller/passive compositor remain reusable and independently
  tested. Do not regress raw/save/awaken/depart order while splitting the shell.
- Accepted Collection, MatchSession, Store, Rules and existing Main are not rewritten.
  Only a narrow Runtime settings-validation correction is in scope.

The existing native shell outside First Forge is an unaccepted scaffold. Replace
its monolithic route rendering with small shared chassis/widgets, starter/Forge/
grant, Team/Kit, and system-route presenters. Shell owns routing, runtime instance,
cached view, local draft, errors and logical request lifetimes. Presenters own native
nodes, not authority or persistence. Avoid extra general-purpose frameworks or
duplicate data models. Stable native control names support tests and focus restore.

## Required behavior

1. Uniform941x1672 contain fit inside all four platform/synthetic safe insets;
   inert dark workshop letterbox. No ad reserve, stretch or second scaled content
   layer. Minimum48 final viewport pixels,56 for primary controls. Enlarging a hit
   must not move/repaint its art or overlap a neighboring active hit.
2. Deterministic fallback sans theme. Real100/150% fonts independent of contrast.
   Correct native ink/cream/outline tokens per physical material. No generic panel
   or duplicate image over baked hardware. Expose meaningful accessibility names,
   selected/disabled state and reasons. Passive art/labels ignore pointer input.
   Cache a mipmapped display texture for the existing transparent blueprint ink
   if its imported texture has no mipmaps. A LINEAR_WITH_MIPMAPS filter flag alone
   does not create mipmaps. Prepare once per requested asset, preserve source art,
   and verify fine strokes at the92-final-pixel Forge docks as well as Starter.
3. One Back dispatcher for visible control, Escape, Android key/notification and
   window close. Deduplicate a platform key+notification pair without swallowing
   deliberate later taps. Inspector/confirmation closes first. Team/Kit Back discards
   the local draft; Settings Back discards its settings draft. Root Back opens a
   physical Leave/Stay confirmation. No data reset, forfeit, capture or fullscreen.
4. Remove old route children from their parent before queue_free; an old hit must
   not remain live until the next frame. Rebuild on size/safe/text changes without
   losing active draft, modal or stable focused control. Pause visual time when
   hidden/backgrounded; never accumulate background progress or persist on focus.
5. Retain a request's ID and immutable payload only for that logical attempt. Failed
   action Retry uses the same envelope; accepted action releases it. A later Apply
   creates a fresh ID. Use process-independent collision-resistant IDs. Display a
   visible error/retry on the same physical owner; don't silently fail or navigate.
6. Workshop uses the exact authored hotspots (not the old576-coordinate values in
   the941 layer). Forge opens Starter when none chosen, available/printing Forge
   while pending, existing grant if settled, and Team if already acknowledged.
   Team/Kit/Settings/Preflight navigation works. No detached Workshop heading or
   fake pack/Market controls. Preflight remains a read-only destination until Battle.
7. Starter arrows are transparent hits over painted arrows, with accessible names,
   not new words on top of arrows. Inspect and Choose confirmation reuse the desk.
   Confirmation disables other choices; Back closes it with zero write. Correct
   Back seat, full names, element/common and native voucher copy for all3 starters.
8. Grant uses actual frozen receipt/guarantees, real mini icons and Support15/15.
   Continue says Continue / To Team, acknowledges once, then loads an unsaved valid
   recommended draft. Failed acknowledgement stays on the receipt with Retry/Back.
   Reopening a settled grant never calls Complete again.
9. Team bays show rooted living front-view printed minis, not blueprints/cards.
   Bay tap opens central-parchment selector with eligible owned Printed companions;
   duplicates in another slot disabled with reason. Selection edits local Team only.
   Print Order opens its separate selector and Move Up/Down, changing priority only.
   Switching one Team ID replaces that ID in priority without changing other order.
10. Kit uses four authored chips/page with V3Catalog art + atlas_region only. No
    generic CardView frame/text composition and no duplicate magazine/card back.
    Fifth type on page2 is reachable. Chip opens native effect/owned/selected
    inspector; Minus/Plus obey actual owned bounds. Recommended sets draft3/2/3/3/4
    locally. Team view retains useful Support context. Modal blocks underlying
    mouse/focus; Back restores the opening control.
11. Apply atomically saves exact3 unique Printed, priority permutation, owned15 Kit.
    Invalid Apply shows the authority reason. Cancel/Back discards all three draft
    parts. Subsequent valid changed Apply must work with a new request ID.
12. Settings has only100/150, HC and RM on registered ST-01 seats; local preview,
    Apply and Back. No125/audio fake controls. Stored malformed scale must compare
    safely against10000/15000 before integer conversion (including huge/nonfinite
    values). Unknown settings/profile keys survive Apply and later Collection actions.
13. Recovery is read-only with concise visible reason, full accessible detail and
    View Details/Close on the authored owner. Back/Leave remain usable; no repair.

## Verification gate

Use the audited runner and sibling `ui-fixtures`, never player/qa-save mutation.
Tests must exercise native actions instead of asserting that a Button merely exists.
Assert exact five successful profile writes for fresh Choose/Begin/Complete/Ack/Apply;
zero writes from inspect, navigation, draft, cancellation, focus and presentation.
Exercise each starter guarantee mapping, pending/reopened print, actual file fault
injections for Begin/Complete/Ack/Apply, identical retries and no double-grant.

Exercise Team replacement/duplicate rejection/priority independent reorder, all5
Support inspectors and art faces, owned bounds, invalid14/16 and valid15, Cancel,
later changed Apply, and reload through a new Runtime instance. Settings malformed
types, real JSON numeric reload,150 without HC, unknown preservation and later
Collection action must have explicit assertions.

Capture actual Workshop, all3 Starter identities/Inspect/confirmation, Forge60/Retry,
each starter Grant, empty/valid Team, selector/priority, Kit page2/inspector,
Settings/Recovery/root confirmation. First correct576 normal, then720x1280 and
720x1600 with synthetic safe insets; repeat representative route families at150%,
HC and RM. Explicitly assert final hit sizes/nonoverlap and modal-only focus.
Source/capture errors fail even if the scene prints a success marker.

The UI reviewer compares these exact native captures to approved M0. This checkpoint
does not claim Battle, APK, physical Android input/performance or Drive delivery.
