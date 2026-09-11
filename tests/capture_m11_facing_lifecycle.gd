extends Node
## Real Main/coordinator receipt proof for both seats. The optional Voltwig
## fixture verifies the explicit legacy exception without calling it directional.
const MAIN := preload("res://scenes/main.tscn")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")
const FACING := preload("res://scripts/ui/battle_facing_sprite_cache.gd")
var failures: Array[String] = []
var width := 576
var height := 1024
var fixture_creature := ""
var text_scale_bps := 10000
var high_contrast := false
var reduced_motion := false

func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func _deck(card_id: String) -> Array:
	var deck: Array = []
	for _index in 40: deck.append(card_id)
	return deck

func _save_capture(image: Image, stem: String, metadata: Dictionary) -> void:
	var path := SaveService.profile_path.get_base_dir().path_join("%s-%dx%d.png" % [stem, width, height])
	require(image != null and image.save_png(path) == OK, "%s rendered capture saved" % stem)
	var metadata_file := FileAccess.open(path.get_basename() + ".json", FileAccess.WRITE)
	require(metadata_file != null, "%s metadata sidecar opened" % stem)
	if metadata_file != null:
		metadata_file.store_string(JSON.stringify(metadata, "\t"))
		metadata_file.close()
	print("M11_FACING_CAPTURE stem=%s path=%s metadata=%s" % [stem, path, path.get_basename() + ".json"])

func _await_presented_frame() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame

func _dispose_shell(shell: Node) -> void:
	# Exercise Main's real leave path first: its generation invalidation makes any
	# already deferred coordinator/AI continuation stale before node teardown.
	if shell.has_method("_leave_unified_battle"):
		shell.call("_leave_unified_battle")
	for _frame in 4:
		await get_tree().process_frame
	shell.queue_free()
	# Main's stage is reattached/deferred by receipt acknowledgement. Let the
	# scene-tree delete queue and its submitted GPU frame retire before the test
	# terminates, rather than leaving a nondeterministic ObjectDB instance at exit.
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	for _frame in 4:
		await get_tree().process_frame

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2: width = int(args[0]); height = int(args[1])
	for arg in args.slice(2):
		var option := str(arg)
		if option.begins_with("--fixture="):
			fixture_creature = option.trim_prefix("--fixture=")
		elif option.begins_with("--text-scale-bps="):
			text_scale_bps = int(option.trim_prefix("--text-scale-bps="))
		elif option == "--high-contrast":
			high_contrast = true
		elif option == "--reduced-motion":
			reduced_motion = true
	if not fixture_creature.is_empty():
		require(FACING.has_interim_coverage(fixture_creature), "Optional lifecycle fixture %s has explicit approved interim coverage." % fixture_creature)
	var evidence := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	var qa_root := SaveService.profile_path.get_base_dir().replace("\\", "/")
	if not qa_root.begins_with(evidence + "/") or DisplayServer.get_name().to_lower() == "headless":
		require(false, "Facing lifecycle requires rendered Main with pre-autoload isolated evidence QA storage.")
		get_tree().quit(1)
		return
	for seat in [0, 1]: await _capture_seat(seat)
	for actor in [0, 1]: await _capture_attack(actor)
	if failures.is_empty(): print("PASS: M11 facing lifecycle captures both coordinator seats for %s" % (fixture_creature if not fixture_creature.is_empty() else "directional representatives"))
	get_tree().quit(0 if failures.is_empty() else 1)

