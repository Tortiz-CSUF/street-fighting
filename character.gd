extends CharacterBody2D

@export var health : int
@export var damage : int
@export var speed : float

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $CharacterSprite
@onready var damage_emitter := $DamageEmitter

## Jump Consts
const JUMP_HEIGHT_SPEED := 120.0
const GRAVITY := 400.0

enum State {IDLE,WALK,ATTACK, JUMP_TAKEOFF, JUMP_AIR, JUMP_LAND}

var state = State.IDLE

## Jump height
var height := 0.0
var height_speed := 0.0

func _ready() -> void:
	damage_emitter.area_entered.connect(on_emit_damage.bind())

func _process(delta: float) -> void:
	handle_input()
	handle_movement()
	handle_jump(delta)
	handle_animation()
	flip_sprites()
	move_and_slide()

func handle_movement():
	if can_move():
		if velocity.length() == 0:
			state = State.IDLE
		else:
			state = State.WALK
	#else:
		#velocity = Vector2.ZERO
		
func handle_input() -> void:
	var direction := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	
	if can_move():
		velocity = direction * speed	
	elif is_airborne():
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	
	if can_attack() and Input.is_action_just_pressed("attack"):
		state = State.ATTACK
		
	if can_jump() and Input.is_action_just_pressed("jump"):
		state = State.JUMP_TAKEOFF
		
func handle_jump(delta: float) -> void:
	if state == State.JUMP_AIR:
		height_speed -= GRAVITY * delta
		height += height_speed * delta
		
		if height <= 0.0:
			height = 0.0
			height_speed = 0.0
			character_sprite.position.y = 0.0
			state = State.JUMP_LAND
			return
		
		character_sprite.position.y = -height
	
func handle_animation() -> void:
	var anim_name := ""
	
	if state == State.IDLE:
		anim_name = "idle"
	elif state == State.WALK:
		anim_name = "walk"
	elif state == State.ATTACK:
		anim_name = "punch"
	elif state == State.JUMP_TAKEOFF:
		anim_name = "jump_takeoff"
	elif state == State.JUMP_AIR:
		anim_name = "jump_air"
	elif state == State.JUMP_LAND:
		anim_name = "jump_land"
		
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)
		
		
func flip_sprites() -> void:
	#facing right
	if velocity.x > 0:
		character_sprite.flip_h = false
		damage_emitter.scale.x = 1
	#facing left	
	elif velocity.x <0:
			character_sprite.flip_h = true
			damage_emitter.scale.x = -1	
func can_move() -> bool:
	return state == State.IDLE or state == State.WALK

func can_attack() -> bool:
	return state == State.IDLE or state == State.WALK
	
func can_jump() -> bool:
	return state == State.IDLE or state == State.WALK
		
func is_airborne() -> bool:
	return state == State.JUMP_TAKEOFF or state == State.JUMP_AIR

func on_action_complete() -> void:
	if state == State.JUMP_TAKEOFF:
		state = State.JUMP_AIR
		height_speed = JUMP_HEIGHT_SPEED
	else:
		state = State.IDLE
		height = 0.0
		character_sprite.position.y = 0.0

func on_emit_damage(damage_receiver:DamageReceiver) -> void:
	var direction := Vector2.LEFT if damage_receiver.global_position.x < global_position.x else Vector2.RIGHT
	
	damage_receiver.damage_received.emit(damage,direction)
	print(damage_receiver)
