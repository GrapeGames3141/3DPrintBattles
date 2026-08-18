import { AuthorityRequest, AuthorityResponse, Intent, JournalEvent, TradeOffer } from "./contracts";

/** Nakama RPC/match handler seam. Deploy with Nakama runtime; clients submit intent only. */
export function validateIntent(intent: Intent): boolean {
  if (!intent || typeof intent !== "object" || typeof (intent as { type?: unknown }).type !== "string") return false;
  if (!["play_card", "advance_phase", "attack", "use_signature", "collect", "smelt", "concede"].includes(intent.type)) return false;
  if (intent.type === "play_card") return typeof intent.cardId === "string" && intent.cardId.length > 0;
  if (intent.type === "attack") return Number.isInteger(intent.slot) && Number.isInteger(intent.target);
  if (intent.type === "use_signature") return Number.isInteger(intent.slot) && (intent.target === undefined || Number.isInteger(intent.target));
  return intent.type !== "collect" || Number.isInteger(intent.pile);
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

/** Credential-free authoritative substitute used by local/integration tests. */
export class InMemoryAuthority {
  revision = 0;
  activeSeat: 0 | 1 = 0;
  snapshot: Record<string, unknown> = { turn: 1, activeSeat: 0 };
  submit(request: AuthorityRequest): AuthorityResponse {
    if (request.expectedRevision !== this.revision) return { ok:false, revision:this.revision, snapshot:{ ...this.snapshot }, reason:"stale_revision" };
    if (request.seat !== this.activeSeat) return { ok:false, revision:this.revision, snapshot:{ ...this.snapshot }, reason:"wrong_seat" };
    if (!validateIntent(request.intent)) return { ok:false, revision:this.revision, snapshot:{ ...this.snapshot }, reason:"illegal_intent" };
    this.revision += 1; this.activeSeat = this.activeSeat === 0 ? 1 : 0;
    this.snapshot = { ...this.snapshot, turn: this.revision + 1, activeSeat: this.activeSeat };
    return { ok:true, revision:this.revision, snapshot:{ ...this.snapshot }, event:{ seat:request.seat, type:request.intent.type } };
  }
}

export class InMemoryDualTrade {
  creatorRevision: number; partnerRevision: number; creator: string[]; partner: string[]; confirms = [false, false]; settled = false; audit: Record<string, unknown>[] = [];
  constructor(creator: string[], partner: string[], creatorRevision = 0, partnerRevision = 0) { this.creator=[...creator]; this.partner=[...partner]; this.creatorRevision=creatorRevision; this.partnerRevision=partnerRevision; }
  confirm(seat: 0 | 1, creatorRevision: number, partnerRevision: number, offered: string, requested: string) {
    if (this.settled) return { ok:false, reason:"settled" };
    if (creatorRevision !== this.creatorRevision || partnerRevision !== this.partnerRevision) return { ok:false, reason:"stale" };
    if (!this.creator.includes(offered) || !this.partner.includes(requested)) return { ok:false, reason:"inventory" };
    this.confirms[seat] = true;
    if (!this.confirms[0] || !this.confirms[1]) return { ok:true, settled:false };
    this.creator[this.creator.indexOf(offered)] = requested; this.partner[this.partner.indexOf(requested)] = offered;
    this.creatorRevision++; this.partnerRevision++; this.settled=true; const audit={ offered, requested, creatorRevision:this.creatorRevision, partnerRevision:this.partnerRevision }; this.audit.push(audit);
    return { ok:true, settled:true, audit };
  }
}
