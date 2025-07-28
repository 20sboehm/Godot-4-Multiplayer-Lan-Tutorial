extends Control

@export var address = "127.0.0.1"
@export var port = 8910
var peer: ENetMultiplayerPeer
const SERVER_ID = 1

@onready var host_button: Button = $Host
@onready var join_button: Button = $Join
@onready var start_game_button: Button = $StartGame
@onready var leave_game_button: Button = $LeaveGame
@onready var lobby_players: Label = %LobbyPlayers

func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	host_button.pressed.connect(_on_host_button_down)
	join_button.pressed.connect(_on_join_button_down)
	start_game_button.pressed.connect(_on_start_game_button_down)
	leave_game_button.pressed.connect(_on_leave_game_button_down)

# Called on the server and clients
func peer_connected(id: int):
	print("Player connected: " + str(id) + " | from " + str(multiplayer.get_unique_id()))

# Called on the server and clients
func peer_disconnected(id: int):
	print("Player disconnected: " + str(id) + " | from " + str(multiplayer.get_unique_id()))
	GameManager.players.erase(id)
	update_lobby_ui()

# Called only from clients
func connected_to_server() -> void:
	print("Connected to server (" + str(multiplayer.get_unique_id()) + ")")
	send_player_information.rpc_id(SERVER_ID, $LineEdit.text, multiplayer.get_unique_id())

# Called only from clients
func connection_failed() -> void:
	print("Failed to connect to server")

#@rpc("any_peer", "reliable")
#func leave_server(id: int):
	#if not multiplayer.is_server():
		#print("Something went wrong. This function should only run on the server.")
		#return
	#
	#peer.disconnect_peer(id)

# Client sends player information to server (always call this with rpc_id using the server ID)
@rpc("any_peer", "reliable")
func send_player_information(player_name: String, id: int):
	if not multiplayer.is_server():
		print("Something went wrong. This function should only run on the server.")
		return
	
	GameManager.players[id] = {
		"name": player_name,
		"id": id,
		"score": 0
	}
	update_lobby_ui()
	sync_player_information.rpc(GameManager.players)

# Server updates all the clients with player information
@rpc("authority", "reliable")
func sync_player_information(player_info: Dictionary):
	GameManager.players = player_info
	
	update_lobby_ui()

func update_lobby_ui() -> void:
	var players_text = lobby_players.text
	var new_players_list: Array = players_text.split("\n")
	var old_players_list: Array = []
	for id in GameManager.players:
		old_players_list.append(GameManager.players[id].name)
	if old_players_list != new_players_list:
		lobby_players.text = "\n".join(PackedStringArray(old_players_list))

#mode:
	#"authority" (default): Only the multiplayer authority can call remotely. The authority is the server by default, but can be changed per-node using Node.set_multiplayer_authority.
	#"any_peer": Clients are allowed to call remotely. Useful for transferring user input.
#sync:
	#"call_remote" (default): The function will not be called on the local peer.
	#"call_local": The function can be called on the local peer. Useful when the server is also a player.
#transfer_mode:
	#"unreliable" (default) Packets are not acknowledged, can be lost, and can arrive at any order.
	#"unreliable_ordered" Packets are received in the order they were sent in. This is achieved by ignoring packets that arrive later if another that was sent after them has already been received. Can cause packet loss if used incorrectly.
	#"reliable" Resend attempts are sent until packets are acknowledged, and their order is preserved. Has a significant performance penalty.
@rpc("any_peer", "call_local")
func start_game() -> void:
	var scene = load("res://testScene.tscn").instantiate()
	get_tree().root.add_child(scene)

func _on_host_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 4)
	if error != OK:
		print("Cannot host: " + str())
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Server hosted. Waiting for players...")
	send_player_information($LineEdit.text, multiplayer.get_unique_id())

func _on_join_button_down() -> void:
	print("Joining game...")
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

func _on_start_game_button_down() -> void:
	# Use rpc_id to only call it on one peer (e.g. only on host)
	start_game.rpc()

func _on_leave_game_button_down() -> void:
	# TODO: This should be different logic for host
	# https://forum.godotengine.org/t/godot-4-disconnect-player/58503/5
	
	#leave_server.rpc_id(SERVER_ID, multiplayer.get_unique_id())
	multiplayer.multiplayer_peer.disconnect_peer(SERVER_ID)
	#multiplayer.multiplayer_peer = null # Terminate connecction
	GameManager.players = {}
	update_lobby_ui()
