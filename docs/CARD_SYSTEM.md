# Offline Support Cards

Support cards use stable catalog IDs and require no profile or save-schema migration.
Every legal deck has exactly 15 cards. A battle deals an opening hand of four, has a
hand cap of four, and draws one normal card at the start of a turn only when below
that cap. Decks exhaust without a reshuffle at this checkpoint. Playing a legal
card is a non-turn-ending tactical action: its Filament cost is paid, the card moves
from hand to runtime-only discard, then its ordered integer effects resolve.

`SupportCardRules` is the shared rules/presentation seam. It normalizes legacy
`effect`/`amount` entries into ordered `effects`, supplies exact target/rules text,
legality feedback and deterministic AI utility. Targets are Your Forge (Filament,
draw), Your team (switch discount), Your active print (heal/shield/buff/cooldown/
cleanse), or Foe active print (debuff). Multi-target cards enumerate their effects.

The approved source atlases are copied unchanged to `assets/cards/` for runtime and
`docs/art/source/cards/` for provenance. Runtime uses cached normalized 4x2
`AtlasTexture` regions; Utility intentionally uses cells 0-5 only. The card back is
a direct texture for private local-versus handoff. No image is decoded or cropped per
frame. Existing primary card costs and values are retained; the modest paired effects
make previously duplicate-looking cards tactically distinct without changing combat
to floating-point arithmetic.

Known limit: this milestone supplies code-native labels and English catalog text;
the broader localization pass remains separate.
