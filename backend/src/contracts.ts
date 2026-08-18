/** Mirrors the 0.7 Godot authority boundary.  Every target is explicit so the
 * server can reject stale/hidden client state without inferring UI intent. */
export type Intent =
  | { type: "play_card"; cardId: string; slot?: number; target?: number }
  | { type: "advance_phase" }
  | { type: "attack"; slot: number; target?: number }
  | { type: "use_signature"; slot: number; target?: number }
  | { type: "collect"; pile: number }
  | { type: "smelt" }
  | { type: "concede" };
export type AuthorityRequest = { seat: 0 | 1; expectedRevision: number; intent: Intent };
export type AuthorityResponse = { ok: boolean; revision: number; snapshot: Record<string, unknown>; event?: { seat: number; type: Intent["type"] }; reason?: string };
export type JournalEvent = { operationId: string; kind: string; payload: Record<string, unknown>; revision: number; timestamp: number };
export type TradeOffer = { offerId: string; creatorId: string; partnerId: string; offeredInstanceIds: string[]; requestedInstanceIds: string[]; inventoryRevision: number; creatorConfirmed: boolean; partnerConfirmed: boolean; status: "draft" | "escrowed" | "complete" | "cancelled" };
export type DualRevisionTradeOffer = TradeOffer & { creatorRevision: number; partnerRevision: number; settled: boolean; auditId?: string };
