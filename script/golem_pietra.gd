extends CharacterBody2D

# --- Variabili Esportabili ---
@export var movement_speed: float = 30.0
@export var gravity: float = 980.0
@export var hp: int = 150
@export var detection_range_agro: float = 250.0 # Raggio in cui inizia a seguire e può attaccare
@export var attack_cooldown_time: float = 2.5 # Tempo tra un attacco e l'altro
# @export var attack_range: float = 80.0 # Non più strettamente necessario se attacca ovunque in detection_range

# --- Riferimenti ai Nodi ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_detection_area: Area2D = $PlayerDetectionArea
@onready var hurtbox: Area2D = $Hurtbox
@onready var spike_spawn_point: Marker2D = $SpikeSpawnPoint # Assicurati che esista
@onready var ray_cast_floor: RayCast2D = $RayCastFloor
@onready var ray_cast_front: RayCast2D = $RayCastFront

# --- Logica Spine ---
const SPINE_SCENE = preload("res://scene/spine.tscn") # CAMBIA QUESTO PATH SE NECESSARIO!

# --- Variabili di Stato ---
enum State { IDLE, RUN, ATTACKING, HURT, DEAD }
var current_state: State = State.IDLE
var player_ref: CharacterBody2D = null # Ora specifico che ci aspettiamo un CharacterBody2D per il giocatore
var can_attack: bool = true
var time_since_last_attack: float = 0.0

# --- Logica Attacchi ---
var current_attack_type: int = 1 # Per scegliere tra attacco spine 1, 2, 3

func _ready() -> void:
	set_collision_layer_value(3, true)  # Layer "enemy"
	set_collision_mask_value(1, true)   # Maschera "world" (terreno, muri)

	hurtbox.set_collision_layer_value(6, true)  # Layer "enemy_hurtbox"
	hurtbox.set_collision_mask_value(2, true) # Maschera "player_weapon"
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	player_detection_area.body_entered.connect(_on_player_detection_area_body_entered)
	player_detection_area.body_exited.connect(_on_player_detection_area_body_exited)
	
	var detection_shape = player_detection_area.get_node_or_null("CollisionShape2D")
	if detection_shape and detection_shape is CollisionShape2D:
		if detection_shape.shape is CircleShape2D:
			(detection_shape.shape as CircleShape2D).radius = detection_range_agro
		# Aggiungi logica per altre forme se necessario

	animated_sprite.animation_finished.connect(_on_animation_finished)
	change_state(State.IDLE)
	time_since_last_attack = attack_cooldown_time


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if not can_attack:
		time_since_last_attack += delta
		if time_since_last_attack >= attack_cooldown_time:
			can_attack = true
			time_since_last_attack = 0.0

	match current_state:
		State.IDLE:
			_state_idle()
		State.RUN:
			_state_run(delta)
		State.ATTACKING:
			_state_attacking()
		State.HURT:
			pass
		State.DEAD:
			pass

	move_and_slide()
	_update_sprite_facing_direction()


func change_state(new_state: State) -> void:
	if current_state == new_state and new_state != State.ATTACKING: # Permette di ri-entrare in ATTACKING per scegliere un nuovo tipo
		return
	
	# Se si stava già attaccando e si vuole attaccare di nuovo, permettilo se l'animazione precedente è finita
	# Questo viene gestito da _on_animation_finished
	
	current_state = new_state
	# print("GolemPietra state: ", State.keys()[new_state])

	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
			velocity.x = 0
		State.RUN:
			animated_sprite.play("run")
		State.ATTACKING:
			velocity.x = 0 # Fermati mentre attacchi
			current_attack_type = randi_range(1, 3)
			animated_sprite.play("attack" + str(current_attack_type))
			can_attack = false
			time_since_last_attack = 0.0
		State.HURT:
			animated_sprite.play("hurt")
			velocity.x = 0
		State.DEAD:
			animated_sprite.play("death")
			set_physics_process(false)
			collision_layer = 0
			collision_mask = 0
			if hurtbox: hurtbox.queue_free()


func _state_idle() -> void:
	# Se il player entra nella detection area (gestito dal segnale), cambia stato.
	# Questo stato è principalmente per quando non c'è un player target.
	if player_ref: # Se per caso il player è stato rilevato e poi si è usciti dalla logica di run
		change_state(State.RUN)


