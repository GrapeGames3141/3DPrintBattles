# PrintForge Legends

Steam-first Godot 4.7.1 vertical slice for a cozy, winter-lit magical 3D-print workshop battler. It provides a playable solo battle loop, spatial workshop navigation, blueprint/printing progression, Forge Coins, Forgedex, safe local trade contract, offline journal, 24-creature / 8-rarity catalog, 30 support cards, five complete suit tiers, five optional socketed Cores, and TypeScript Nakama-authority scaffolding.

## Workshop navigation

The Workshop is a spatial, accessible 2D hub rather than a button menu: its five physical-item glow zones move to art-led close-ups, where props open compact Blueprint Trays for the relevant actions. The Printer Bench always exposes a touch- and keyboard-accessible **Choose a Print** control: its station-local tray lists every learned catalog blueprint with idle art, exact print price, and owned count before opening a safe Forge preview. Slow printer and hologram ambient accents are presentation-only, with a static readable frame in reduced-motion mode. Portrait close-ups use cover mapping, bounded horizontal scene panning, and focus-driven prop reveal. The overview selects independent landscape/portrait v3 stage plates as static establishing shots; the focused Printer and Maker stations host the deterministic presentation-only Forge and team displays. Escape closes a tray, returns a close-up to the overview, then returns a launched game screen to its originating close-up. The native-3:2 workshop art and normalized hotspot rationale are documented in `docs/WORKSHOP_NAV_ART.md`.

## First-run flow

New apprentices begin with 180 Forge Coins and no creatures or blueprints. The Awakening Ceremony presents Cinderpaw, Aquafin, and Voltwig with a permanent-choice confirmation. Confirming grants exactly one bound, nontradable starter blueprint and instance, then creates a one-creature training team. Existing schema-1 profiles migrate without removing inventory and are marked complete to prevent a duplicate starter grant.

## Workshop progression

The Collection, Team Builder, Equipment Workbench, Deck Builder, and Extruder Forge are reachable from the Workshop. The Forge takes an explicit day key and produces a deterministic nine-offer rotation: three creature blueprints, two full-suit blueprints, two Core blueprints, and two support cards. Every purchase, print, equip, socket, team save, and deck save is catalog-validated as one offline profile transition. Teams contain one to three unique prints; decks contain exactly 15 owned support cards.

Starter completion owns only the 15 cards needed for the legal starter deck, never the full catalog. The active saved deck is dealt into training matches. An equipped full suit applies its catalog-defined maximum-HP, speed, and guard modifiers; its optional Core supplies one deterministic passive.

## Workshop depth

Calibration Bench now presents three deterministic day-keyed target bands per attempt. Confirming the three selected values calculates an integer distance score and uses the existing capped 8-28 Forge Coin curve; three patterns remain available per day. Print Yard offers one daily choice: Field Practice (+12 account XP), Team Bond (+5 mastery to each saved-team instance), or, at spool capacity 4+, one non-stacking Spool Warmup consumed only after a valid Daily Training or Workshop Trial begins.

Full-suit and Core blueprints print through the same transaction-safe Arcane Forge timing as creatures: ten seconds of layer printing, one raw-completed-part hold, then a completion transfer. Forgedex records base stats, signature, per-instance mastery, inventory and print counts. Five fixed-label deck slots support create, duplicate, rename, activate, and delete; the starter slot remains protected and every active deck remains legal.

Solo Daily Training and Workshop Trials share a catalog-valid launch factory. It uses the saved team and active 15-card deck when they are legal; a stale but repairable team reference temporarily uses deterministic owned prints for that match without changing inventory or saved-team data, while a profile with no catalog-valid owned print receives an exact actionable setup error. Long activity screens use a touch-first scroll container with focus-follow, a low drag threshold, and a 32px visible scrollbar target.

Workshop Trials show the current Team Builder lineup before Start and provide an **Edit Current Team** route. If an older local profile contains only catalog-valid raw species records without usable instance IDs, solo launch uses the matching owned prints temporarily, shows that notice inside the battle screen, and never writes a repaired team, inventory, or deck.

