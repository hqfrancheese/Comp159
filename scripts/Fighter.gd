extends CharacterBody2D

@export var player_number: int = 1
@export var is_cpu: bool = false
@onready var anim = $AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -700.0
const MELEE_RANGE = 80.0
const FIREBALL_COOLDOWN = 1.0
const MELEE_COOLDOWN = 0.5

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health: float = 100.0
var is_blocking = false
var fireball_timer: float = 0.0
var melee_timer: float = 0.0
var is_attacking: bool = false
var opponent: CharacterBody2D = null
var facing: int = 1
var current_animation: String = "idle"

# Player controls mapping (populated from GameManager)
var controls = {
	"left": "",
	"right": "",
	"jump": "",
	"melee": "",
	"fireball": "",
	"block": ""
}

@onready var sprite = $ColorRect
@onready var fireball_scene = null

func _ready():
	# Assign control scheme based on player number
	if player_number == 1:
		controls = GameManager.player1_controls.duplicate()
		sprite.color = Color.BLUE
		$AnimatedSprite2D.sprite_frames = preload("res://assets/sprites/Fire Wizard/firewizard.tres")
		fireball_scene = preload("res://scenes/Fireball.tscn")
	else:
		controls = GameManager.player2_controls.duplicate()
		sprite.color = Color.RED
		$AnimatedSprite2D.sprite_frames = preload("res://assets/sprites/Lightning Mage/lightningmage.tres")
		fireball_scene = preload("res://scenes/Lightning.tscn")

