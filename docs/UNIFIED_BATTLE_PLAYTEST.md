# 0.7 Unified Battle Playtest

This work remains on `feature/unified-card-battle-redesign`; do not merge until a human playtest signs off.

## Start and collection

- Begin on a new isolated profile. Choose one image-led starter, inspect its blue card, then complete the required free Workshop print.
- Buy 3-, 5-, and 10-card packs. A pending reveal survives restart; every pack slot is independently weighted and duplicates are allowed.
- The Library contains owned cards only. The market exposes only available packs. Card inspectors are viewport-sized Card / Stats / Build overlays.
- A battle deck is exactly 15 owned cards, with at least three creature cards and no more than three copies of any card.

## Battles

- Battle proceeds Play -> Attack -> Collect. The player explicitly selects play, equipment, spell, and attack targets; no first available target is inferred.
- Each side has a visible printer and three board slots. A completed print animates from its owner's printer to its slot once; reduced motion presents it instantly.
- Defending prints guard their printer from attacks. Test print queue timing, refill waste at a full spool, collector capacity, smelter/spooler conversion, salvage, and printer destruction.
- Daily Training resolves the current frozen daily contract. Workshop Trial modes resolve the first authored available encounter for the selected named tier; the factory also accepts a specific contract or encounter ID for test/host callers.
- On a Daily or Trial outcome, the unified result key is mode-scoped and invokes the existing Daily Training or Workshop Trial reward claim seam before recording the unified settlement. Replaying the same key returns a duplicate result and grants neither reward twice nor additional card/forge/salvage rewards.

## Accessibility and layout

- Verify landscape and portrait page controls, 125% text, high contrast, and reduced motion from Settings.
- Unified collection and battle screens use grids/pagination rather than gameplay ScrollContainers. Any visible game scrollbar is a playtest failure.

## Current limits

- Unified Daily/Trial launch adapts legacy creature-team and support-card encounter data to the unified 15-card format. It uses the authored team as creature cards, retains catalog IDs from the legacy support deck, then uses a fixed unified support/refill fill. Legacy suit/core tactical effects are metadata only in unified battle.
- Local Versus remains a pass-and-play session and deliberately has no persistent reward settlement.
- The unified shell currently chooses the first available daily contract and each tier's first encounter; selecting a different authored contract/encounter is available through the GameManager factory but does not yet have a dedicated picker in the compact shell.
