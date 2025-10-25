# Fireball.gd
extends Area2D

const SPEED = 400.0
const DAMAGE = 20.0

var direction: int = 1
var shooter: Node = null

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Set visual
	var sprite = $ColorRect
	sprite.color = Color.ORANGE

func _physics_process(delta):
	position.x += direction * SPEED * delta
	
	# Destroy if off screen
	if abs(position.x) > 1500:
		queue_free()

func _on_body_entered(body):
	if body == shooter:
		return
	
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
	
	queue_free()