func _physics_process(delta):
	fireball_timer = max(0, fireball_timer - delta)
	melee_timer = max(0, melee_timer - delta)
	
	if is_cpu:
		_cpu_behavior(delta)
	else:
		_player_input(delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	_update_animation()
	
	# Update blocking visual
	sprite.color.a = 0.5 if is_blocking else 1.0
	
	move_and_slide()

func _update_animation():
	var new_animation = "idle"
	
	if is_blocking:
		new_animation = "block"
	elif not is_on_floor():
		if current_animation == "idle" or current_animation == "run":
			new_animation = current_animation
		else:
			new_animation = "idle"
	elif abs(velocity.x) > 10:
		new_animation = "run"
	else:
		new_animation = "idle"
	
	if new_animation != current_animation:
		current_animation = new_animation
		$AnimatedSprite2D.play(current_animation)
	
	# Update facing direction
	if not is_cpu:
		if velocity.x != 0:
			facing = sign(velocity.x)
	else:
		if is_on_floor() and abs(velocity.x) > 50:
			facing = sign(velocity.x)
	
	$AnimatedSprite2D.flip_h = facing < 0

# -----------------------------
# Dynamic Input System
# -----------------------------
func _player_input(_delta):
	# Horizontal movement
	var direction = 0
	if _is_key_pressed(controls["left"]):
		direction -= 1
	if _is_key_pressed(controls["right"]):
		direction += 1

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Jump
	if _is_key_pressed(controls["jump"]) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Block
	is_blocking = _is_key_pressed(controls["block"])

	# Melee
	if _is_key_pressed(controls["melee"]) and melee_timer <= 0:
		_melee_attack()

	# Fireball
	if _is_key_pressed(controls["fireball"]) and fireball_timer <= 0:
		_shoot_fireball()

func _is_key_pressed(key_name: String) -> bool:
	if key_name == "":
		return false
	var keycode = OS.find_keycode_from_string(key_name)
	if keycode == 0:
		return false
	return Input.is_key_pressed(keycode)

# -----------------------------
# CPU Behavior
# -----------------------------
func _cpu_behavior(_delta):
	if not opponent:
		return
	
	var distance = global_position.distance_to(opponent.global_position)
	var direction_to_opponent = sign(opponent.global_position.x - global_position.x)
	var health_ratio = health / 100.0
	var opponent_health_ratio = opponent.health / 100.0
	
	var aggression = 0.7
	var ideal_distance = MELEE_RANGE * 1.8
	
	if health_ratio < 0.3:
		aggression = 0.4
		ideal_distance = MELEE_RANGE * 2.5
	elif opponent_health_ratio < 0.3:
		aggression = 0.9
		ideal_distance = MELEE_RANGE * 1.2
	
	if is_on_floor() and randf() < 0.08:
		velocity.y = JUMP_VELOCITY
	
	var can_change_direction = is_on_floor()
	var distance_error = distance - ideal_distance
	var move_intensity = 0.0
	
	if can_change_direction:
		if abs(distance_error) > 30:
			if distance_error > 0:
				move_intensity = 0.6
			else:
				move_intensity = -0.4
		else:
			if randf() < 0.3:
				move_intensity = randf_range(-0.3, 0.3)
			else:
				move_intensity = 0
		
		velocity.x = direction_to_opponent * move_intensity * SPEED
		
		if randf() < 0.15:
			velocity.x = 0
	
	is_blocking = false
	
	if opponent.is_attacking and distance <= MELEE_RANGE * 1.5:
		is_blocking = randf() < 0.7
	elif distance < MELEE_RANGE * 0.8 and health_ratio < 0.5:
		is_blocking = randf() < 0.4
	elif randf() < 0.05:
		is_blocking = true
	
	var should_attack = false
	
	if distance > MELEE_RANGE * 0.7 and distance < MELEE_RANGE * 2.5:
		should_attack = randf() < (aggression * 0.3)
	
	if should_attack and not is_blocking:
		if distance <= MELEE_RANGE * 1.2 and melee_timer <= 0:
			if randf() < 0.6:
				_melee_attack()
		elif distance > MELEE_RANGE * 1.3 and distance < 380 and fireball_timer <= 0:
			if randf() < 0.5:
				_shoot_fireball()
	
	if melee_timer > 0 or fireball_timer > 0.5:
		is_blocking = false
	
	facing = direction_to_opponent

# -----------------------------
# Attacks
# -----------------------------
func _melee_attack():
	melee_timer = MELEE_COOLDOWN
	is_attacking = true
	
	var attack_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(MELEE_RANGE, 50)
	collision.shape = shape
	attack_area.add_child(collision)
	add_child(attack_area)
	
	attack_area.position.x = MELEE_RANGE / 2 * facing
	
	attack_area.body_entered.connect(func(body):
		if body.has_method("take_damage") and body != self:
			body.take_damage(15.0)
	)
	
	var flash = ColorRect.new()
	flash.size = Vector2(MELEE_RANGE, 50)
	flash.color = Color(1, 1, 0, 0.5)
	flash.position = Vector2(MELEE_RANGE / 2 * facing - MELEE_RANGE / 2, -25)
	add_child(flash)
	
	await get_tree().create_timer(0.1).timeout
	if flash and is_instance_valid(flash):
		flash.queue_free()
	if attack_area and is_instance_valid(attack_area):
		attack_area.queue_free()
	is_attacking = false

func _shoot_fireball():
	fireball_timer = FIREBALL_COOLDOWN
	
	var fireball = fireball_scene.instantiate()
	get_parent().add_child(fireball)
	
	var offset = Vector2(40, -70)
	fireball.global_position = global_position + Vector2(offset.x * facing, offset.y)
	fireball.direction = facing
	fireball.shooter = self

# -----------------------------
# Damage and Misc
# -----------------------------
func take_damage(amount: float):
	if is_blocking:
		amount *= 0.5
	
	health -= amount
	health = max(0, health)
	
	if player_number == 1:
		GameManager.player1_health = health
	else:
		GameManager.player2_health = health
	
	var original_color = sprite.color
	sprite.color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(sprite):
		sprite.color = original_color

func set_opponent(new_opponent: CharacterBody2D):
	opponent = new_opponent
