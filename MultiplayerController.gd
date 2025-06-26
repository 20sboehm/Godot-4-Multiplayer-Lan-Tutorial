extends Control

@export var address = "127.0.0.1"

@onready var host: Button = $Host
@onready var join: Button = $Join
@onready var start_game: Button = $StartGame

func _ready() -> void:
	multiplayer.peer_connected.connect(player_connected)
	
	host.pressed.connect(_on_host_button_down)
	join.pressed.connect(_on_join_button_down)
	start_game.pressed.connect(_on_start_game_button_down)

func player_connected(id: int):
	print("Player connected: " + str(id))

func _on_host_button_down() -> void:
	pass

func _on_join_button_down() -> void:
	pass

func _on_start_game_button_down() -> void:
	pass
