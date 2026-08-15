export type Intent = { type: "attack" | "ability" | "defend" | "card" | "switch" | "end_turn" | "concede"; cardId?: string; index?: number };
export type JournalEvent = { operationId: string; kind: string; payload: Record<string, unknown>; revision: number; timestamp: number };
export type TradeOffer = { offerId: string; creatorId: string; partnerId: string; offeredInstanceIds: string[]; requestedInstanceIds: string[]; inventoryRevision: number; creatorConfirmed: boolean; partnerConfirmed: boolean; status: "draft" | "escrowed" | "complete" | "cancelled" };