func _capture_seat(seat: int) -> void:
	get_window().content_scale_size = Vector2i(width, height); get_window().size = Vector2i(width, height)
	GameManager.profile = RULES.new_profile(); GameManager.profile.settings = {"text_scale_bps":text_scale_bps,"high_contrast":high_contrast,"reduced_motion":reduced_motion}
	var friendly_card := _card_for_seat(seat)
	var enemy_card := _card_for_seat(1 - seat)
	var deck := _deck(friendly_card)
	var state := STATE.create(deck, deck, 1700 + seat); state.active_seat = seat; state.phase = "print"; state.turn = 2
	state.player(seat).queue = [{"card_id":friendly_card, "remaining":1,"target":0,"mode":"attack","cost":70,"job_id":"facing-%d" % seat}]
	var opponent := 1 - seat
	state.player(opponent).slots[0] = STATE._unit(RULES.card(enemy_card))
	# Training fixes the viewer at seat 0.  Unlike local hotseat (where Main
	# remaps an active seat-1 player to the lower physical presentation seat), it
	# proves each authority seat's actual front/rear battle-facing row.
	var shell := MAIN.instantiate(); shell.screen="unified_battle"; shell.battle=state; shell.battle_mode="training"; shell.unified_battle_coordinator.configure(state, 0); add_child(shell)
	await get_tree().process_frame
	var accepted: Dictionary = shell.unified_battle_coordinator.submit_checked(shell.unified_battle_coordinator.envelope(seat,{"type":"advance_phase"}),shell.unified_battle_coordinator.generation)
	var receipt: Dictionary = accepted.get("receipt",{})
	require(bool(accepted.get("ok",false)) and not receipt.is_empty(), "seat %d produces a legal coordinator print receipt" % seat)
	shell._present_unified_battle_event(receipt); shell.render(); await get_tree().create_timer(.46).timeout
	var stage := shell.find_child("PhysicalBattlefieldStage",true,false) as PhysicalBattlefieldStage
	var raw := stage.find_child("BattlePrinterSolidRaw%d" % seat,true,false) as TextureRect if stage != null else null
	var image: Image
	if not reduced_motion:
		require(stage != null and raw != null and raw.visible, "seat %d real print owns its raw facing silhouette" % seat)
		image = get_viewport().get_texture().get_image()
		_save_capture(image, "m11-facing-seat%d-print" % seat, {"kind":"print_raw","seat":seat,"receipt_serial":int(receipt.get("serial",-1)),"fixture":fixture_creature,"width":width,"height":height})
	var deadline := Time.get_ticks_msec() + 3000
	while shell.unified_battle_coordinator.presentation_active and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		await get_tree().create_timer(.02).timeout
	require(not shell.unified_battle_coordinator.presentation_active, "seat %d presentation settles within three seconds" % seat)
	# The acknowledgement queues Main's final native render.  A process frame alone
	# can still read the preceding raw-print GPU frame, so read only after it lands.
	await _await_presented_frame()
	stage = shell.find_child("PhysicalBattlefieldStage",true,false) as PhysicalBattlefieldStage
	var friendly := stage.find_child("LivingPrintSlot%d" % (seat * 3),true,false) as TextureRect if stage != null else null
	var enemy := stage.find_child("LivingPrintSlot%d" % (opponent * 3),true,false) as TextureRect if stage != null else null
	var friendly_caption := stage.find_child("LivingPrintCaption%d" % (seat * 3),true,false) as Label if stage != null else null
	var enemy_caption := stage.find_child("LivingPrintCaption%d" % (opponent * 3),true,false) as Label if stage != null else null
	require(friendly != null and enemy != null and friendly.visible and enemy.visible and friendly_caption != null and enemy_caption != null and friendly_caption.visible and enemy_caption.visible and friendly_caption.text.to_lower().contains(friendly_card) and enemy_caption.text.to_lower().contains(enemy_card), "seat %d settled board shows both legal living units with their final authoritative identities after the presentation acknowledgement" % seat)
	var expected_y := int(FACING.safe_source_region(FACING.frame_for_creature(friendly_card, seat, 0.0)).position.y)
	var opposite_expected_y := int(FACING.safe_source_region(FACING.frame_for_creature(enemy_card, opponent, 0.0)).position.y)
	var atlas := friendly.texture as AtlasTexture if friendly != null else null
	var enemy_atlas := enemy.texture as AtlasTexture if enemy != null else null
	require(atlas != null and int(atlas.region.position.y) == expected_y, "seat %d settled unit uses its physical inward-facing row with the cache gutter applied (expected=%d actual=%d)" % [seat, expected_y, int(atlas.region.position.y) if atlas != null else -1])
	require(enemy_atlas != null and int(enemy_atlas.region.position.y) == opposite_expected_y, "seat %d settled opposite-side unit uses its physical inward-facing row with the cache gutter applied (expected=%d actual=%d)" % [seat, opposite_expected_y, int(enemy_atlas.region.position.y) if enemy_atlas != null else -1])
	image = get_viewport().get_texture().get_image()
	_save_capture(image, "m11-facing-seat%d-settled" % seat, {"kind":"print_settled","authority_actor":seat,"presentation_actor":int(stage.event.get("actor",-1)) if stage != null else -1,"receipt_serial":int(receipt.get("serial",-1)),"friendly_card":friendly_card,"opposite_card":enemy_card,"friendly_row_y":expected_y,"opposite_row_y":opposite_expected_y,"fixture":fixture_creature,"text_scale_bps":text_scale_bps,"high_contrast":high_contrast,"reduced_motion":reduced_motion,"width":width,"height":height})
	await _dispose_shell(shell)

