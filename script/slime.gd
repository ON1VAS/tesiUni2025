extends CharacterBody2D

# ===== PHYSICS SETTINGS =====
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var movement_speed: float = 80.0
var jump_force: float = 500.0
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
var damage_dealt: bool = false
var hitbox_active: bool = false
var jump_start_time: float = 0.0
var initial_jump_position: Vector2 = Vector2.ZERO

# Stati del salto
enum JumpState { ANTICIPATION, ASCENDING, FALLING, LANDING }
var jump_state = JumpState.ANTICIPATION

# Aggiungi queste variabili per controllare il salto
var max_jump_speed: float = 300.0  # Velocità massima orizzontale durante il salto
var min_jump_distance: float = 50.0  # Distanza minima per saltare
var max_jump_height: float = 180.0  # Altezza massima del salto

# ===== NODES =====
@onready var player: Node2D = get_tree().get_first_node_in_group("giocatore") as Node2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var slam_hitbox: CollisionShape2D = $SlamHitbox/CollisionShape2D
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
	$SlamHitbox.set_collision_layer_value(1, true)  # Enable layer 2 (player_weapon)
	$SlamHitbox.set_collision_mask_value(1, true) # Enable mask to hit enemies
	$SlamHitbox.body_entered.connect(_on_slam_hitbox_body_entered)
	hurtbox.set_collision_layer_value(6, true)
	hurtbox.set_collision_mask_value(2, true)
	
	# Set collision shape
	var shape = CircleShape2D.new()
	shape.radius = 10.0  # collisione a raggio 12 per prendere tutto lo slime
	collision_shape.shape = shape
	
	# Configure raycast
	ray_front.target_position = Vector2(30.0 * scale.x, 0.0)
	ray_floor.target_position = Vector2(30.0 * scale.x, 30.0)
	
	original_y = global_position.y

func _physics_process(delta: float) -> void:
	# Apply gravity - SEMPRE quando non è a terra
	if not is_on_floor():
		velocity.y += gravity * delta * 1.5
		velocity.y = min(velocity.y, 500)  # Limite di velocità di caduta
	
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
		
	# Debug: mostra lo stato del salto
	print("Stato salto: ", jump_state, " | VelY: ", velocity.y, " | A terra: ", is_on_floor())

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
		abs(player.global_position.y - global_position.y) < 60.0 and
		global_position.distance_to(player.global_position) > min_jump_distance):  # Aggiunto controllo distanza minima
		perform_jump_attack(direction)

func _handle_jump_state(delta: float):
	var elapsed = (Time.get_ticks_msec() / 1000) - jump_start_time
	
	match jump_state:
		JumpState.ANTICIPATION:
			if elapsed > 0.1:  # Fine dell'anticipazione
				jump_state = JumpState.ASCENDING
				anim.play("jump")
				# Calcola la traiettoria del salto con limiti
				var target_x = player.global_position.x
				var distance_x = target_x - global_position.x
				
				# Limita la distanza massima
				if abs(distance_x) > 400:
					distance_x = sign(distance_x) * 400
				
				# Calcola velocità orizzontale con limite massimo
				var jump_time = jump_duration * 0.5
				velocity.x = clamp(distance_x / jump_time, -max_jump_speed, max_jump_speed)
				velocity.y = -jump_force * 0.8  # Riduci la forza verticale
				
				# Salva la posizione iniziale per il calcolo dell'altezza
				initial_jump_position = global_position
				print("Inizio salto - VelX: ", velocity.x, " VelY: ", velocity.y)
		
		JumpState.ASCENDING:
			# Applica una leggera decelerazione orizzontale
			velocity.x = lerp(velocity.x, 0.0, delta * 1.5)
			
			# Controlla se ha raggiunto l'altezza massima o sta iniziando a cadere
			if velocity.y >= 0 or global_position.y <= (initial_jump_position.y - max_jump_height):
				jump_state = JumpState.FALLING
				# Attiva la hitbox per la fase di caduta
				if not hitbox_active:
					slam_hitbox.disabled = false
					hitbox_active = true
					print("HITBOX ATTIVA (caduta)")
		
		JumpState.FALLING:
			# Applica una decelerazione orizzontale più forte
			velocity.x = lerp(velocity.x, 0.0, delta * 3.0)
			
			# Controlla se ha toccato terra
			if is_on_floor():
				_end_jump_with_impact()
		
		JumpState.LANDING:
			# Aspetta che l'animazione di atterraggio finisca
			if not anim.is_playing():
				_end_jump()

func _handle_attack_state(delta: float):
	velocity.x = lerp(velocity.x, 0.0, friction * 2.0 * delta * 60.0)

func perform_jump_attack(direction: Vector2):
	if not is_on_floor():
		return
	
	# Reset delle variabili di stato
	damage_dealt = false
	hitbox_active = false
	jump_state = JumpState.ANTICIPATION
	
	# Prepara l'attacco
	is_jumping = true
	is_falling = false
	attack_direction = Vector2(sign(direction.x), 0).normalized()
	last_attack_time = Time.get_ticks_msec() / 1000
	jump_start_time = last_attack_time
	
	# Animazione di anticipazione
	anim.play("jump_anticipation")
	print("Inizio attacco salto")

func _end_jump():
	# Reset completo dello stato di salto
	is_jumping = false
	jump_state = JumpState.ANTICIPATION
	slam_hitbox.disabled = true
	hitbox_active = false
	velocity = Vector2.ZERO
	anim.play("idle")
	print("Salto completato - Hitbox disattivata")

func _end_jump_with_impact():
	# Impatto con il terreno
	jump_state = JumpState.LANDING
	slam_hitbox.disabled = true
	hitbox_active = false
	
	# Animazione di impatto
	anim.play("slam_impact")
	print("Impatto a terra - Hitbox disattivata")
	
	# Resetta la velocità dopo l'impatto
	velocity = Vector2.ZERO

func take_damage(amount: int):
	if is_dead:
		return
	hp -= amount
	
	if hp > 0:
		anim.play("hurt")
	if hp <= 0:
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
	if body.is_in_group("giocatore") and jump_state == JumpState.FALLING and not damage_dealt:
		body.Damage(damage)
		damage_dealt = true
		print("Danno inflitto al giocatore")
		# Piccolo rimbalzo quando colpisce il giocatore
		velocity.y = -jump_force * 0.3

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "slam_impact" and is_jumping:
		_end_jump()
