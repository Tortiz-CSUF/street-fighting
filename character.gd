extends CharacterBody2D

@export var health : int
@export var damage : int
@export var speed : float

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $CharacterSprite
@onready var damage_emitter := $DamageEmitter
@onready var damage_receiver := $DamageReceiver

## Jump Consts
const JUMP_HEIGHT_SPEED := 120.0
const GRAVITY := 400.0
const KNOCKBACK_STRENGTH := 100.0

enum State {IDLE,WALK,ATTACK, JUMP_TAKEOFF, JUMP_AIR, JUMP_LAND, JUMP_KICK, HURT, DEATH}

var state = State.IDLE
var has_hit := false

## Jump height
var height := 0.0
var height_speed := 0.0
var knockback_velocity := Vector2.ZERO


func _ready() -> void:
	damage_emitter.area_entered.connect(on_emit_damage.bind())
	animation_player.animation_finished.connect(on_animation_finished.bind())
	damage_receiver.damage_received.connect(on_receive_damage.bind())
	

func _process(delta: float) -> void:
	if state == State.DEATH:
		handle_animation()
		return
		
	handle_input()
	handle_movement()
	handle_jump(delta)
	handle_animation()
	flip_sprites()
	
	if state == State.HURT:
		velocity = knockback_velocity
		
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
	
	if can_move() or is_airborne():
		velocity = direction * speed	
	else:
		velocity = Vector2.ZERO
	
	if can_attack() and Input.is_action_just_pressed("attack"):
		state = State.ATTACK
		
	if state == State.JUMP_AIR and Input.is_action_just_pressed("attack"):
		state = State.JUMP_KICK
		has_hit = false
		damage_emitter.monitoring = true
		
	if can_jump() and Input.is_action_just_pressed("jump"):
		state = State.JUMP_TAKEOFF
		
func handle_jump(delta: float) -> void:
	if state == State.JUMP_AIR or state == State.JUMP_KICK:
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
	
	if not animation_player.is_playing():
		if state == State.DEATH:
			return
	
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
	elif state == State.JUMP_KICK:
		anim_name = "jump_kick"
	elif state == State.HURT:
		anim_name = "hurt"
	elif  state == State.DEATH:
		anim_name == "death"
		
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
	return state == State.JUMP_TAKEOFF or state == State.JUMP_AIR or state == State.JUMP_KICK

func on_action_complete() -> void:
	has_hit = false
	state = State.IDLE
	
	if state == State.JUMP_TAKEOFF:
		state = State.JUMP_AIR
		height_speed = JUMP_HEIGHT_SPEED
	else:
		state = State.IDLE
		height = 0.0
		character_sprite.position.y = 0.0

func on_emit_damage(damage_receiver:DamageReceiver) -> void:
	if has_hit:
		return
	has_hit = true
		
	var direction := Vector2.LEFT if damage_receiver.global_position.x < global_position.x else Vector2.RIGHT
	var knockdown: bool = (state == State.JUMP_KICK)
	
	damage_receiver.damage_received.emit(damage, direction, knockdown)
	print(damage_receiver)
	
func on_receive_damage(dmg: int, direction: Vector2, is_knockdown: bool = false) -> void:
	if state == State.HURT or state == State.DEATH:
		return
	
	health -= dmg
	if health <= 0:
		state = State.DEATH
		knockback_velocity = Vector2.ZERO
		
	state = State.HURT
	knockback_velocity = direction * KNOCKBACK_STRENGTH

func on_animation_finished(anim_name: String) -> void:
	if anim_name == "jump_takeoff":
		state = State.JUMP_AIR
		height_speed = JUMP_HEIGHT_SPEED
	elif anim_name == "jump_land":
		state = State.IDLE
		height = 0.0
		character_sprite.position.y = 0.0
		damage_emitter.monitoring = false
	elif anim_name == "hurt":
		state = State.IDLE
		knockback_velocity = Vector2.ZERO
	elif anim_name == "death":
		fade_out()
		
func fade_out() -> void:
	var tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(self, "modulate.a", 0.0, 0.5)
	tween.tween_callback(queue_free)