func _capture_attack(actor: int) -> void:
	get_window().content_scale_size = Vector2i(width, height); get_window().size = Vector2i(width, height)
	GameManager.profile = RULES.new_profile(); GameManager.profile.settings = {"text_scale_bps":text_scale_bps,"high_contrast":high_contrast,"reduced_motion":reduced_motion}
	var seat_zero_card := _card_for_seat(0)
	var seat_one_card := _card_for_seat(1)
	var state := STATE.create(_deck(seat_zero_card), _deck(seat_one_card), 1800 + actor)
	state.active_seat = actor; state.phase = "attack"; state.turn = 2
	state.player(0).slots[0] = STATE._unit(RULES.card(seat_zero_card))
	state.player(1).slots[0] = STATE._unit(RULES.card(seat_one_card))
	var shell := MAIN.instantiate(); shell.screen = "unified_battle"; shell.battle = state; shell.battle_mode = "training"; shell.unified_battle_coordinator.configure(state, 0); add_child(shell)
	await get_tree().process_frame
	var accepted: Dictionary = shell.unified_battle_coordinator.submit_checked(shell.unified_battle_coordinator.envelope(actor,{"type":"attack","slot":0,"target":0}),shell.unified_battle_coordinator.generation)
	var receipt: Dictionary = accepted.get("receipt",{})
	require(bool(accepted.get("ok",false)) and str(receipt.get("kind","")) == "attack", "actor %d produces a legal coordinator attack receipt" % actor)
	var authority_signature := JSON.stringify(receipt)
	shell._present_unified_battle_event(receipt); shell.render(); await get_tree().create_timer(.30).timeout; await _await_presented_frame()
	var stage := shell.find_child("PhysicalBattlefieldStage",true,false) as PhysicalBattlefieldStage
	var contact := stage.find_child("BattleContactPeakOverlay",true,false) as TextureRect if stage != null else null
	var contact_atlas := contact.texture as AtlasTexture if contact != null else null
	# Training has a fixed seat-0 viewer, so the physical stage must retain each
	# authority actor: player Cinderpaw attacks rear-facing; rival Aquafin attacks
	# front-facing. This deliberately avoids hotseat's lower-seat remap.
	var presentation_actor := int(stage.event.get("actor", -1)) if stage != null else -1
	var expected_card := _card_for_seat(actor)
	var expected_frame := FACING.frame_for_creature(expected_card, actor if reduced_motion else presentation_actor, 0.0, "attack", .50)
	var expected_region := FACING.safe_source_region(expected_frame)
	if reduced_motion:
		var settled := stage.find_child("LivingPrintSlot%d" % (actor * 3), true, false) as TextureRect if stage != null else null
		require(stage != null and not shell.unified_battle_coordinator.presentation_active and settled != null and settled.visible, "Reduced-motion actor %d reaches a settled visible unit without claiming an attack flyover/contact overlay." % actor)
		require(JSON.stringify(receipt) == authority_signature, "Reduced-motion actor %d authority receipt remains unchanged through finite acknowledgement." % actor)
		_save_capture(get_viewport().get_texture().get_image(), "m11-facing-actor%d-attack-reduced-motion" % actor, {"kind":"attack_reduced_motion","authority_actor":actor,"actor_card":expected_card,"receipt_serial":int(receipt.get("serial",-1)),"authority_signature":authority_signature,"fixture":fixture_creature,"text_scale_bps":text_scale_bps,"high_contrast":high_contrast,"reduced_motion":true,"width":width,"height":height})
		await _dispose_shell(shell)
		return
	require(presentation_actor == actor, "training viewer retains authority actor %d as physical actor %d rather than remapping its battle direction" % [actor, presentation_actor])
	var presentation_kind := "legacy selected presentation" if FACING.uses_legacy_art(expected_card) else "required inward"
	require(stage != null and stage.attack_contact_reached() and contact != null and contact.visible and contact_atlas != null and contact_atlas.atlas != null and contact_atlas.atlas.resource_path == FACING.sprite_path_for(expected_card) and contact_atlas.region.position == expected_region.position, "authority actor %d / physical actor %d contact overlay uses %s's %s contact cell (frame=%d expected=%s actual=%s visible=%s reached=%s)" % [actor, presentation_actor, expected_card, presentation_kind, expected_frame, str(expected_region.position), str(contact_atlas.region.position if contact_atlas != null else Vector2(-1,-1)), str(contact.visible if contact != null else false), str(stage.attack_contact_reached() if stage != null else false)])
	require(JSON.stringify(receipt) == authority_signature, "actor %d authority receipt remains unchanged through visual contact" % actor)
	_save_capture(get_viewport().get_texture().get_image(), "m11-facing-actor%d-attack-contact" % actor, {"kind":"attack_contact","authority_actor":actor,"presentation_actor":presentation_actor,"actor_card":expected_card,"receipt_serial":int(receipt.get("serial",-1)),"contact_frame":expected_frame,"contact_region":str(expected_region),"authority_signature":authority_signature,"fixture":fixture_creature,"text_scale_bps":text_scale_bps,"high_contrast":high_contrast,"reduced_motion":reduced_motion,"width":width,"height":height})
	var deadline := Time.get_ticks_msec() + 3000
	while shell.unified_battle_coordinator.presentation_active and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		await get_tree().create_timer(.02).timeout
	require(not shell.unified_battle_coordinator.presentation_active, "actor %d attack presentation returns after its real acknowledgement" % actor)
	await _await_presented_frame()
	require(JSON.stringify(receipt) == authority_signature, "actor %d authority receipt remains unchanged after visual acknowledgement" % actor)
	_save_capture(get_viewport().get_texture().get_image(), "m11-facing-actor%d-attack-return" % actor, {"kind":"attack_return","actor":actor,"receipt_serial":int(receipt.get("serial",-1)),"authority_signature":authority_signature,"width":width,"height":height})
	await _dispose_shell(shell)

func _card_for_seat(seat: int) -> String:
	if fixture_creature == "voltwig":
		return "voltwig"
	return "cinderpaw" if seat == 0 else "aquafin"
