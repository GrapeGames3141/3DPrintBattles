# PrintForge Legends architecture

The Godot client is a self-contained offline vertical slice. Immutable catalog data lives in `scripts/core/catalog.gd`; player state contains only stable IDs, integers, schema/catalog versions, and revisions. `BattleRules` uses integer fixed-point element math and accepts intent dictionaries, making it suitable for both local simulation and a TypeScript authority.

Profile schema 3 keeps starter selection in pure `ProfileRules` transitions and moves collection/economy actions to `ProgressionRules`. Fresh profiles intentionally contain no starter inventory and route through `OnboardingState`; a completed selection grants one bound/nontradable creature instance, a legal 15-card starter deck, and the initial training team. Migration preserves legacy inventory and idempotently adds armor blueprints, counted support cards, saved decks/active deck ID, and the cached daily-shop record.

`ProgressionRules` is deliberately file-free: it validates catalog IDs, integer coin balances, atomic blueprint/printing/equip/team/deck transitions, and a deterministic explicit-`YYYY-MM-DD` shop rotation. `GameManager` is the only facade that persists an accepted result, increments revision, and appends the operation journal. Thus a rejected action cannot deduct coins or create a journal record. Battle state accepts an optional supplied deck while retaining default starter-deck callers. Armor has a saved equip loop now; applying its stats in combat is deferred to combat balance work.

Online release contract: Steam tickets authenticate through Nakama; the client submits an intent with match ID and expected revision; an authoritative TypeScript match handler validates it, updates canonical state, and broadcasts a snapshot/event. Clients never award online rewards or settle trades.

Offline mode stores a profile snapshot and append-only operation journal in Godot `user://`. On reconnect, the server merges valid unseen operation IDs idempotently against server revision. A client-controlled offline mode cannot be cheat-proof; suspicious journals can remain solo-only and trading must stay locked until reconciliation.

Trades require Steam-friend or one-time-code pairing, escrow, revision lock, two confirmations, inventory revalidation, and a single PostgreSQL transaction. There is no chat or editable profile text.
