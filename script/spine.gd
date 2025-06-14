# spine.gd
extends CharacterBody2D

# --- Variabili Esportabili ---
@export var lifetime: float = 2.0
@export var animation_name: String = "attack"  # Rimossa animazione predefinita
@export var gravity: float = 980.0
@export var damage_amount: int = 5
@export var variation: int = 1 
@export var throw_speed: float = 200.0  # Velocità ridotta
var target_direction: Vector2 = Vector2.ZERO

# --- Riferimenti ai Nodi ---
@onready var player = get_tree().get_first_node_in_group("giocatore")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_area: Area2D = $HitboxArea 
@onready var despawn_timer: Timer = $DespawnTimer

# --- Variabili Interne ---
var has_hit_target: bool = false
var is_despawning: bool = false
var ground_level: float = 0.0
var signals_connected = false  # Flag per controllare i segnali

func set_variation(type: int) -> void:
	variation = type
	match variation:
		1:  # Spine dal terreno
			if animated_sprite: 
				animated_sprite.modulate = Color.WHITE
			damage_amount = 5
			# Disabilita la fisica
			set_physics_process(false)
		2:  # Spine che cadono dal cielo
			if animated_sprite: 
				animated_sprite.modulate = Color(1, 0.5, 0.5)
			damage_amount = 20
			velocity = Vector2.ZERO  # Inizia da fermo
		3:  # Spine lanciate al giocatore
			if animated_sprite: 
				animated_sprite.modulate = Color(0.5, 0.5, 1)
			damage_amount = 10
			# Calcola direzione verso il giocatore
			if player and is_instance_valid(player):
				target_direction = (player.global_position - global_position).normalized()
			else:
				target_direction = Vector2(1, 0)  # Direzione di default

func _ready() -> void:
	ground_level = 135
	
	# Connessione segnali solo se non già connessi
	if !signals_connected:
		if hitbox_area:
			hitbox_area.collision_layer = 0
			hitbox_area.set_collision_mask_value(7, true)
			hitbox_area.body_entered.connect(_on_hitbox_area_body_entered)
		else:
			print_rich("[color=yellow]Spine Warning:[/color] HitboxArea non trovata. Nessun danno.")

		if despawn_timer:
			despawn_timer.wait_time = lifetime
			despawn_timer.one_shot = true
			despawn_timer.timeout.connect(_on_despawn_timer_timeout)
		
		signals_connected = true

	# Riproduci animazione solo se esiste
	if animated_sprite:
		if animation_name != "" && animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.play(animation_name)
		else:
			# Riproduci un'animazione predefinita se disponibile
			if animated_sprite.sprite_frames.get_animation_names().size() > 0:
				animated_sprite.play(animated_sprite.sprite_frames.get_animation_names()[0])
	
	# Per spine di tipo 1, impostale a livello del terreno
	if variation == 1:
		global_position.y = ground_level

	# Avvia il timer se esiste
	if despawn_timer:
		despawn_timer.start()
	else:
		print_rich("[color=yellow]Spine Warning:[/color] DespawnTimer non trovato. Despawn manuale dopo 'lifetime'.")
		await get_tree().create_timer(lifetime).timeout
		if is_instance_valid(self):
			queue_free()

func _physics_process(delta: float) -> void:
	match variation:
		2:  # Spine che cadono dal cielo
			velocity.y += gravity * delta
			move_and_slide()
			animated_sprite.play("attaccoaereo")
			
			# Ferma quando raggiunge il terreno
			if is_on_floor():
				velocity = Vector2.ZERO
				set_physics_process(false)
		3:  # Spine lanciate al giocatore
			velocity = target_direction * throw_speed
			move_and_slide()
			
			# Rimuovi se colpisce qualcosa
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
