# Fighter.gd
extends CharacterBody2D

@export var player_number: int = 1
@export var is_cpu: bool = false

const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const MELEE_RANGE = 80.0
const FIREBALL_COOLDOWN = 1.0
const MELEE_COOLDOWN = 0.5

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health: float = 100.0
var is_blocking: bool = false
var fireball_timer: float = 0.0
var melee_timer: float = 0.0
var is_attacking: bool = false
var opponent: CharacterBody2D = null
var facing: int = 1

# Player controls mapping
var controls = {
	"left": "",
	"right": "",
	"jump": "",
	"melee": "",
	"fireball": "",
	"block": ""
}

@onready var sprite = $ColorRect
@onready var fireball_scene = preload("res://scenes/Fireball.tscn")

func _ready():
	if player_number == 1:
		controls = GameManager.player1_controls
		sprite.color = Color.BLUE
	else:
		controls = GameManager.player2_controls
		sprite.color = Color.RED


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
	
	# Face direction
	if velocity.x != 0:
		facing = sign(velocity.x)
		$AnimatedSprite2D.flip_h = facing < 0
		$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("idle")
	
	# Update blocking visual
	if is_blocking:
		sprite.color.a = 0.5
	else:
		sprite.color.a = 1.0
	
	move_and_slide()

func _player_input(_delta):
	# Jump
	if Input.is_key_pressed(KEY_W if controls["jump"] == "w" else KEY_UP) and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Movement
	var direction = 0
	if Input.is_key_pressed(KEY_A if controls["left"] == "a" else KEY_LEFT):
		direction -= 1
	if Input.is_key_pressed(KEY_D if controls["right"] == "d" else KEY_RIGHT):
		direction += 1
	
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Block
	is_blocking = Input.is_key_pressed(KEY_H if controls["block"] == "h" else KEY_J)
	
	# Melee attack
	if Input.is_key_pressed(KEY_F if controls["melee"] == "f" else KEY_L) and melee_timer <= 0:
		_melee_attack()
	
	# Fireball
	if Input.is_key_pressed(KEY_G if controls["fireball"] == "g" else KEY_K) and fireball_timer <= 0:
		_shoot_fireball()

func _cpu_behavior(_delta):
	if not opponent:
		return
	
	var distance = global_position.distance_to(opponent.global_position)
	var direction_to_opponent = sign(opponent.global_position.x - global_position.x)
	
	# Movement logic
	if distance > MELEE_RANGE * 1.5:
		# Move towards opponent
		velocity.x = direction_to_opponent * SPEED
	elif distance < MELEE_RANGE * 0.8:
		# Move away slightly
		velocity.x = -direction_to_opponent * SPEED * 0.5
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Attack logic
	if distance <= MELEE_RANGE and melee_timer <= 0:
		_melee_attack()
	elif distance > MELEE_RANGE and distance < 400 and fireball_timer <= 0:
		_shoot_fireball()
	
	facing = sign(direction_to_opponent)
	
	# Random blocking
	is_blocking = randf() < 0.1

func _melee_attack():
	melee_timer = MELEE_COOLDOWN
	is_attacking = true
	
	# Create temporary attack hitbox
	var attack_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(MELEE_RANGE, 50)
	collision.shape = shape
	attack_area.add_child(collision)
	add_child(attack_area)
	
	# Position hitbox in front of player
	facing = self.facing
	attack_area.position.x = MELEE_RANGE / 2 * facing
	
	# Check for hit
	attack_area.body_entered.connect(func(body):
		if body.has_method("take_damage") and body != self:
			body.take_damage(15.0)
	)
	
	# Flash attack indicator
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

func take_damage(amount: float):
	if is_blocking:
		amount *= 0.5
	
	health -= amount
	health = max(0, health)
	
	# Update GameManager
	if player_number == 1:
		GameManager.player1_health = health
	else:
		GameManager.player2_health = health
	
	# Flash white on hit
	var original_color = sprite.color
	sprite.color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(sprite):
		sprite.color = original_color

func set_opponent(new_opponent: CharacterBody2D):
	opponent = new_opponent
