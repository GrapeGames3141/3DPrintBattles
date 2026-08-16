# PrintForge Legends

Steam-first Godot 4.7.1 vertical slice for a cozy, winter-lit magical 3D-print workshop battler. It provides a playable solo battle loop, spatial workshop navigation, blueprint/printing progression, Forge Coins, Forgedex, safe local trade contract, offline journal, 24-creature / 8-rarity catalog, 30 support cards, 7 armor definitions, and TypeScript Nakama-authority scaffolding.

## Workshop navigation

The Workshop is a spatial, accessible 2D hub rather than a button menu: its five physical-item glow zones move to art-led close-ups, where props open compact Blueprint Trays for the relevant actions. The Printer Bench always exposes a touch- and keyboard-accessible **Choose a Print** control: its station-local tray lists every learned catalog blueprint with idle art, exact print price, and owned count before opening a safe Forge preview. Slow printer and hologram ambient accents are presentation-only, with a static readable frame in reduced-motion mode. Portrait close-ups use cover mapping, bounded horizontal scene panning, and focus-driven prop reveal. The overview selects independent landscape/portrait v3 stage plates as static establishing shots; the focused Printer and Maker stations host the deterministic presentation-only Forge and team displays. Escape closes a tray, returns a close-up to the overview, then returns a launched game screen to its originating close-up. The native-3:2 workshop art and normalized hotspot rationale are documented in `docs/WORKSHOP_NAV_ART.md`.

## First-run flow

New apprentices begin with 180 Forge Coins and no creatures or blueprints. The Awakening Ceremony presents Cinderpaw, Aquafin, and Voltwig with a permanent-choice confirmation. Confirming grants exactly one bound, nontradable starter blueprint and instance, then creates a one-creature training team. Existing schema-1 profiles migrate without removing inventory and are marked complete to prevent a duplicate starter grant.

## Workshop progression

The Collection, Team Builder, Armor Workbench, Deck Builder, and Extruder Forge are reachable from the Workshop. The Forge takes an explicit day key and produces a deterministic seven-offer rotation: three creature blueprints, two armor blueprints, and two support cards. Every purchase, print, equip, team save, and deck save is catalog-validated as one offline profile transition. Teams contain one to three unique prints; decks contain exactly 15 owned support cards.

Starter completion owns only the 15 cards needed for the legal starter deck, never the full catalog. The active saved deck is dealt into training matches. Equipped armor applies its catalog-defined maximum-HP, speed, and guard modifiers to the training loadout.

## Workshop depth

Calibration Bench now presents three deterministic day-keyed target bands per attempt. Confirming the three selected values calculates an integer distance score and uses the existing capped 8-28 Forge Coin curve; three patterns remain available per day. Print Yard offers one daily choice: Field Practice (+12 account XP), Team Bond (+5 mastery to each saved-team instance), or, at spool capacity 4+, one non-stacking Spool Warmup consumed only after a valid Daily Training or Workshop Trial begins.

Armor blueprints print through the same transaction-safe Arcane Forge timing as creatures: ten seconds of layer printing, one raw-completed-part hold, then an armor-only completion transfer. Forgedex records base stats, signature, per-instance mastery, inventory and print counts. Five fixed-label deck slots support create, duplicate, rename, activate, and delete; the starter slot remains protected and every active deck remains legal.

The Proving Door deliberately separates repeatable Daily Training from five ordered Workshop Trial tiers: **First Layers**, **Element Bench**, **Reinforced Run**, **Masterwork Circuit**, and **Primordial Proof**. Every tier has three fixed encounters and a three-print boss. First clears use an authored integer reward curve and grant coins, account XP, and mastery to every instance in the currently saved team; duplicate claims cannot grant rewards again. A faster replay can improve only its recorded best turn count. Mastery is per printed instance and is shown in Collection, Team Builder, Forgedex, and Trial rewards; it is presentation/progression only and does not alter combat stats in this build.

## Accessibility and battle presentation