Trial preview and launch now share the same canonical factory lineup. Valid Team Builder order is preserved; the battle boundary also accepts catalog-valid legacy `id`, `species_id`, `creature`, and `species` aliases. If a legacy dictionary construction still cannot validate, the client makes one non-persisting catalog-ID-only retry without an optional loadout and keeps that recovery notice visible in battle. Settings displays the installed review-build label for support checks.

The Android battle boundary keeps alias extraction data-only, then performs its
single existing catalog validation inside `BattleState.make_team()`. This avoids
an exported nested static-helper lookup producing an empty valid team while
preserving catalog validation, suit modifiers, deterministic order, and the
non-persisting retry behavior. The current review label is
`0.5.21-alpha-battle-presentation`. Battle units rest on static idle artwork,
then replay finite tokenized action presentation with a stable 2px atlas inset and
optional transparent elemental/status VFX atlases. Living sheets are repaired
offline before import, so the runtime stage reuses ordinary imported textures
without a component scan or a per-frame texture allocation. The complete battle domain now reads the
immutable `catalog.gd` constants through a preloaded static accessor rather
than the application `Catalog` Node autoload, so battle construction,
normalization, rules, signatures, support cards, and AI share export-safe data
without duplicating authored catalog records.

The Suit Forge and Core Lab use processed transparent raw assets derived from the approved printer source. Each remains seated on the Forge bed during the deterministic ten-second layer reveal and three-second completed-part hold; a suit or Core completes as a transfer, never as a creature awakening.

The Proving Door deliberately separates repeatable Daily Training from five ordered Workshop Trial tiers: **First Layers**, **Element Bench**, **Reinforced Run**, **Masterwork Circuit**, and **Primordial Proof**. Every tier has three fixed encounters and a three-print boss. First clears use an authored integer reward curve and grant coins, account XP, and mastery to every instance in the currently saved team; duplicate claims cannot grant rewards again. A faster replay can improve only its recorded best turn count. Mastery is per printed instance and is shown in Collection, Team Builder, Forgedex, and Trial rewards; it is presentation/progression only and does not alter combat stats in this build.

## Accessibility and battle presentation

Profile settings persist text scale (100%, 125%, or 150%), high contrast, reduced motion, and Apprentice/Craftsman/Master training AI. Controls have 44px minimum targets and status/element information is always written as text. Solo Proving Grounds uses an explicit visible-viewport battle composition instead of a nested scrolling stack: its first-render `Moves` dock is terminal in the portrait flow, so changing battle feedback never moves its four actions below the viewport; Basic Attack, Signature Ability, Defend, and End Turn form a two-column portrait grid (four columns on landscape), and every core target is at least 48px high. Battle units derive their equipped full-suit and optional Core IDs from authoritative inventory before combat and presentation, preserving their exact maximum HP, guard, speed, and Core behavior across snapshots. Arcane Core activation is finite and actor-scoped, including reduced-motion playback. Bench, Hand, Details, and Concede remain compact secondary tabs; expanding them preserves an in-frame action row. Training uses the approved transparent 4x2 creature sheets for a responsive 2D stage: idle frames loop independently of deterministic combat, while legal attacks and abilities select wind-up, strike, recovery, and hit frames. Reduced motion holds frame zero. This is a presentation placeholder; final art and audio remain approval-gated.

Profiles receive an idempotent catalog-valid integrity pass even at the current schema. It repairs only unambiguous aliases and team references that already point to owned inventory; an irreparable team is blocked before battle instead of rendering an Unknown zero-stat unit. Turns one and two are a symmetric setup round: attacks and Signature are visibly disabled for both seats while cards, Defend, and End Turn remain available. The second setup Defend grants a visible 8-shield reply guard; ordinary Defend grants 4.

Save compatibility is explicit: a profile from a schema newer than this build opens read-only with recovery guidance. The client never downgrades, migrates, or writes that future profile; install the newer build or copy the profile and backup before returning to it.

Every catalog creature has a deterministic, catalog-authored Signature profile: an integer base-damage bonus (applied before element and armor) plus one or two fixed effects such as repair, shield, filament, attack buff, debuff/lock, cleanse, or switch discount. The exact derived effect sentence appears in the roster, Forgedex, and battle move dock, and the same data drives combat. Apprentice favors safe basics and survival cards; Craftsman scores legal damage, repair, defense, cards, and switches; Master additionally values lethal lines, element advantage, cooldown utility, and signature disruption. No signature or AI decision uses combat randomness.

