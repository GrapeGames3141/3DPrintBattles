extends Node
## Account state facade. All mutations pass through SaveService journal entries.

signal profile_changed
signal toast_requested(message: String)
var profile: Dictionary = {}

func _ready() -> void:
	profile = SaveService.load_profile()
	if profile.is_empty():
		profile = default_profile()
		SaveService.commit_snapshot(profile)

func default_profile() -> Dictionary:
	return {"schema_version":Catalog.SCHEMA_VERSION,"catalog_version":Catalog.CATALOG_VERSION,"revision":0,"next_instance_nonce":1,"coins":180,"xp":0,"spool_level":3,"blueprints":["cinderpaw","aquafin","voltwig"],"creatures":[{"instance_id":"starter-cinderpaw","creature_id":"cinderpaw","armor_id":""},{"instance_id":"starter-aquafin","creature_id":"aquafin","armor_id":""},{"instance_id":"starter-voltwig","creature_id":"voltwig","armor_id":""}],"armor":[],"discovered":["cinderpaw","aquafin","voltwig"],"team":["starter-cinderpaw","starter-aquafin","starter-voltwig"],"daily_job_count":0,"last_job_day":"","shop":{},"server_revision":0}

func filament_cap() -> int:
	return clampi(int(profile.spool_level), 3, 10)

func earn_coins(amount: int, reason: String) -> void:
	if amount <= 0: return
	profile.coins = int(profile.coins) + amount
	mutated("earn_coins", {"amount":amount,"reason":reason})

func spend_coins(amount: int, reason: String) -> bool:
	if amount <= 0 or int(profile.coins) < amount:
		toast_requested.emit("Not enough Forge Coins.")
		return false
	profile.coins = int(profile.coins) - amount
	mutated("spend_coins", {"amount":amount,"reason":reason})
	return true

func award_battle(win: bool) -> void:
	earn_coins(20 if win else 8, "battle")
	profile.xp = int(profile.xp) + (30 if win else 10)
	if int(profile.xp) >= filament_cap() * 100 and filament_cap() < 10:
		profile.xp = int(profile.xp) - filament_cap() * 100
		profile.spool_level = filament_cap() + 1
		toast_requested.emit("Your filament spool grew to %d!" % filament_cap())
	mutated("battle_reward", {"win":win})

func complete_workshop_job(performance: int) -> int:
	# Non-educational calibration/pattern job: 0..100 performance.
	var reward := clampi(8 + performance / 5, 8, 28)
	earn_coins(reward, "workshop_job")
	return reward

func learn_blueprint(creature_id: String, price: int) -> bool:
	if creature_id in profile.blueprints: return false
	if not spend_coins(price, "blueprint:%s" % creature_id): return false
	profile.blueprints.append(creature_id)
	if not creature_id in profile.discovered: profile.discovered.append(creature_id)
	mutated("learn_blueprint", {"creature_id":creature_id})
	return true

func print_creature(creature_id: String, price: int) -> bool:
	if not creature_id in profile.blueprints or not spend_coins(price, "print:%s" % creature_id): return false
	var instance_id := _next_instance_id(creature_id)
	profile.creatures.append({"instance_id":instance_id,"creature_id":creature_id,"armor_id":""})
	mutated("print_creature", {"creature_id":creature_id,"instance_id":instance_id})
	return true

func print_armor(armor_id: String, price: int) -> bool:
	if _armor_definition(armor_id).is_empty() or not spend_coins(price, "print_armor:%s" % armor_id): return false
	var armor_instance_id := _next_instance_id("armor-%s" % armor_id)
	profile.armor.append({"armor_instance_id":armor_instance_id,"armor_id":armor_id,"equipped_to":""})
	mutated("print_armor", {"armor_id":armor_id,"armor_instance_id":armor_instance_id})
	return true

func equip_armor(creature_instance_id: String, armor_instance_id: String) -> bool:
	var creature: Dictionary = _creature_instance(creature_instance_id)
	var armor: Dictionary = _armor_instance(armor_instance_id)
	if creature.is_empty() or armor.is_empty() or str(armor.equipped_to) != "":
		toast_requested.emit("That creature or armor is not ready to equip.")
		return false
	for existing in profile.armor:
		if str(existing.get("equipped_to", "")) == creature_instance_id: existing.equipped_to = ""
	creature.armor_id = str(armor.armor_id)
	armor.equipped_to = creature_instance_id
	mutated("equip_armor", {"creature_instance_id":creature_instance_id,"armor_instance_id":armor_instance_id})
	return true

func _next_instance_id(prefix: String) -> String:
	var nonce: int = int(profile.get("next_instance_nonce", 1))
	profile.next_instance_nonce = nonce + 1
	var timestamp: int = int(Time.get_unix_time_from_system())
	var revision: int = int(profile.get("revision", 0)) + 1
	return "%s-%d-%d-%d" % [prefix, timestamp, revision, nonce]

func _creature_instance(instance_id: String) -> Dictionary:
	for creature in profile.creatures:
		if str(creature.instance_id) == instance_id: return creature
	return {}

func _armor_instance(instance_id: String) -> Dictionary:
	for armor in profile.armor:
		if str(armor.armor_instance_id) == instance_id: return armor
	return {}

func _armor_definition(armor_id: String) -> Dictionary:
	for armor in Catalog.ARMOR:
		if str(armor.id) == armor_id: return armor
	return {}

func mutated(kind: String, payload: Dictionary) -> void:
	profile.revision = int(profile.revision) + 1
	SaveService.append_event(kind, payload, int(profile.revision))
	SaveService.commit_snapshot(profile)
	profile_changed.emit()
