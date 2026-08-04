class_name CombatNetworkSession
extends Node

signal server_started(port: int)
signal connected_to_server
signal connection_failed(message: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal command_received(peer_id: int, command: Dictionary)
signal snapshot_received(snapshot: Dictionary, event: Dictionary)
signal command_rejected(message: String)

const DEFAULT_PORT := 7000
const MAX_CLIENTS := 1

var mode := "offline"
var connected_peer_id := 0


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host(port := DEFAULT_PORT) -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(port, MAX_CLIENTS)
	if result != OK:
		connection_failed.emit("Could not host UDP port %d (%s)." % [port, error_string(result)])
		return result
	mode = "host"
	multiplayer.multiplayer_peer = peer
	server_started.emit(port)
	return OK


func join(address: String, port := DEFAULT_PORT) -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_client(address, port)
	if result != OK:
		connection_failed.emit("Could not connect to %s:%d (%s)." % [address, port, error_string(result)])
		return result
	mode = "client"
	multiplayer.multiplayer_peer = peer
	return OK


func close() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	mode = "offline"
	connected_peer_id = 0


func send_command(command: Dictionary) -> void:
	if mode == "client" and multiplayer.multiplayer_peer != null:
		_server_receive_command.rpc_id(1, command)


func send_snapshot(snapshot: Dictionary, event := {}, peer_id := 0) -> void:
	if mode != "host":
		return
	if peer_id > 1:
		_client_receive_snapshot.rpc_id(peer_id, snapshot, event)
	else:
		_client_receive_snapshot.rpc(snapshot, event)


func reject(peer_id: int, message: String) -> void:
	if mode == "host" and peer_id > 1:
		_client_command_rejected.rpc_id(peer_id, message)


@rpc("any_peer", "call_remote", "reliable")
func _server_receive_command(command: Dictionary) -> void:
	if mode != "host":
		return
	command_received.emit(multiplayer.get_remote_sender_id(), command)


@rpc("authority", "call_remote", "reliable")
func _client_receive_snapshot(snapshot: Dictionary, event: Dictionary) -> void:
	if mode == "client":
		snapshot_received.emit(snapshot, event)


@rpc("authority", "call_remote", "reliable")
func _client_command_rejected(message: String) -> void:
	if mode == "client":
		command_rejected.emit(message)


func _on_peer_connected(peer_id: int) -> void:
	connected_peer_id = peer_id
	peer_joined.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if connected_peer_id == peer_id:
		connected_peer_id = 0
	peer_left.emit(peer_id)


func _on_connected_to_server() -> void:
	connected_to_server.emit()


func _on_connection_failed() -> void:
	mode = "offline"
	connection_failed.emit("The ENet connection failed.")


func _on_server_disconnected() -> void:
	mode = "offline"
	connected_peer_id = 0
	connection_failed.emit("The host disconnected.")
