extends CharacterBody2D

# ===== PHYSICS SETTINGS =====
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var movement_speed: float = 80.0
var jump_force: float = 400.0
var max_floor_angle = deg_to_rad(45)
var friction: float = 0.15
var acceleration: float = 0.25

# ===== ENEMY VARIABLES =====
var hp: int = 15
var damage: int = 10
var min_distance: float = 100.0
var is_attacking: bool = false
var is_jumping: bool = false
var attack_direction = Vector2.ZERO
var attack_cooldown: float = 3.0
var last_attack_time: float = 0.0
var jump_duration: float = 1.0
var is_falling: bool = false
var original_y: float = 0.0
var jump_height: float = 150.0

# ===== NODES =====
@onready var player: Node2D = get_tree().get_first_node_in_group("giocatore") as Node2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var slam_hitbox: CollisionShape2D = $SlamHitbox/CollisionShape2D
@onready var hitbox_timer: Timer = $HitboxTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ray_front: RayCast2D = $RayCastFront
@onready var ray_floor: RayCast2D = $RayCastFloor

#servono pe capire quando il nemico è morto e far progredire i progressi della wave
signal dead
var death_sig_emitted = 0
var is_dead = false

func _ready():
	# Initial configuration
	anim.play("idle")
	slam_hitbox.disabled = true
	floor_max_angle = max_floor_angle
	$SlamHitbox.set_collision_layer_value(2, true)  # Enable layer 2 (player_weapon)
	$SlamHitbox.set_collision_mask_value(1, true) # Enable mask to hit enemies
	$SlamHitbox.body_entered.connect(_on_slam_hitbox_body_entered)
	hurtbox.set_collision_layer_value(6, true)
	hurtbox.set_collision_mask_value(2, true)
	
	# Set collision shape
	var shape = CircleShape2D.new()
	shape.radius = 12.0  # collisione a raggio 12 per prendere tutto lo slime
	collision_shape.shape = shape
	
	# Configure raycast
	ray_front.target_position = Vector2(30.0 * scale.x, 0.0)
	ray_floor.target_position = Vector2(30.0 * scale.x, 30.0)
	
	original_y = global_position.y

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor() and not is_jumping:
		velocity.y += gravity * delta * 1.5
	else:
		velocity.y = min(velocity.y, gravity * 2)
	
	# Update raycast
	ray_front.force_raycast_update()
	ray_floor.force_raycast_update()
	
	# State handling
	if is_jumping:
		_handle_jump_state(delta)
	elif is_attacking:
		_handle_attack_state(delta)
	elif hp > 0:
		_handle_normal_state(delta)
	
	# Apply movement
	move_and_slide()
	
	# Platform edge check
	if is_on_floor() and not ray_floor.is_colliding() and not is_jumping:
		velocity.x = 0.0

func _handle_normal_state(delta: float):
	var direction = (player.global_position - global_position).normalized()
	
	# Basic movement
	if global_position.distance_to(player.global_position) > min_distance:
		velocity.x = lerp(velocity.x, direction.x * movement_speed, acceleration * delta * 60.0)
		
		# Flip sprite
		if direction.x != 0:
			anim.scale.x = sign(direction.x) * abs(anim.scale.x)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta * 60.0)
		anim.play("idle")
	
	# Attack check
	if (Time.get_ticks_msec() / 1000.0 - last_attack_time > attack_cooldown and 
		is_on_floor() and 
		abs(player.global_position.y - global_position.y) < 60.0):
		perform_jump_attack(direction)

func _handle_jump_state(delta: float):
	# During jump arc
	if not is_falling:
		# Calculate jump arc
		var jump_progress = (Time.get_ticks_msec() / 1000.0 - last_attack_time) / (jump_duration * 0.5)
		if jump_progress >= 1.0:
			is_falling = true
			velocity.y = gravity  # Start falling
		else:
			# Parabolic jump movement
			velocity.y = -jump_force * (1 - jump_progress)
	else:
		# Falling down
		velocity.y += gravity * delta * 2.0
		
		# Check if landed
		if is_on_floor():
			_end_jump_with_impact()

func _handle_attack_state(delta: float):
	velocity.x = lerp(velocity.x, 0.0, friction * 2.0 * delta * 60.0)

func perform_jump_attack(direction: Vector2):
	if not is_on_floor():
		return
	
	# Prepare attack
	is_jumping = true
	is_falling = false
	attack_direction = Vector2(sign(direction.x), 0).normalized()
	last_attack_time = Time.get_ticks_msec() / 1000.0
	
	# Animation
	anim.play("jump_anticipation")
	await get_tree().create_timer(0.5).timeout
	
	if is_jumping:  # If not interrupted
		anim.play("jump")
		
		# Calculate jump trajectory to go over player
		var target_x = player.global_position.x + (player.velocity.x * 0.3)  # Lead the target slightly
		var distance_x = target_x - global_position.x
		var jump_time = jump_duration * 0.5
		velocity.x = distance_x / jump_time
		velocity.y = -jump_force
		
		# Enable hitbox when falling
		await get_tree().create_timer(jump_duration * 0.5).timeout
		if is_jumping:
			slam_hitbox.call_deferred("set_disabled", false)
		
		# Timer for full jump duration
		await get_tree().create_timer(jump_duration * 0.5).timeout
		if is_jumping:
			_end_jump()

func _end_jump():
	is_jumping = false
	is_falling = false
	slam_hitbox.call_deferred("set_disabled", true)
	velocity = Vector2.ZERO
	anim.play("idle")

func _end_jump_with_impact():
	# Impact effect
	is_jumping = false
	is_falling = false
	slam_hitbox.call_deferred("set_disabled", true)
	
	# Screen shake or other effects could be added here
	anim.play("slam_impact")
	await get_tree().create_timer(0.3).timeout
	anim.play("idle")

func take_damage(amount: int):
	if is_dead:
		return
	hp -= amount
	
	if hp > 0:
		anim.play("hurt")
	if hp <= 0:
		is_dead = true
		set_collision_layer_value(1, false)
		anim.play("death")
		set_physics_process(false)
		await anim.animation_finished
		if death_sig_emitted == 0:
			print("slime: so morto")
			dead.emit()
			death_sig_emitted += 1
		queue_free()


# ===== SIGNALS =====
func _on_hurtbox_area_entered(area: Area2D):
	if area.is_in_group("player_weapon"):
		take_damage(damage)

func _on_slam_hitbox_body_entered(body: Node2D):
	if body.is_in_group("giocatore"):
		body.Damage(damage)
		# Small bounce when hitting player
		velocity.y = -jump_force * 0.3

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "jump_anticipation" and is_jumping:
		anim.play("jump")
