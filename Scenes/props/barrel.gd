extends StaticBody2D
@onready var damage_receiver := $DamageReceiver
@onready var sprite := $Sprite2D
@export var knockback_intesity : float

var velocity := Vector2.ZERO
var height := 0.0
var height_speed

enum State {IDLE,DESTROYED}
var state := State.IDLE
const GRAVITY := 600.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	damage_receiver.damage_received.connect(on_receive_damage.bind())
	
func _process(delta: float) -> void:
	position +=	velocity * delta
	sprite.position = Vector2.UP * height
	handle_air_time(delta)
	
func on_receive_damage(damage:int, direction:Vector2) -> void:
		if state == State.IDLE:
			sprite.frame = 1
			height_speed = knockback_intesity * 2
			state = State.DESTROYED
			velocity = direction * knockback_intesity
		
func handle_air_time(delta : float) -> void:
	if state == State.DESTROYED:
		modulate.a -= delta
		height += height_speed * delta
		if height < 0:
			height = 0
			queue_free()
		else: height_speed -= GRAVITY * delta