func _state_run(delta: float) -> void:
	if not player_ref:
		change_state(State.IDLE)
		return

	var direction_to_player = (player_ref.global_position - global_position).normalized()
	# var distance_to_player = global_position.distance_to(player_ref.global_position) # Non più strettamente necessario per la decisione di attaccare qui

	# Se il player è nell'area di detection E possiamo attaccare
	if can_attack: # Il check se player_ref esiste è già fatto sopra
		change_state(State.ATTACKING)
	else:
		# Muoviti verso il giocatore se non stai attaccando
		velocity.x = direction_to_player.x * movement_speed

		if is_on_floor() and (ray_cast_front.is_colliding() or not ray_cast_floor.is_colliding()):
			velocity.x = 0
		
		if direction_to_player.x != 0:
			animated_sprite.flip_h = direction_to_player.x < 0


func _state_attacking() -> void:
	# L'azione di spawn delle spine è gestita dalla chiamata di metodo nell'animazione.
	# Mantieni il Golem girato verso il giocatore durante l'attacco.
	if player_ref:
		var direction_to_player = (player_ref.global_position - global_position).normalized()
		if direction_to_player.x != 0:
			animated_sprite.flip_h = direction_to_player.x < 0


# --- Funzione di Attacco (chiamata tramite AnimationPlayer o AnimatedSprite2D method call tracks) ---
func _spawn_spikes(attack_variation: int = 1) -> void:
	if not SPINE_SCENE:
		print_rich("[color=red]Errore: Scena delle spine non caricata! Controlla il path.[/color]")
		return
	if not spike_spawn_point:
		print_rich("[color=red]Errore: SpikeSpawnPoint non trovato! Le spine non possono essere spawnate.[/color]")
		return

	var spikes_instance = SPINE_SCENE.instantiate()
	
	# Qui potresti voler configurare le spine diversamente in base a 'attack_variation'
	# Ad esempio, la scena 'spine.tscn' potrebbe avere una funzione per settare un pattern o un effetto.
	if spikes_instance.has_method("set_variation"):
		spikes_instance.set_variation(attack_variation)
	elif "variation" in spikes_instance: # Se 'variation' è una proprietà @export var
		spikes_instance.variation = attack_variation
	
	# Posiziona le spine (potrebbe essere relativo al Golem o al Giocatore a seconda del design)
	# Qui usiamo spike_spawn_point del Golem.
	spikes_instance.global_position = spike_spawn_point.global_position

	# Orienta le spine (opzionale, se le spine hanno una direzione)
	# if player_ref:
	#     var direction_to_player = (player_ref.global_position - spikes_instance.global_position).normalized()
	#     spikes_instance.rotation = direction_to_player.angle() # Esempio
		
	get_tree().current_scene.add_child(spikes_instance) # Aggiungi alla scena principale
	# print("GolemPietra: Spine (variazione ", attack_variation, ") evocate!")


func take_damage(amount: int) -> void:
	if current_state == State.DEAD or current_state == State.HURT:
		return

	hp -= amount
	# print("GolemPietra colpito! Vita rimanente: ", hp)

	if hp <= 0:
		change_state(State.DEAD)
	else:
		change_state(State.HURT)


func _on_animation_finished() -> void:
	var current_animation_name = animated_sprite.animation
	
	if current_animation_name.begins_with("attack"):
		if player_ref: # Se il player è ancora targettabile
			change_state(State.RUN) # Torna a inseguire/valutare se attaccare di nuovo
		else:
			change_state(State.IDLE)
	elif current_animation_name == "hurt":
		if player_ref:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
	elif current_animation_name == "death":
		queue_free()


func _on_player_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("giocatore") and body is CharacterBody2D:
		player_ref = body as CharacterBody2D # Salva il riferimento al giocatore
		if current_state == State.IDLE:
			change_state(State.RUN)


func _on_player_detection_area_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null # "Dimentica" il giocatore
		if current_state == State.RUN or current_state == State.ATTACKING: # Se lo stava inseguendo o attaccando
			change_state(State.IDLE)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_weapon"):
		var damage_amount = 10
		if area.has_method("get_damage"):
			damage_amount = area.get_damage()
		elif "damage" in area:
			damage_amount = area.damage
		
		take_damage(damage_amount)


func _update_sprite_facing_direction() -> void:
	# Se si muove, si gira in base alla velocità
	if velocity.x > 0.1:
		animated_sprite.flip_h = false
	elif velocity.x < -0.1:
		animated_sprite.flip_h = true
	# Se non si muove (es. idle o attacking) e c'è un player, si gira verso il player
	elif player_ref:
		if player_ref.global_position.x > global_position.x:
			animated_sprite.flip_h = false
		elif player_ref.global_position.x < global_position.x:
			animated_sprite.flip_h = true
