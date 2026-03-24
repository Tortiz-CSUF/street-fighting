extends Node2D

@onready var player := $ActorsContainer/Player
@onready var camera := $Camera

func _ready() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.player = player	
func _process(delta: float) -> void:
	if player.position.x > camera.position.x:
		camera.position.x = player.position.x
