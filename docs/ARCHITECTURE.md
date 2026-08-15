# PrintForge Legends architecture

The Godot client is a self-contained offline vertical slice. Immutable catalog data lives in `scripts/core/catalog.gd`; player state contains only stable IDs, integers, schema/catalog versions, and revisions. `BattleRules` uses integer fixed-point element math and accepts intent dictionaries, making it suitable for both local simulation and a TypeScript authority.

Profile schema 2 moves starter selection into pure `ProfileRules` transitions. Fresh profiles intentionally contain no starter inventory and route through `OnboardingState`; a completed selection grants one bound/nontradable creature instance and establishes the initial training team. Schema-1 migration preserves the legacy inventory, identifies an existing Forge Trio creature, and completes onboarding so migration can never create a second starter reward.

Online release contract: Steam tickets authenticate through Nakama; the client submits an intent with match ID and expected revision; an authoritative TypeScript match handler validates it, updates canonical state, and broadcasts a snapshot/event. Clients never award online rewards or settle trades.

Offline mode stores a profile snapshot and append-only operation journal in Godot `user://`. On reconnect, the server merges valid unseen operation IDs idempotently against server revision. A client-controlled offline mode cannot be cheat-proof; suspicious journals can remain solo-only and trading must stay locked until reconciliation.

Trades require Steam-friend or one-time-code pairing, escrow, revision lock, two confirmations, inventory revalidation, and a single PostgreSQL transaction. There is no chat or editable profile text.
