extends CharacterBody2D

@export var speed: float = 35.0
@export var health : int = 10

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $CharacterSprite
@onready var damage_receiver := $DamageReceiver

var player: CharacterBody2D = null

enum State {IDLE, WALK, HURT}

const KNOCKBACK_STRENGTH := 100.0

var state = State.IDLE
var slot_offset := Vector2.ZERO
var knockback_velocity := Vector2.ZERO

func _ready() -> void:
	damage_receiver.damage_received.connect(on_receive_damage.bind())

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
	
func on_receive_damage(dmg: int, direction: Vector2) -> void:
	if state == State.HURT:
		return
	health -= dmg
	state = State.HURT
	knockback_velocity = direction * KNOCKBACK_STRENGTH
	
	
	
	
	
