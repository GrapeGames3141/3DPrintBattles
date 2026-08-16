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

The approved landscape v2 source sheets remain under
`docs/art/source/cards/landscape_v2/` for provenance. Their exact 2x2 native 3:2
quadrants are deterministically assembled into versioned 1536x512 runtime 4x2
atlases in `assets/cards/`; each runtime cell is 384x256. Runtime uses cached
`AtlasTexture` regions; Utility intentionally uses cells 0-5 only. The card back is
a direct texture for private local-versus handoff. No image is decoded or cropped per
frame. Existing primary card costs and values are retained; the modest paired effects
make previously duplicate-looking cards tactically distinct without changing combat
to floating-point arithmetic.

## Presentation contract (0.5.25)

Every support-card context uses one 2:3 portrait silhouette: the archive, Deck
Builder, Forge shop, solo Hand, revealed local-versus Hand, and private local handoff.
The card front is a code-rendered navy/workshop-brass frame with an inset border,
rarity accent, title and separate Filament badge, framed atlas art, rarity/role line,
rules panel, target footer, optional copy count, and a readable legality banner.
Battle and local hands use a horizontal touch carousel rather than changing cards into
landscape tiles; the compact 150x225 tier preserves exact rules and targets. The
private handoff renders only the full portrait back within that same silhouette and is
noninteractive. Native `Button.text` remains empty; tooltip and accessibility names
provide the complete card detail.

Front atlas cells and their `CardArtWindow` are both exact 3:2. Centered containment
therefore fills the window with the complete landscape cell—no crop, side bars, or
letterbox space—while the overall card frame remains canonical 2:3. The private back
remains full-cover because its source image already matches the canonical 2:3 card
silhouette.

Known limit: this milestone supplies code-native labels and English catalog text;
the broader localization pass remains separate.
