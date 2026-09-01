# M7 runtime visual corrections HOLD v1

Status: **HOLD - five P1 runtime visual corrections required; implementation and
evidence pending**

Date: 2026-09-01

Authority: M1-M7 deterministic design/checkpoints, the exact approved blueprint v2
family, and the latest read-only runtime UI review. This checkpoint records only the
five P1 corrections below. It does not claim that any correction exists.

## Locked boundaries

- No gameplay value, catalog, ownership, legal-deck, three Pre-Print, print, reward,
  economy, profile, or save-schema change.
- Battle remains Plan -> Run Cycle. Existing print, awaken, attack, and battle-end
  ordering and deterministic outcomes remain unchanged.
- Approved blueprint art is pre-print representation; raw/wireframe is extrusion;
  existing animated sprites are awakened field units; rival concealed cards remain
  the existing card back.
- Portrait only, native dynamic text/accessibility, minimum 48-logical-pixel targets
  and 56-logical-pixel primary actions, safe areas, 150% text, high contrast, reduced
  motion, and zero no-AdMob reserve remain authoritative.
- Captures are original-resolution Forward+ runtime evidence. Generated mockups,
  source inspection, and geometry-only fixtures cannot close this HOLD.

## P1 correction contracts

### P1-1: First Print cartridge blueprint legibility/material

- **Entry:** The deterministic first-print fixture reaches the cartridge-loaded setup
  before extrusion at 576x1024 or 720x1280.
- **Player decision:** Inspect the selected blueprint, continue the existing first-
  print action, or return without committing.
- **Result:** The approved intact blueprint is immediately legible as transparent ink
  integrated into the cartridge's physical paper/label material. Creature contour,
  build plane, supports, and subordinate datum survive at card scale; the cartridge
  reads as a handled workshop object rather than a flat app card or pasted rectangle.
  Native creature name, cost/status, focus, and action text remain separate and clear.
- **Failure:** Washed-out/low-contrast ink, opaque sticker rectangle, blueprint hidden
  by glare/texture, paper inconsistent with the cartridge, clipped creature, baked
  label, finished creature, or unreadable native value keeps the P1 open.
- **Disabled:** An unavailable/illegal cartridge remains visibly noninteractive and
  cannot borrow another creature's art. Continue remains disabled until the existing
  first-print prerequisites pass.
- **Feedback:** Four-edge inset focus, physical pressed/selected treatment, native
  status, and accessible name remain readable at 100%/150% text and high contrast
  without tinting away blueprint identity.
- **Progression:** Inspect/focus/back are zero-mutation. The existing exactly-once
  first-print transaction alone advances the profile.

Deterministic acceptance: `test_m7_first_print_cartridge_material`; captures
`M7-RV-01-FirstPrintCartridge` at 576x1024 and 720x1280, plus 150% text at 576x1024.

### P1-2: Deck parchment-consistent thumbnails and reachable controls

- **Entry:** Open Deck Workbench with owned and unowned creatures, a legal saved deck,
  and three Pre-Print selections at each standard portrait size.
- **Player decision:** Inspect/select a blueprint thumbnail, change an existing legal
  deck/Pre-Print choice, use Back, or save through the existing transaction.
- **Result:** Every creature blueprint thumbnail uses transparent approved ink on the
  same parchment/material family as its physical Deck seat; no navy/white sticker or
  mismatched paper tile remains. Native count/legality/selection labels remain clear.
  Back, Save, and Pre-Print each expose a visible physical target at least 48 logical
  pixels in both axes, with the primary commit target at least 56 where already
  designated.
- **Failure:** Pasted rectangular art, inconsistent parchment, clipped/illegible
  thumbnail, focus crossing label padding, target below 48 pixels, overlap, dead hit
  region, wrong callback, or Save mutation before validation keeps the P1 open.
- **Disabled:** Illegal cards, invalid Save, and unavailable Pre-Print seats are
  visibly disabled and cannot look pressed/active. Back remains reachable and never
  mutates deck state.
- **Feedback:** Hover/focus/pressed/disabled/saved states are physical and distinct;
  native validation and exactly-once save receipt remain readable at 150% and high
  contrast without relying on color alone.
- **Progression:** Browse, inspect, Back, and failed validation are zero-mutation.
  The accepted Save persists one legal deck/three Pre-Print state exactly once.

Deterministic acceptance: `test_m7_deck_blueprint_material_and_targets`; captures
`M7-RV-02-DeckWorkbench` and `M7-RV-03-DeckWorkbench-150Text` at 576x1024 and
720x1280. Geometry assertions require Back, Save, and Pre-Print >=48x48 logical
pixels and label-safe four-edge focus.

### P1-3: Workshop transparent physical hit regions and inset focus

- **Entry:** Enter the six-hotspot Workshop in completed-profile state at each
  standard portrait size, including keyboard/controller focus traversal.
- **Player decision:** Focus and activate printer, battle dais, archive, deck,
  supplies, or settings through its visible physical object.
