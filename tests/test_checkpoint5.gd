extends Node
var failures: Array[String] = []
func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)
func _ready() -> void:
	var authority := LocalBattleAuthority.create(["cinderpaw"], ["mossmunk"], BattleState.STARTER_LOADOUT, 2)
	require(not authority.submit({"seat":1,"expected_revision":0,"intent":{"type":"defend"}}).ok, "wrong seat is rejected")
	require(not authority.submit({"seat":0,"expected_revision":0,"intent":{"type":"unknown"}}).ok and authority.revision == 0, "illegal intent is immutable")
	var accepted := authority.submit({"seat":0,"expected_revision":0,"intent":{"type":"defend"}})
	accepted.snapshot.players[0].filament = 99
	require(bool(accepted.ok) and authority.revision == 1 and int(authority.state.players[0].filament) != 99 and not authority.submit({"seat":1,"expected_revision":0,"intent":{"type":"defend"}}).ok, "authority snapshot is defensive and stale is rejected")
	var a: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	var b: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "aquafin").profile
	a.creatures.append({"instance_id":"trade-a","creature_id":"mossmunk","bound":false,"tradable":true,"suit_instance_id":""})
	b.creatures.append({"instance_id":"trade-b","creature_id":"voltwig","bound":false,"tradable":true,"suit_instance_id":""})
	a.creatures.append({"instance_id":"bound","creature_id":"mossmunk","bound":true,"tradable":false,"suit_instance_id":""})
	a.creatures.append({"instance_id":"nontradable","creature_id":"mossmunk","bound":false,"tradable":false,"suit_instance_id":""})
	a.creatures.append({"instance_id":"suited","creature_id":"mossmunk","bound":false,"tradable":true,"suit_instance_id":"trade-suit"})
	a.suits.append({"suit_instance_id":"trade-suit","tier_id":"standard","equipped_to":"suited","socketed_core_id":""})
	a.creatures.append({"instance_id":"team","creature_id":"mossmunk","bound":false,"tradable":true,"suit_instance_id":""}); a.team.append("team")
	var trade := LocalTradeAuthority.create(a, b, 20260814)
	require(not bool(trade.choose("bound", "trade-b").ok) and not bool(trade.choose("nontradable", "trade-b").ok) and not bool(trade.choose("team", "trade-b").ok), "bound, nontradable, and team prints are ineligible")
	require(bool(trade.choose("trade-a", "trade-b").ok), "eligible local escrow draft")
	require(not bool(trade.confirm(0, 1, 0).ok) and not bool(trade.confirm(0, 0, 1).ok) and bool(trade.confirm(0, 0, 0).ok) and not trade.settled, "both stale revisions reject")
	var settlement := trade.confirm(1, 0, 0)
	require(bool(settlement.ok) and trade.settled and trade.audit.size() == 1 and str(trade.creator.creatures.back().instance_id) == "trade-b" and str(trade.partner.creatures.back().instance_id) == "trade-a" and not bool(trade.confirm(0, 1, 1).ok), "second confirmation swaps exact IDs once and latches")
	if failures.is_empty(): print("PASS: checkpoint5 local authority and escrow")
	call_deferred("finish")
func finish() -> void: get_tree().quit(0 if failures.is_empty() else 1)
