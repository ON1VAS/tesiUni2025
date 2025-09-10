# spine.gd
extends CharacterBody2D

# --- Variabili Esportabili ---
@export var lifetime: float = 2.0
@export var animation_name: String = "attack"
@export var gravity: float = 980.0
@export var damage_amount: int = 5
@export var variation: int = 1
@export var throw_speed: float = 200.0
@export var aim_rotates_sprite: bool = true
@export var sprite_forward_angle: float = +PI / 2  # se lo sprite "punta" verso l’alto, usa -PI/2

# --- Target/Direzione ---
var target_direction: Vector2 = Vector2.RIGHT
var has_custom_target: bool = false
var custom_target_pos: Vector2 = Vector2.ZERO

# --- Riferimenti ai Nodi ---
@onready var player = get_tree().get_first_node_in_group("giocatore")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_area: Area2D = $HitboxArea
@onready var despawn_timer: Timer = $DespawnTimer

# --- Variabili Interne ---
var has_hit_target: bool = false
var is_despawning: bool = false
var ground_level: float = 135.0
var signals_connected: bool = false

# --------------------------------------------------------------

func _compute_initial_direction() -> void:
	var tgt := Vector2.ZERO
	if has_custom_target:
		tgt = custom_target_pos
	elif is_instance_valid(player):
		tgt = player.global_position
	else:
		tgt = global_position + Vector2.RIGHT

	var dir := tgt - global_position
	if dir.length() < 0.001:
		dir = Vector2.RIGHT
	target_direction = dir.normalized()

	if aim_rotates_sprite:
		rotation = target_direction.angle() + sprite_forward_angle

func set_target_position(pos: Vector2) -> void:
	has_custom_target = true
	custom_target_pos = pos
	if variation == 3:
		_compute_initial_direction()
		velocity = target_direction * throw_speed

func set_variation(type: int) -> void:
	variation = type
	match variation:
		1:
			if animated_sprite:
				animated_sprite.modulate = Color.WHITE
			damage_amount = 10 * DebuffManager.enemy_damage_multiplier()
			# spine dal terreno: restano fisse
			set_physics_process(false)
		2:
			if animated_sprite:
				animated_sprite.modulate = Color(1, 0.5, 0.5)
			damage_amount = 20 * DebuffManager.enemy_damage_multiplier()
			velocity = Vector2.ZERO
			animation_name = "attaccoaereo"
		3:
			if animated_sprite:
				animated_sprite.modulate = Color(0.5, 0.5, 1)
			damage_amount = 10 * DebuffManager.enemy_damage_multiplier()
			_compute_initial_direction()
			velocity = target_direction * throw_speed
			animation_name = "attaccoaereo"

func _ready() -> void:
	# Collisions del corpo fisico: collide con terreno/muri (mask 1 come nel golem)
	# Metti il proiettile su un layer dedicato se lo usi (qui 7 di esempio)
	set_collision_layer_value(7, true)
	collision_mask = 0
	set_collision_mask_value(1, true)  # terreno/muri

	# Hitbox per danno al player
	if not signals_connected:
		if hitbox_area:
			hitbox_area.collision_layer = 0
			# Assicurati che il "player_hurtbox" stia su questo layer indice 7
			hitbox_area.set_collision_mask_value(7, true)
			hitbox_area.body_entered.connect(_on_hitbox_area_body_entered)
		if despawn_timer:
			despawn_timer.wait_time = lifetime
			despawn_timer.one_shot = true
			despawn_timer.timeout.connect(_on_despawn_timer_timeout)
		signals_connected = true

	# Animazione una volta sola
	if animated_sprite:
		var anim_to_play := animation_name
		if anim_to_play == "" or not animated_sprite.sprite_frames.has_animation(anim_to_play):
			var names := animated_sprite.sprite_frames.get_animation_names()
			if names.size() > 0:
				anim_to_play = names[0]
		animated_sprite.play(anim_to_play)

	# Variation 1 a livello terreno (come nel tuo codice originario)
	if variation == 1:
		global_position.y = ground_level

	# Avvio timer despawn
	if despawn_timer:
		despawn_timer.start()
	else:
		await get_tree().create_timer(lifetime).timeout
		if is_instance_valid(self):
			queue_free()

	# Safety: se siamo variation 3 ma la velocità non è stata impostata (ordine segnali),
	# calcolala ora.
	if variation == 3 and velocity == Vector2.ZERO:
		_compute_initial_direction()
		velocity = target_direction * throw_speed

# --------------------------------------------------------------

func _physics_process(delta: float) -> void:
	match variation:
		2:
			velocity.y += gravity * delta
			move_and_slide()
			if is_on_floor():
				queue_free()
		3:
			# nessun ricalcolo della mira: niente jitter
			move_and_slide()
			# se tocca qualcosa di solido (terreno/muri), despawna
			if get_slide_collision_count() > 0:
				queue_free()

func _on_despawn_timer_timeout() -> void:
	if not is_despawning:
		is_despawning = true
		queue_free()

func _on_hitbox_area_body_entered(body: Node2D) -> void:
	if has_hit_target:
		return
	if body.is_in_group("giocatore") and body.has_method("Damage"):
		body.call("Damage", damage_amount)
		has_hit_target = true
		if despawn_timer and not despawn_timer.is_stopped():
			despawn_timer.stop()
		_on_despawn_timer_timeout()
