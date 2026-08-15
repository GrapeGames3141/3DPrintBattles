class_name LocalTradeAuthority
extends RefCounted
## Credential-free two-profile escrow used only for local demo sessions.

var creator: Dictionary
var partner: Dictionary
var creator_revision: int
var partner_revision: int
var code: String
var offered_id := ""
var requested_id := ""
var creator_confirmed := false
var partner_confirmed := false
var settled := false
var audit: Array = []

static func create(creator_profile: Dictionary, partner_profile: Dictionary, seed: int = 20260814) -> LocalTradeAuthority:
	var session := LocalTradeAuthority.new()
	session.creator = creator_profile.duplicate(true); session.partner = partner_profile.duplicate(true)
	session.creator_revision = int(creator_profile.get("revision", 0)); session.partner_revision = int(partner_profile.get("revision", 0))
	session.code = "GUILD-%04d-%04d" % [seed % 10000, (seed / 97) % 10000]
	return session

func eligible(profile: Dictionary) -> Array:
	var result: Array = []
	for creature in profile.get("creatures", []):
		var id := str(creature.get("instance_id", ""))
		if id.is_empty() or bool(creature.get("bound", false)) or not bool(creature.get("tradable", false)) or not str(creature.get("armor_id", "")).is_empty(): continue
		if id in profile.get("team", []): continue
		result.append(id)
	return result

func choose(creator_instance: String, partner_instance: String) -> Dictionary:
	if settled: return {"ok":false,"error":"This local guild trade is already settled."}
	if not creator_instance in eligible(creator) or not partner_instance in eligible(partner): return {"ok":false,"error":"Choose eligible unequipped printed companions."}
	offered_id = creator_instance; requested_id = partner_instance; creator_confirmed = false; partner_confirmed = false
	return {"ok":true}

func confirm(seat: int, expected_creator_revision: int, expected_partner_revision: int) -> Dictionary:
	if settled: return {"ok":false,"error":"This local guild trade is already settled."}
	if offered_id.is_empty() or requested_id.is_empty(): return {"ok":false,"error":"Choose both companions before confirming."}
	if expected_creator_revision != creator_revision or expected_partner_revision != partner_revision: return {"ok":false,"error":"A profile revision changed; rebuild this trade."}
	if seat == 0: creator_confirmed = true
	elif seat == 1: partner_confirmed = true
	else: return {"ok":false,"error":"Choose a valid guild seat."}
	if not creator_confirmed or not partner_confirmed: return {"ok":true,"settled":false}
	if not offered_id in eligible(creator) or not requested_id in eligible(partner): return {"ok":false,"error":"Trade inventory changed; settlement was refused."}
	_swap()
	settled = true; creator_revision += 1; partner_revision += 1
	audit.append({"kind":"local_trade_settled","code":code,"offered":offered_id,"requested":requested_id,"creator_revision":creator_revision,"partner_revision":partner_revision})
	return {"ok":true,"settled":true,"creator":creator.duplicate(true),"audit":audit.back()}

func _swap() -> void:
	var creator_creature := _take(creator, offered_id)
	var partner_creature := _take(partner, requested_id)
	creator.creatures.append(partner_creature); partner.creatures.append(creator_creature)

func _take(profile: Dictionary, instance_id: String) -> Dictionary:
	for index in profile.creatures.size():
		if str(profile.creatures[index].get("instance_id", "")) == instance_id:
			var row: Dictionary = profile.creatures[index].duplicate(true); profile.creatures.remove_at(index); return row
	return {}