Profile settings persist text scale (100%, 125%, or 150%), high contrast, reduced motion, and Apprentice/Craftsman/Master training AI. Controls have 44px minimum targets and status/element information is always written as text. Solo Proving Grounds uses an explicit visible-viewport battle composition instead of a nested scrolling stack: its first-render `Moves` dock sits directly below the stage, Basic Attack, Signature Ability, Defend, and End Turn form a two-column portrait grid (four columns on landscape), and every core target is at least 48px high. Battle units are normalized from their catalog and equipped-armor IDs before combat and presentation, so older local snapshots that retain only IDs, runtime HP, and an armor ID preserve their equipped maximum HP while still showing the same actions, player summary, and deterministic combat behavior. Bench, Hand, Details, and Concede remain compact secondary tabs; expanding them preserves an in-frame action row. Training uses the approved transparent 4x2 creature sheets for a responsive 2D stage: idle frames loop independently of deterministic combat, while legal attacks and abilities select wind-up, strike, recovery, and hit frames. Reduced motion holds frame zero. This is a presentation placeholder; final art and audio remain approval-gated.

Profiles receive an idempotent catalog-valid integrity pass even at the current schema. It repairs only unambiguous aliases and team references that already point to owned inventory; an irreparable team is blocked before battle instead of rendering an Unknown zero-stat unit. On a player-owned opening turn, Basic Attack and Signature are visibly disabled while Defend and End Turn remain available.

Every catalog creature has a deterministic, catalog-authored Signature profile: an integer base-damage bonus (applied before element and armor) plus one or two fixed effects such as repair, shield, filament, attack buff, debuff/lock, cleanse, or switch discount. The exact derived effect sentence appears in the roster, Forgedex, and battle move dock, and the same data drives combat. Apprentice favors safe basics and survival cards; Craftsman scores legal damage, repair, defense, cards, and switches; Master additionally values lethal lines, element advantage, cooldown utility, and signature disruption. No signature or AI decision uses combat randomness.

The presentation layer reuses imported creature textures and alpha bounds across
screen refreshes. Battle, Forge, and Workshop keep their expensive stage nodes
alive across Main shell rerenders; this does not alter combat, progression,
save, or authority semantics.

## Arcane Forge printing

Main Printer and Collection printing now enter a transaction-safe Arcane Forge preview. A four-frame Arcane Forge carriage animation runs through a deterministic twelve-second layer print, with the small dormant raw form anchored on the physical build plate. After the one authoritative print transition, it holds visibly for three seconds, then crossfades through restrained cyan/amber magic before the living form takes a short step away. No coins or inventory change while previewing, cancelling, or rendering; exactly one catalog-validated print transition is requested at raw completion. Reduced motion uses calm staged fades and remains skippable. Android uses the launcher icon, workshop splash, and sensor orientation configured for both portrait and landscape. The selected printer and raw forms are recorded in `docs/ART_GENERATION_LEDGER.md`; the living sheets are untouched.

## Run

## Internal alpha local play

The Workshop includes a credential-free Local Versus station and Guild Trade Table. Local Versus submits revisioned, seat-bound intents to a private local authority and hides each hand behind a fixed ready-player handoff. It awards no rewards. The trade table uses a fixed pairing code, dual profile-revision locks, two confirmations, final inventory validation, and a one-settlement latch; only the real local profile persists.

`tests/test_alpha_loop.tscn` is the composed credential-free acceptance path: it starts from onboarding, selects the permanent starter, completes a workshop job, buys and prints Mossmunk through the Arcane Forge commit seam, saves a two-print team and 15-card deck, wins with legal deterministic battle intents, claims one reward, and reloads the isolated snapshot/journal. This internal-alpha loop is complete; Steam, hosted Nakama/PostgreSQL, signing, and approved production art/audio remain external release work.

Open `project.godot` in Godot 4.7.1 or run `tests/test_profile_rules.tscn`, `tests/test_progression_rules.tscn`, and `tests/test_battle_rules.tscn` headlessly. The first run creates only local `user://` save data.

## Scope note

Approved creature concepts, final GLB models/animations, GodotSteam, Nakama SDK/runtime deployment, Steam App ID, and production art/audio are intentionally not bundled. The procedural UI makes the vertical slice runnable without credentials or unapproved final assets.