- **Result:** Each interactive region is transparent and aligned to its physical
  object's readable silhouette/medallion, with no opaque stock-button plate or broad
  invisible rectangle stealing adjacent input. Focus is inset within the object's
  physical boundary, shows all four edges, and does not cross labels or scenery.
- **Failure:** Misaligned/dead hotspot, activation outside the object, overlap that
  routes to the wrong destination, opaque button chrome, clipped/outset focus, hidden
  focus, or unreachable route keeps the P1 open.
- **Disabled:** Any route disabled by authoritative state retains a visible physical
  seat and clear noninteractive treatment; its transparent hit region cannot activate.
- **Feedback:** Focus/hover/press occurs on the owning physical object, native
  accessible name announces the destination, and accepted activation gives immediate
  finite physical feedback before one route transition.
- **Progression:** Focus and failed/disabled presses are zero-mutation. Each accepted
  hotspot performs only its existing route transition and cannot double-open.

Deterministic acceptance: `test_m7_workshop_physical_hit_regions`; captures
`M7-RV-04-WorkshopHotspots` and `M7-RV-05-WorkshopFocusTraversal` at 576x1024 and
720x1280, with hit-map assertions for all six routes and no overlaps/dead regions.

### P1-4: Active Print physical instrument plates and no dead glass void

- **Entry:** Pause the deterministic active print at 60% with native progress,
  material/status, layer, and time values populated at each standard portrait size.
- **Player decision:** Inspect status or use the existing reduced-motion/skip affordance
  where legal; no new print decision is added.
- **Result:** Every dynamic printer value is seated inside a readable brass/leather/
  workshop instrument plate with physical ownership and padding. The printer bed and
  solid-below/wireframe-above creature remain the visual focus. The former empty glass
  void is replaced by purposeful printer-bed depth, instrument structure, or authored
  workshop material; it is not filled with unrelated UI or decorative noise.
- **Failure:** Floating stock labels, values outside plates, dead reflective/glass
  expanse, generic app panel, covered print, wrong 60% split, finished creature, or
  clipped 150% value keeps the P1 open.
- **Disabled:** Completion/claim remains disabled before authoritative completion.
  Disabled instruments retain a physical seat and cannot present active press cues.
- **Feedback:** Native 60% progress and status are readable at 100%/150%, high
  contrast distinguishes plate/value/state without color alone, and reduced motion
  holds the same semantic print frame without a sweep.
- **Progression:** Status inspection and presentation changes are zero-mutation. The
  existing exactly-once print transaction alone changes job state.

Deterministic acceptance: `test_m7_active_print_physical_instruments`; captures
`M7-RV-06-ActivePrint60`, `M7-RV-07-ActivePrint60-150Text`, and
`M7-RV-08-ActivePrint60-HighContrast` at 576x1024 and 720x1280.

### P1-5: reduced-motion battle end frame preserves combat readability

- **Entry:** Run the named reduced-motion deterministic battle fixture through its
  final accepted attack: player Cinderpaw remains on field, Aquafin is the damaged
  target, and battle-end resolution has not yet removed the readable combat frame.
- **Player decision:** Watch Run Cycle with reduced motion enabled; no manual Attack,
  target, damage, or phase choice is introduced.
- **Result:** The held battle-end semantic frame visibly preserves the player's
  awakened Cinderpaw and damaged Aquafin together. Both printer bodies and native HP/
  damage HUD, player hand, and rival concealed hand/count remain readable. The finite
  damage/end feedback does not replace either creature with a blueprint, raw print,
  empty field, oversized receipt, or full-screen effect.
- **Failure:** Missing/hidden Cinderpaw, missing/undamaged/unidentifiable Aquafin,
  cropped printers/HP/hands, early result takeover, ambiguous damage ownership,
  animation stall, duplicate intent/damage, or a manual phase button keeps the P1
  open.
- **Disabled:** Plan, hand actions, and Run Cycle reactivation remain visibly locked
  during the end frame. Rival cards remain concealed and noninspectable.
- **Feedback:** Reduced motion uses a stable contact/damage pose, native ordered damage
  event and HP delta, then a finite result handoff. High contrast keeps both creature
  identities and damaged state readable without motion or color alone.
- **Progression:** Presentation does not choose or reapply combat. The accepted attack
  and battle result advance authoritative revisions/rewards exactly once.

Deterministic acceptance: `test_m7_reduced_motion_battle_end_readability`; captures
`M7-RV-09-BattleEndReducedMotion` at 576x1024 and 720x1280, plus
`M7-RV-10-BattleEndReducedMotion-HighContrast` at 720x1280.

## Re-review gate

The HOLD closes only when all five named deterministic tests pass; every exact-size
capture exists with manifest/SHA evidence; interaction callbacks and target geometry
pass; and read-only original-resolution UI re-review reports **P0 none / P1 none** for
the corrected states. Any remaining P1 keeps M7 runtime visual approval on HOLD.

This checkpoint is a correction contract only. It claims no implementation, capture,
APK, physical-device result, DriveFS copy, or cloud synchronization.
