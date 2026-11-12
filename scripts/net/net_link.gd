class_name NetLink
extends Node
## Direct-connect multiplayer (LAN, or the internet with a forwarded port).
## The host runs the rules; the guest only sends actions and receives the
## already-hidden view of the battle. No accounts, no chat, no text.

signal guest_ready(info: Dictionary)
signal game_started(view: Dictionary, info: Dictionary)
signal update_received(events: Array, view: Dictionary)
signal action_received(action: Dictionary)
signal connected
signal dropped(reason: String)

const PORT := 24842

var role := ""
var guest_id := 0


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func(): connected.emit())
	multiplayer.connection_failed.connect(func(): _drop("Could not reach that address."))
	multiplayer.server_disconnected.connect(func(): _drop("The host left the game."))


func host() -> String:
	close()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, 1)
	if err != OK:
		return "Could not open port %d (%s)." % [PORT, error_string(err)]
	multiplayer.multiplayer_peer = peer
	role = "host"
	return ""


func join(address: String) -> String:
	close()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address.strip_edges(), PORT)
	if err != OK:
		return "That address does not look right."
	multiplayer.multiplayer_peer = peer
	role = "client"
	return ""


func close() -> void:
	if not is_inside_tree():
		return
	if multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	role = ""
	guest_id = 0


static func local_addresses() -> Array:
	var out: Array = []
	for a in IP.get_local_addresses():
		if a.count(".") == 3 and not a.begins_with("127.") and not a.begins_with("169.254."):
			out.append(a)
	return out


func _drop(reason: String) -> void:
	if role == "":
		return
	close()
	dropped.emit(reason)


func _on_peer_connected(id: int) -> void:
	if role == "host" and guest_id == 0:
		guest_id = id


func _on_peer_disconnected(id: int) -> void:
	if role == "host" and id == guest_id:
		guest_id = 0
		dropped.emit("Your opponent left the game.")


# -- guest to host

func send_hello(info: Dictionary) -> void:
	c_hello.rpc_id(1, info)


func send_action(action: Dictionary) -> void:
	c_action.rpc_id(1, action)


@rpc("any_peer", "call_remote", "reliable")
func c_hello(info: Dictionary) -> void:
	if role == "host" and multiplayer.get_remote_sender_id() == guest_id:
		guest_ready.emit(info)


@rpc("any_peer", "call_remote", "reliable")
func c_action(action: Dictionary) -> void:
	if role == "host" and multiplayer.get_remote_sender_id() == guest_id:
		action_received.emit(action)


# -- host to guest

func send_start(view: Dictionary, info: Dictionary) -> void:
	if guest_id != 0:
		s_start.rpc_id(guest_id, view, info)


func send_update(events: Array, view: Dictionary) -> void:
	if guest_id != 0:
		s_update.rpc_id(guest_id, events, view)


@rpc("authority", "call_remote", "reliable")
func s_start(view: Dictionary, info: Dictionary) -> void:
	game_started.emit(view, info)


@rpc("authority", "call_remote", "reliable")
func s_update(events: Array, view: Dictionary) -> void:
	update_received.emit(events, view)
