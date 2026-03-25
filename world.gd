extends Node2D

@onready var player := $ActorsContainer/Player
@onready var camera := $Camera

var enemy_slots := [
	Vector2(-15, 0),
	Vector2(15, 0),
	
]

func _ready() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for i in enemies.size():
		enemies[i].player = player
		enemies[i].slot_offset = enemy_slots[i % enemy_slots.size()]
		
func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
		
	if player.position.x > camera.position.x:
		camera.position.x = player.position.x
