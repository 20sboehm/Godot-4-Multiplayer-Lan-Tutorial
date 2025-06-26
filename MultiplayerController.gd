extends Control

@export var address = "127.0.0.1"

@onready var host: Button = $Host
@onready var join: Button = $Join
@onready var start_game: Button = $StartGame

func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	host.pressed.connect(_on_host_button_down)
	join.pressed.connect(_on_join_button_down)
	start_game.pressed.connect(_on_start_game_button_down)

# Called on the server and clients
func peer_connected(id: int):
	print("Player connected: " + str(id))

# Called on the server and clients
func peer_disconnected(id: int):
	print("Player disconnected: " + str(id))

# Called only from clients
func connected_to_server() -> void:
	print("Connected to server")

# Called only from clients
func connection_failed() -> void:
	print("Failed to connect to server")

func _on_host_button_down() -> void:
	pass

func _on_join_button_down() -> void:
	pass

func _on_start_game_button_down() -> void:
	pass
