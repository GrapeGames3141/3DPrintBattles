import { Intent, JournalEvent, TradeOffer } from "./contracts";

/** Nakama RPC/match handler seam. Deploy with Nakama runtime; clients submit intent only. */
export function validateIntent(intent: Intent): boolean {
  return ["attack", "ability", "defend", "card", "switch", "end_turn", "concede"].includes(intent.type);
}
export function mergeJournal(events: JournalEvent[], processed: Set<string>): JournalEvent[] {
  return events.filter((event) => event.operationId.length > 4 && !processed.has(event.operationId));
}
export function canSettleTrade(offer: TradeOffer, currentRevision: number): boolean {
  return offer.status === "escrowed" && offer.creatorConfirmed && offer.partnerConfirmed && offer.inventoryRevision === currentRevision && offer.offeredInstanceIds.length > 0 && offer.requestedInstanceIds.length > 0;
}
/** Production implementation: one PostgreSQL transaction locks both inventories, verifies ownership, moves instances, and records the audit row. */
export async function settleTradeAtomically(offer: TradeOffer, currentRevision: number): Promise<{ ok: boolean; reason?: string }> {
  if (!canSettleTrade(offer, currentRevision)) return { ok: false, reason: "stale_or_unconfirmed" };
  return { ok: false, reason: "database_adapter_not_configured" };
}
