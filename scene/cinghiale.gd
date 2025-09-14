extends CharacterBody2D

# ===== IMPOSTAZIONI FISICHE =====
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var movement_speed: float = 120.0
var charge_speed_multiplier: float = 2.8
var max_floor_angle = deg_to_rad(45)
var friction: float = 0.15
var acceleration: float = 0.25

# ===== VARIABILI NEMICO =====
var hp: int = 20
var damage: int = 15
var min_distance: float = 40.0
var is_attacking: bool = false
var is_charging: bool = false
var attack_direction = Vector2.ZERO
var attack_cooldown: float = 1.5
var last_attack_time: float = 0.0
var charge_duration: float = 1.2

#servono pe capire quando il nemico è morto e far progredire i progressi della wave
signal dead
var death_sig_emitted = 0
var is_dead = false

# ===== NODI =====
@onready var player: Node2D = get_tree().get_first_node_in_group("giocatore") as Node2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var sword_hitbox: CollisionShape2D = $Incornata/CollisionShape2D
@onready var hitbox_timer: Timer = $HitboxTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ray_front: RayCast2D = $RayCastFront
@onready var ray_floor: RayCast2D = $RayCastFloor
@onready var incornata: Area2D = $Incornata
@onready var audiohurt = $CinghialeHurt
@onready var audiodeath = $CinghialeDeath


@onready var effects = $Effects
@onready var hurt_timer = $hurtAnimTimer

# ===== PROPRIETÀ ATTACCHI =====
var attack_properties = {
	"attack": {"delay": 0.1, "duration": 0.4},
	"charge_attack": {"delay": 0.2, "duration": 0.6}
}

func _ready():
	# Configurazione iniziale
	effects.play("RESET")
	anim.play("move")
	sword_hitbox.disabled = true
	floor_max_angle = max_floor_angle
	$Incornata.set_collision_layer_value(2, true)  # Abilita layer 2 (player_weapon)
	$Incornata.set_collision_mask_value(3, true) #abilita la maschera per colpire i nemici
	$Incornata.body_entered.connect(_on_incornata_body_entered)
	hurtbox.set_collision_layer_value(2, true)
	hurtbox.set_collision_mask_value(3, true)
	hurtbox.set_collision_layer_value(6, true) # Layer "enemy_hurtbox"
	hurtbox.set_collision_mask_value(2, true) # Maschera "player_weapon"
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	# Imposta forma collisione
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30.0, 20.0) 
	collision_shape.shape = shape
	
	# Configura raycast
	ray_front.target_position = Vector2(40.0 * attack_direction.x, 0.0)
	ray_floor.target_position = Vector2(40.0 * scale.x, 30.0)

func _physics_process(delta: float) -> void:
	# Applica gravità
	if not is_on_floor():
		velocity.y += gravity * delta * 1.2
	else:
		velocity.y = min(velocity.y, 5.0)
	
	var facing_dir = -sign(anim.scale.x) if anim.scale.x != 0 else 1  # Direzione corrente
	ray_front.target_position = Vector2(40.0 * attack_direction.x, 0.0)
	ray_floor.target_position = Vector2(40.0 * facing_dir, 30.0)
	if facing_dir > 0:
		incornata.position.x = 30*facing_dir  # Aggiorna posizione incornata
	else: 	incornata.position.x = 5*facing_dir  # Aggiorna posizione incornata
	# Aggiorna raycast
	ray_front.force_raycast_update()
	ray_floor.force_raycast_update()
	
	# Gestione stati
	if is_charging:
		_handle_charge_state(delta)
	elif is_attacking:
		_handle_attack_state(delta)
	elif hp > 0:
		_handle_normal_state(delta)
	
	# Applica movimento
	move_and_slide()
	
	
	# Controllo caduta piattaforme
	if is_on_floor() and not ray_floor.is_colliding() and not is_charging:
		velocity.x = 0.0

func _handle_normal_state(delta: float):
	var direction = (player.global_position - global_position).normalized()
	
	
	# Movimento base
	if global_position.distance_to(player.global_position) > min_distance:
		velocity.x = lerp(velocity.x, direction.x * movement_speed, acceleration * delta * 60.0)
		
		# Flip sprite
		if direction.x > 0:
			anim.scale.x = -abs(anim.scale.x)
		elif direction.x < 0:
			anim.scale.x = abs(anim.scale.x)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta * 60.0)
	
	# Controllo attacco
	if (Time.get_ticks_msec() / 1000.0 - last_attack_time > attack_cooldown and 
		is_on_floor() and 
		abs(player.global_position.y - global_position.y) < 50.0):
		perform_charge_attack(direction)

func _handle_charge_state(delta: float):
	# Movimento durante la carica
	velocity.x = attack_direction.x * movement_speed * charge_speed_multiplier
	
	
	# Controllo collisioni
	if ray_front.is_colliding() :
		var collider = ray_front.get_collider()
		if collider != null and not collider.is_in_group("giocatore"):
			_end_charge_with_impact()
		elif collider != null and collider.is_in_group("giocatore"):
		# Non fare nulla, il player sarà gestito da Incornata
			pass
	elif is_on_wall():
		_end_charge_with_impact()
	elif not is_on_floor():
		_end_charge()

func _handle_attack_state(delta: float):
	velocity.x = lerp(velocity.x, 0.0, friction * 2.0 * delta * 60.0)

func perform_charge_attack(direction: Vector2):
	if not is_on_floor():
		return
	
	# Preparazione attacco
	is_charging = true
	attack_direction = Vector2(sign(direction.x), 0).normalized()
	last_attack_time = Time.get_ticks_msec() / 1000.0
	
	# Animazione
	anim.play("charge_anticipation")
	await get_tree().create_timer(0.3).timeout
	
	if is_charging:  # Se non è stato interrotto
		anim.play("charge_attack")
		sword_hitbox.call_deferred("set_disabled", false)
		
		# Timer durata carica
		await get_tree().create_timer(charge_duration).timeout
		_end_charge()

func _end_charge():
	is_charging = false
	sword_hitbox.call_deferred("set_disabled", true)
	velocity.x = 0.0
	anim.play("move")

func _end_charge_with_impact():
	# Effetto impatto
	velocity.x = -attack_direction.x * movement_speed * 0.5
	velocity.y = -150
	is_charging = false
	sword_hitbox.call_deferred("set_disabled", true)
	anim.play("hurt")
	await get_tree().create_timer(0.5).timeout
	anim.play("move")

func take_damage(amount: int):
	hp -= amount
	anim.play("hurt")
	effects.play("hurt_animation")
	if hp <= 0:
		_die()
	else:
		audiohurt.play()
		await anim.animation_finished
		anim.play("move")

func _die():
	set_collision_layer_value(1, false)
	audiodeath.play()
	anim.play("death")
	set_physics_process(false)
	await anim.animation_finished
	if death_sig_emitted == 0:
			dead.emit()
			death_sig_emitted += 1
	queue_free()

# ===== SEGNALI =====
func _on_hurtbox_area_entered(area: Area2D):
	if area.is_in_group("player_weapon") and !is_dead:
		take_damage(player.damage)

func _on_incornata_body_entered(body: Node2D):
	if body.is_in_group("giocatore"):
		body.Damage(damage)
		call_deferred("_end_charge_with_impact")

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "charge_anticipation" and is_charging:
		anim.play("charge_attack")


func _on_hurt_anim_timer_timeout() -> void:
	effects.play("RESET")
