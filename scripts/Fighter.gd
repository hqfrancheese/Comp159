# Fighter.gd
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
		$AnimatedSprite2D.sprite_frames = preload("res://assets/sprites/Fire Wizard/firewizard.tres") 
	else:
		controls = GameManager.player2_controls
		sprite.color = Color.RED
		$AnimatedSprite2D.sprite_frames = preload("res://assets/sprites/Lightning Mage/lightningmage.tres")

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
	
	# Update animation smoothly
	_update_animation()
	
	# Update blocking visual
	if is_blocking:
		sprite.color.a = 0.5
	else:
		sprite.color.a = 1.0
	
	move_and_slide()

func _update_animation():
	var new_animation = "idle"
	
	# Priority system for animations
	if is_blocking:
		new_animation = "block"
	elif not is_on_floor():
		# In air - don't change animation, keep current one smooth
		if current_animation == "idle" or current_animation == "run":
			new_animation = current_animation  # Keep whatever was playing
		else:
			new_animation = "idle"
	elif abs(velocity.x) > 10:  # Only play run if actually moving
		new_animation = "run"
	else:
		new_animation = "idle"
	
	# Only change animation if it's different
	if new_animation != current_animation:
		current_animation = new_animation
		$AnimatedSprite2D.play(current_animation)
	
	# Update facing direction
	if not is_cpu:
		# Player: instant direction change
		if velocity.x != 0:
			facing = sign(velocity.x)
	else:
		# CPU: only change direction when on ground and moving significantly
		if is_on_floor() and abs(velocity.x) > 50:
			facing = sign(velocity.x)
	
	$AnimatedSprite2D.flip_h = facing < 0

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
	var health_ratio = health / 100.0
	var opponent_health_ratio = opponent.health / 100.0
	
	# AI difficulty settings
	var aggression = 0.7  # Higher = more aggressive (0.0 to 1.0)
	var ideal_distance = MELEE_RANGE * 1.8  # Preferred fighting distance
	
	# Adjust aggression based on health
	if health_ratio < 0.3:
		aggression = 0.4  # Play more defensive when low health
		ideal_distance = MELEE_RANGE * 2.5  # Keep more distance when low
	elif opponent_health_ratio < 0.3:
		aggression = 0.9  # Go for the kill
		ideal_distance = MELEE_RANGE * 1.2  # Get closer for the finish
	
	# Jump occasionally (dodge fireballs, add variety)
	if is_on_floor() and randf() < 0.08:
		velocity.y = JUMP_VELOCITY
	
	# Don't change movement direction while in air (reduces flickering)
	var can_change_direction = is_on_floor()
	
	# Tactical spacing - maintain ideal distance
	var distance_error = distance - ideal_distance
	var move_intensity = 0.0
	
	if can_change_direction:  # Only adjust movement on ground
		if abs(distance_error) > 30:  # Only move if significantly off ideal distance
			if distance_error > 0:
				# Too far - approach
				move_intensity = 0.6
			else:
				# Too close - back off
				move_intensity = -0.4
		else:
			# At ideal range - strafe/circle
			if randf() < 0.3:
				move_intensity = randf_range(-0.3, 0.3)  # Random strafing
			else:
				move_intensity = 0  # Hold position
		
		# Apply movement with some randomness
		velocity.x = direction_to_opponent * move_intensity * SPEED
		
		# Add pauses/hesitation for realism (not constant movement)
		if randf() < 0.15:
			velocity.x = 0  # Stand still briefly
	# else: keep current velocity.x when in air (no flickering)
	
	# Smart blocking decisions
	is_blocking = false
	
	# Block when opponent attacks
	if opponent.is_attacking and distance <= MELEE_RANGE * 1.5:
		is_blocking = randf() < 0.7
	# Block when too close and defensive
	elif distance < MELEE_RANGE * 0.8 and health_ratio < 0.5:
		is_blocking = randf() < 0.4
	# Occasional random block (feint defense)
	elif randf() < 0.05:
		is_blocking = true
	
	# Attack decision making with better timing
	var should_attack = false
	
	# Only consider attacking at good ranges
	if distance > MELEE_RANGE * 0.7 and distance < MELEE_RANGE * 2.5:
		should_attack = randf() < (aggression * 0.3)  # Less spam, more tactical
	
	if should_attack and not is_blocking:
		# Prefer different attacks at different ranges
		if distance <= MELEE_RANGE * 1.2 and melee_timer <= 0:
			# Close range melee
			if randf() < 0.6:  # 60% chance
				_melee_attack()
		elif distance > MELEE_RANGE * 1.3 and distance < 380 and fireball_timer <= 0:
			# Medium range fireball
			if randf() < 0.5:  # 50% chance
				_shoot_fireball()
	
	# Don't block while attacking
	if melee_timer > 0 or fireball_timer > 0.5:
		is_blocking = false
	
	# Always face opponent
	facing = direction_to_opponent

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
	
# func _input(event):
	#if event.is_action_pressed("h"):
		#is_blocking = true
		#anim.play("h")
	#elif event.is_action_released("h"):
		#is_blocking = false
