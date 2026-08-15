export type Intent = { type: "attack" | "ability" | "defend" | "card" | "switch" | "end_turn" | "concede"; cardId?: string; index?: number };
export type AuthorityRequest = { seat: 0 | 1; expectedRevision: number; intent: Intent };
export type AuthorityResponse = { ok: boolean; revision: number; snapshot: Record<string, unknown>; event?: { seat: number; type: Intent["type"] }; reason?: string };
export type JournalEvent = { operationId: string; kind: string; payload: Record<string, unknown>; revision: number; timestamp: number };
export type TradeOffer = { offerId: string; creatorId: string; partnerId: string; offeredInstanceIds: string[]; requestedInstanceIds: string[]; inventoryRevision: number; creatorConfirmed: boolean; partnerConfirmed: boolean; status: "draft" | "escrowed" | "complete" | "cancelled" };
export type DualRevisionTradeOffer = TradeOffer & { creatorRevision: number; partnerRevision: number; settled: boolean; auditId?: string };
