/** PrintForge Legends v3.1 authority contract. Snapshots are redacted by seat. */
export type Seat = 0 | 1;
export type Intent =
  | { type: "play_card"; cardId: string; target?: number }
  | { type: "upgrade_reprint"; graveyardIndex: number }
  | { type: "cancel_queue"; queueIndex: number }
  | { type: "place_completed"; slot: number; mode: "attack" | "defense" }
  | { type: "attach_completed"; slot: number }
  | { type: "switch_mode"; slot: number; mode: "attack" | "defense" }
  | { type: "activate_ability"; slot: number; target?: number }
  | { type: "attack"; slot: number; target: number }
  | { type: "discard_overflow"; cardIds: string[] }
  | { type: "advance_phase" }
  | { type: "concede" };
export type AuthorityRequest = { seat: Seat; expectedRevision: number; intent: Intent };
export type AuthorityResponse = { ok: boolean; revision: number; snapshot: Record<string, unknown>; event?: { seat: Seat; type: Intent["type"] }; reason?: string };
export type JournalEvent = { operationId: string; kind: string; payload: Record<string, unknown>; revision: number; timestamp: number };
export type TradeOffer = { offerId: string; creatorId: string; partnerId: string; offeredInstanceIds: string[]; requestedInstanceIds: string[]; inventoryRevision: number; creatorConfirmed: boolean; partnerConfirmed: boolean; status: "draft" | "escrowed" | "complete" | "cancelled" };
export type DualRevisionTradeOffer = TradeOffer & { creatorRevision: number; partnerRevision: number; settled: boolean; auditId?: string };
