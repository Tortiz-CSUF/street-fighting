extends CharacterBody2D

@export var speed: float = 35.0
@export var health : int = 10
@export var damage : int = 2

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $CharacterSprite
@onready var damage_receiver := $DamageReceiver
@onready var damage_emmiter := $DamageEmitter

var player: CharacterBody2D = null

enum State {IDLE, WALK, HURT, KNOCKDOWN, GROUNDED, DEATH, ATTACK, COOLDOWN}

const KNOCKBACK_STRENGTH := 150.0
const ATTACK_RANGE := 5.0
const MAX_PUNCHES := 3
const PUNCH_COOLDOWN := 1.0

var state = State.IDLE
var slot_offset := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var has_hit := false
var punch_left := true
var punch_count := 0
var cooldown_timer := 0.0

func _ready() -> void:
	damage_receiver.damage_received.connect(on_receive_damage.bind())
	animation_player.animation_finished.connect(on_animation_finished.bind())
	damage_emmiter.area_entered.connect(on_emit_damage.bind())

func _process(delta: float) -> void:
	if player == null:
		return
			
	handle_movement()
	handle_animation()
	flip_sprites()
	move_and_slide()
	
func handle_movement() -> void:
	if state == State.HURT or state == State.KNOCKDOWN:
		velocity = knockback_velocity
		return
	if state == State.GROUNDED or state == State.DEATH or state == State.ATTACK:
		velocity = Vector2.ZERO
		return
	
	var target := player.global_position + slot_offset
	var distance := global_position.distance_to(target)
	
	if distance < ATTACK_RANGE:
		velocity = Vector2.ZERO
		if state == State.WALK or state == State.IDLE:
			if not is_instance_valid(player) or player.state == player.State.DEATH:
				state = State.IDLE
				return
			state = State.ATTACK
		return
		
	var direction := (target - global_position).normalized()
	velocity = direction * speed
	state = State.WALK	
	
func handle_animation() -> void:
	var anim_name := ""
	
	if not animation_player.is_playing():
		if state == State.DEATH or state == State.KNOCKDOWN or state == State.GROUNDED:
			return
	
	if state == State.IDLE:
		anim_name = "idle"
	elif state == State.WALK:
		anim_name = "walk"
	elif state == State.HURT:
		anim_name = "hurt"
	elif state == State.KNOCKDOWN:
		anim_name = "knockdown"
	elif state == State.GROUNDED:
		anim_name = "grounded"
	elif state == State.DEATH:
		anim_name = "death"
	elif  state == State.ATTACK:
		if punch_left:
			anim_name = "punch_left"
		else:
			anim_name = "punch_right"
		
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func on_animation_finished(anim_name: String) -> void:
	if anim_name == "hurt":
		state = State.IDLE
		knockback_velocity = Vector2.ZERO
	elif anim_name == "knockdown":
		state = State.GROUNDED
		knockback_velocity = Vector2.ZERO
	elif anim_name == "grounded":
		state = State.IDLE
	elif anim_name == "death":
		fade_out()
	elif anim_name == "punch_left" or anim_name == "punch_right":
		state = State.IDLE
		has_hit = false
		damage_emmiter.monitoring = false
		punch_left = !punch_left
	
func flip_sprites() -> void:
	if player == null:
		return 
	if player.global_position.x > global_position.x:
		character_sprite.flip_h = false
		damage_emmiter.scale.x = 1
	else:
		character_sprite.flip_h = true
		damage_emmiter.scale.x = -1

func on_emit_damage(damage_receiver: DamageReceiver) -> void:
	if has_hit:
		return
		
	has_hit = true
	var direction := Vector2.LEFT if damage_receiver.global_position.x < global_position.x else Vector2.RIGHT
	damage_receiver.damage_received.emit(damage, direction, false)
	
func on_receive_damage(dmg: int, direction: Vector2, is_knckdown: bool = false) -> void:
	if state == State.HURT or state == State.KNOCKDOWN or state == State.GROUNDED or state == State.DEATH:
		return
	health -= dmg
	if health <= 0:
		state = State.DEATH
		knockback_velocity = Vector2.ZERO
		return
		
	if is_knckdown:
		state = State.KNOCKDOWN
		knockback_velocity = direction * KNOCKBACK_STRENGTH
	else:
		state = State.HURT
		knockback_velocity = direction * KNOCKBACK_STRENGTH
	
func fade_out() -> void:
	var tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	
	
	