The presentation layer reuses imported creature textures and alpha bounds across
screen refreshes. Battle, Forge, and Workshop keep their expensive stage nodes
alive across Main shell rerenders; this does not alter combat, progression,
save, or authority semantics.

Workshop Settings also persist fixed-step Master, Music, and SFX levels with
safe quiet defaults. `AudioDirector` creates only short procedural Godot tones
for Workshop, Battle, Forge, buttons, impacts, and support cards; the visible
sound-cue caption remains the authoritative gameplay feedback. Audio is
non-authoritative, capture-muted, and never changes a rule or reward.

## Arcane Forge printing

Main Printer and Collection printing now enter a transaction-safe Arcane Forge preview. A four-frame Arcane Forge carriage animation runs through a deterministic twelve-second layer print, with the small dormant raw form anchored on the physical build plate. After the one authoritative print transition, it holds visibly for three seconds, then crossfades through restrained cyan/amber magic before the living form takes a short step away. No coins or inventory change while previewing, cancelling, or rendering; exactly one catalog-validated print transition is requested at raw completion. Reduced motion uses calm staged fades and remains skippable. Android uses the launcher icon, workshop splash, and sensor orientation configured for both portrait and landscape. The selected printer and raw forms are recorded in `docs/ART_GENERATION_LEDGER.md`; the living sheets are untouched.

## Run

## Internal alpha local play

The Workshop includes a credential-free Local Versus station and Guild Trade Table. Local Versus submits revisioned, seat-bound intents to a private local authority and hides each hand behind a fixed ready-player handoff. It awards no rewards. The trade table uses a fixed pairing code, dual profile-revision locks, two confirmations, final inventory validation, and a one-settlement latch; only the real local profile persists.

`tests/test_alpha_loop.tscn` is the composed credential-free acceptance path: it starts from onboarding, selects the permanent starter, completes a workshop job, buys and prints Mossmunk through the Arcane Forge commit seam, saves a two-print team and 15-card deck, wins with legal deterministic battle intents, claims one reward, and reloads the isolated snapshot/journal. This internal-alpha loop is complete; Steam, hosted Nakama/PostgreSQL, signing, and approved production art/audio remain external release work.

Open `project.godot` in Godot 4.7.1 or run `tests/test_profile_rules.tscn`, `tests/test_progression_rules.tscn`, and `tests/test_battle_rules.tscn` headlessly. The first run creates only local `user://` save data.

## Scope note

Approved creature concepts, final GLB models/animations, GodotSteam, Nakama SDK/runtime deployment, Steam App ID, and production art/audio are intentionally not bundled. The procedural UI makes the vertical slice runnable without credentials or unapproved final assets.

## 0.6.3 opponent diversity review

Daily Training contracts now use data-driven band policies for rating, suit and
Core coverage, counter behavior, tactics, starting filament, and offense
preference. The contract preview and result panel show living rival portraits,
equipment, tactics, and claim/practice state. A deterministic diversity pass
prevents repeated same-day rival lineups when legal alternatives exist and
prefers no more than one reused creature across the three 3-unit contracts.

The final paired 600-match audit recorded Apprentice/Circuit/Master win rates
of **68% / 59% / 44%**, a **2pp** opening-seat delta, and **0** stalls. Band
rows B1–B5 were **55/42/55**, **67/62/37**, **60/67/37**, **75/70/40**, and
**82/52/50** respectively (Apprentice/Circuit/Master); each is within its
published contract tolerance. The 38-scene retained suite passed 38/38.

Reviewed responsive captures are retained outside the repository at
`E:/CodexCache/printforge-validation/proving_576x1024_opponent-diversity.png`,
`proving_1280x720_opponent-diversity.png`,
`training_result_576x1024_opponent-final.png`, and
`training_result_1280x720_opponent-final.png`. The Android review artifact is
`build/android/PrintForge-Legends-0.6.3-opponent-diversity-arm64.apk`; its
verified size is 145,019,387 bytes and SHA-256 is
`5F68E8518CD73A40F6028F7A90990AA09BD56CE1DC0A48B14F41EA6064841090`.
Package, signing, ABI, and export-exclusion verification is recorded in
`docs/VALIDATION.md`.
