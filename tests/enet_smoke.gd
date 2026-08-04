extends SceneTree

const CombatNetworkScript := preload("res://scripts/combat_network.gd")
const TEST_PORT := 17991

var session
var host_mode := false
var deadline := 0


func _initialize() -> void:
	host_mode = "--host" in OS.get_cmdline_user_args()
	deadline = Time.get_ticks_msec() + 8000
	call_deferred("_start")


func _start() -> void:
	set_multiplayer(MultiplayerAPI.create_default_interface(), NodePath("/root"))
	session = CombatNetworkScript.new()
	session.name = "CombatNetwork"
	root.add_child(session)
	session.connection_failed.connect(_fail)
	if host_mode:
		session.peer_joined.connect(_on_peer_joined)
		session.command_received.connect(_on_command_received)
		if session.host(TEST_PORT) != OK:
			quit(2)
	else:
		session.snapshot_received.connect(_on_snapshot_received)
		if session.join("127.0.0.1", TEST_PORT) != OK:
			quit(2)


func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() > deadline:
		_fail("ENet smoke test timed out.")
	return false


func _on_peer_joined(peer_id: int) -> void:
	session.send_snapshot({
		"version": 1,
		"cell": Vector2i(12, 16),
		"nested": {"filament": 6},
	}, {"type": "probe"}, peer_id)


func _on_snapshot_received(snapshot: Dictionary, event: Dictionary) -> void:
	assert(int(snapshot.get("version", 0)) == 1)
	assert(snapshot.get("cell") == Vector2i(12, 16))
	assert(int(snapshot.get("nested", {}).get("filament", 0)) == 6)
	assert(str(event.get("type", "")) == "probe")
	session.send_command({"type": "ack", "sequence": 1})
	print("ENET_CLIENT_SMOKE_OK")
	call_deferred("quit", 0)


func _on_command_received(_peer_id: int, command: Dictionary) -> void:
	assert(str(command.get("type", "")) == "ack")
	assert(int(command.get("sequence", 0)) == 1)
	print("ENET_HOST_SMOKE_OK")
	call_deferred("quit", 0)


func _fail(message: String) -> void:
	push_error(message)
	quit(2)
