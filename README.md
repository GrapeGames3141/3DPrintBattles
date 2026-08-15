# PrintForge Legends

Steam-first Godot 4.7.1 vertical slice for a cozy, winter-lit magical 3D-print workshop battler. It provides a playable solo battle loop, workshop navigation, blueprint/printing progression, Forge Coins, Forgedex, safe local trade contract, offline journal, 24-creature / 8-rarity catalog, 30 support cards, 7 armor definitions, and TypeScript Nakama-authority scaffolding.

## First-run flow

New apprentices begin with 180 Forge Coins and no creatures or blueprints. The Awakening Ceremony presents Cinderpaw, Aquafin, and Voltwig with a permanent-choice confirmation. Confirming grants exactly one bound, nontradable starter blueprint and instance, then creates a one-creature training team. Existing schema-1 profiles migrate without removing inventory and are marked complete to prevent a duplicate starter grant.

## Workshop progression

The Collection, Team Builder, Armor Workbench, Deck Builder, and Extruder Forge are reachable from the Workshop. The Forge takes an explicit day key and produces a deterministic seven-offer rotation: three creature blueprints, two armor blueprints, and two support cards. Every purchase, print, equip, team save, and deck save is catalog-validated as one offline profile transition. Teams contain one to three unique prints; decks contain exactly 15 owned support cards.

Starter completion owns only the 15 cards needed for the legal starter deck, never the full catalog. The active saved deck is dealt into training matches. Equipped armor applies its catalog-defined maximum-HP, speed, and guard modifiers to the training loadout.

## Accessibility and battle presentation

Profile settings persist text scale (100%, 125%, or 150%), high contrast, reduced motion, and Apprentice/Craftsman/Master training AI. Controls have 44px minimum targets and status/element information is always written as text. Training uses the approved transparent 4x2 creature sheets for a responsive 2D stage: idle frames loop independently of deterministic combat, while legal attacks and abilities select wind-up, strike, recovery, and hit frames. Reduced motion holds frame zero. This is a presentation placeholder; final art and audio remain approval-gated.

## Run

## Internal alpha local play

The Workshop includes a credential-free Local Versus station and Guild Trade Table. Local Versus submits revisioned, seat-bound intents to a private local authority and hides each hand behind a fixed ready-player handoff. It awards no rewards. The trade table uses a fixed pairing code, dual profile-revision locks, two confirmations, final inventory validation, and a one-settlement latch; only the real local profile persists.

Open `project.godot` in Godot 4.7.1 or run `tests/test_profile_rules.tscn`, `tests/test_progression_rules.tscn`, and `tests/test_battle_rules.tscn` headlessly. The first run creates only local `user://` save data.

## Scope note

Approved creature concepts, final GLB models/animations, GodotSteam, Nakama SDK/runtime deployment, Steam App ID, and production art/audio are intentionally not bundled. The procedural UI makes the vertical slice runnable without credentials or unapproved final assets.
