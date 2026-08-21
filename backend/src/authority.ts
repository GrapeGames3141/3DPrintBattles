import { AuthorityRequest, AuthorityResponse, Intent, JournalEvent, TradeOffer, Seat } from "./contracts";

const PHASES = ["draw", "main", "print", "attack", "collect"] as const;
/** Shape validation is intentionally strict: no inferred targets, no UI fields. */
export function validateIntent(intent: Intent): boolean {
  if (!intent || typeof intent !== "object" || typeof (intent as {type?:unknown}).type !== "string") return false;
  switch (intent.type) {
    case "play_card": return typeof intent.cardId === "string" && intent.cardId.length > 0 && (intent.target === undefined || Number.isInteger(intent.target));
    case "upgrade_reprint": return Number.isInteger(intent.graveyardIndex) && intent.graveyardIndex >= 0;
    case "cancel_queue": return Number.isInteger(intent.queueIndex) && intent.queueIndex >= 0;
    case "place_completed": case "switch_mode": return Number.isInteger(intent.slot) && intent.slot >= 0 && intent.slot < 3 && (intent.mode === "attack" || intent.mode === "defense");
    case "attach_completed": return Number.isInteger(intent.slot) && intent.slot >= 0 && intent.slot < 3;
    case "activate_ability": return Number.isInteger(intent.slot) && (intent.target === undefined || Number.isInteger(intent.target));
    case "attack": return Number.isInteger(intent.slot) && Number.isInteger(intent.target);
    case "discard_overflow": return Array.isArray(intent.cardIds) && intent.cardIds.every(card => typeof card === "string");
    case "advance_phase": case "concede": return true;
  }
}
export function mergeJournal(events: JournalEvent[], processed: Set<string>): JournalEvent[] { return events.filter(event => event.operationId.length > 4 && !processed.has(event.operationId)); }
export function canSettleTrade(offer: TradeOffer, currentRevision: number): boolean { return offer.status === "escrowed" && offer.creatorConfirmed && offer.partnerConfirmed && offer.inventoryRevision === currentRevision && offer.offeredInstanceIds.length > 0 && offer.requestedInstanceIds.length > 0; }
export async function settleTradeAtomically(offer: TradeOffer, currentRevision: number): Promise<{ok:boolean;reason?:string}> { return canSettleTrade(offer,currentRevision) ? {ok:false,reason:"database_adapter_not_configured"} : {ok:false,reason:"stale_or_unconfirmed"}; }

/** Credential-free v3 boundary used by contract tests. Production replaces this
 * transition seam with shared rules fixtures and a transactional match store. */
export class InMemoryAuthority {
  revision = 0; activeSeat: Seat = 0; snapshot: Record<string,unknown> = {schema:"v3.1",turn:1,phase:"draw",activeSeat:0,players:[{printer:{hp:2000,maxHp:2000}},{printer:{hp:2000,maxHp:2000}}]};
  submit(request: AuthorityRequest): AuthorityResponse {
    const before = structuredClone(this.snapshot);
    if (request.expectedRevision !== this.revision) return this.reject("stale_revision",before);
    if (request.seat !== this.activeSeat) return this.reject("wrong_seat",before);
    if (!validateIntent(request.intent)) return this.reject("illegal_intent",before);
    if (request.intent.type === "concede") { this.snapshot={...this.snapshot,finished:true,winner:this.activeSeat===0?1:0}; return this.accept(request); }
    if (request.intent.type === "advance_phase") {
      const current = String(this.snapshot.phase); const index = PHASES.indexOf(current as typeof PHASES[number]);
      if (index === PHASES.length - 1) { this.activeSeat=this.activeSeat===0?1:0; this.snapshot={...this.snapshot,turn:Number(this.snapshot.turn)+1,phase:"draw",activeSeat:this.activeSeat}; }
      else this.snapshot={...this.snapshot,phase:PHASES[Math.max(0,index+1)]};
    }
    return this.accept(request);
  }
  private accept(request: AuthorityRequest): AuthorityResponse { this.revision++; return {ok:true,revision:this.revision,snapshot:structuredClone(this.snapshot),event:{seat:request.seat,type:request.intent.type}}; }
  private reject(reason:string,snapshot:Record<string,unknown>): AuthorityResponse { return {ok:false,revision:this.revision,snapshot,reason}; }
}
export class InMemoryDualTrade {
  creatorRevision:number; partnerRevision:number; creator:string[]; partner:string[]; confirms=[false,false]; settled=false; audit:Record<string,unknown>[]=[];
  constructor(creator:string[],partner:string[],creatorRevision=0,partnerRevision=0){this.creator=[...creator];this.partner=[...partner];this.creatorRevision=creatorRevision;this.partnerRevision=partnerRevision;}
  confirm(seat:Seat,creatorRevision:number,partnerRevision:number,offered:string,requested:string){if(this.settled)return{ok:false,reason:"settled"};if(creatorRevision!==this.creatorRevision||partnerRevision!==this.partnerRevision)return{ok:false,reason:"stale"};if(!this.creator.includes(offered)||!this.partner.includes(requested))return{ok:false,reason:"inventory"};this.confirms[seat]=true;if(!this.confirms[0]||!this.confirms[1])return{ok:true,settled:false};this.creator[this.creator.indexOf(offered)]=requested;this.partner[this.partner.indexOf(requested)]=offered;this.creatorRevision++;this.partnerRevision++;this.settled=true;const audit={offered,requested,creatorRevision:this.creatorRevision,partnerRevision:this.partnerRevision};this.audit.push(audit);return{ok:true,settled:true,audit};}
}
