class_name TradeService
extends RefCounted
## Server escrow contract; no transfer takes place locally.
static func make_offer(offered_ids: Array, requested_ids: Array, inventory_revision: int) -> Dictionary:
	return {"offer_id":"","offered_instance_ids":offered_ids,"requested_instance_ids":requested_ids,"inventory_revision":inventory_revision,"creator_confirmed":false,"partner_confirmed":false,"status":"draft"}
static func can_confirm(offer: Dictionary) -> bool:
	return offer.status == "escrowed" and not offer.offered_instance_ids.is_empty() and not offer.requested_instance_ids.is_empty()
