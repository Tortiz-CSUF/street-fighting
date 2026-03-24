extends CharacterBody2D

@export var speed: float = 35.0

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $CharacterSprite

var player: CharacterBody2D = null

enum State {IDLE, WALK}

var state = State.IDLE
var slot_offset := Vector2.ZERO

func _process(delta: float) -> void:
	if player == null:
		return
	
	handle_movement()
	handle_animation()
	flip_sprites()
	move_and_slide()
	
func handle_movement() -> void:
	var target := player.global_position + slot_offset
	var distance := global_position.distance_to(target)
	
	if distance < 5.0:
		velocity = Vector2.ZERO
		state = State.IDLE
		return
		
	var direction := (target - global_position).normalized()
	velocity = direction * speed
	state = State.WALK	
	
func handle_animation() -> void:
	var anim_name := ""
	
	if state == State.IDLE:
		anim_name = "idle"
	elif state == State.WALK:
		anim_name = "walk"
		
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)
	
func flip_sprites() -> void:
	if player == null:
		return 
	if player.global_position.x > global_position.x:
		character_sprite.flip_h = false
	else:
		character_sprite.flip_h = true
	
	
	
	
	
	
	
	
	
	
