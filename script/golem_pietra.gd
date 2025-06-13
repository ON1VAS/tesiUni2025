extends CharacterBody2D

# --- Variabili Esportabili ---
@export var movement_speed: float = 30.0
@export var gravity: float = 980.0 # Assicurati che sia lo stesso del progetto o un valore sensato
@export var hp: int = 150
@export var detection_range_agro: float = 250.0
@export var attack_cooldown_time: float = 2.5

# --- Riferimenti ai Nodi ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # Per flip_h
@onready var player_detection_area: Area2D = $PlayerDetectionArea
@onready var hurtbox: Area2D = $Hurtbox
@onready var spike_spawn_point: Marker2D = $SpikeSpawnPoint
@onready var ray_cast_floor: RayCast2D = $RayCastFloor
@onready var ray_cast_front: RayCast2D = $RayCastFront
@export var float_amplitude: float = 5.0
@export var float_speed: float = 2.0
var float_offset: float = 0.0
var base_y_position: float = 0.0


# --- Logica Spine ---
const SPINE_SCENE = preload("res://scene/spine.tscn") # CAMBIA QUESTO PATH SE NECESSARIO!

# --- Variabili di Stato ---
enum State { IDLE, RUN, ATTACKING, HURT, DEAD }
var current_state: State = State.IDLE
var player_ref: CharacterBody2D = null
var can_attack: bool = true
var time_since_last_attack: float = 0.0

# --- Logica Attacchi ---
var current_attack_type: int = 1 # Per scegliere tra attacco spine 1, 2, 3

func _ready() -> void:
	
	base_y_position = global_position.y
	float_offset = randf_range(0, TAU)  # Valore casuale iniziale
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
	
		# Controlla se SpikeSpawnPoint esiste
	if not spike_spawn_point:
		spike_spawn_point = Node2D.new()
		add_child(spike_spawn_point)
		spike_spawn_point.position = Vector2.ZERO
		print_rich("[color=yellow]Attenzione: SpikeSpawnPoint non trovato, creato uno temporaneo[/color]")
	
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
	change_state(State.IDLE)
	time_since_last_attack = attack_cooldown_time # Permette di attaccare subito all'inizio se il player è in range


func _physics_process(delta: float) -> void:
	# Gravità (solo se non sei in stato DEAD, altrimenti potrebbe cadere all'infinito)
	if player_ref:
		print("Player pos: ", player_ref.global_position, " | Golem pos: ", global_position)
	
	float_offset += float_speed * delta
	global_position.y = base_y_position + sin(float_offset) * float_amplitude
	if current_state == State.HURT:
		if animated_sprite.animation != "hurt" or animated_sprite.frame >= animated_sprite.sprite_frames.get_frame_count("hurt") - 1:
			if player_ref:
				change_state(State.RUN)
			else:
				change_state(State.IDLE)
	
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
			# La logica di ritorno allo stato precedente è in _on_animation_finished
			pass
		State.DEAD:
			# La logica di queue_free è in _on_animation_finished
			pass
	
	# Evita move_and_slide se morto, per permettere all'animazione di morte di completarsi senza movimenti strani
	if current_state != State.DEAD:
		move_and_slide()
		_update_sprite_facing_direction()


func change_state(new_state: State) -> void:
	if current_state == new_state and new_state != State.ATTACKING:
		return
	
	current_state = new_state
	# print("GolemPietra state: ", State.keys()[new_state]) # Debug
	
	if not animated_sprite:
		print_rich("[color=red]GolemPietra: AnimationPlayer non trovato. Impossibile cambiare animazione.[/color]")
		return
	
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
			print("fermo")
			velocity.x = 0
		State.RUN:
			animated_sprite.play("run")
			print("corri")
		State.ATTACKING:
			velocity.x = 0 # Fermati mentre attacchi
			current_attack_type = randi_range(1, 3)
			animated_sprite.play("attack" + str(current_attack_type)) # Es. "attack1", "attack2", "attack3"
			can_attack = false
			time_since_last_attack = 0.0
			print("attaccando")
		State.HURT:
			animated_sprite.play("hurt")
			print("ashia")
			velocity.x = 0
		State.DEAD:
			animated_sprite.play("death")
			print("sn mortop")
			set_physics_process(false) # Stoppa la logica principale
			# Disabilita collisioni
			collision_layer = 0
			collision_mask = 0
			if hurtbox and is_instance_valid(hurtbox): # Controllo aggiuntivo
				hurtbox.queue_free()


func _state_idle() -> void:
	if player_ref:
		change_state(State.RUN)


func _state_run(delta: float) -> void:
	if not player_ref:
		change_state(State.IDLE)
		return
	# Se il player è nell'area di detection E possiamo attaccare
	if can_attack: 
		# Scegli casualmente tra gli attacchi disponibili
		current_attack_type = randi_range(1, 3)
		change_state(State.ATTACKING)
		return
	
	# Movimento verso il giocatore se non si sta attaccando
	var direction_to_player = (player_ref.global_position - global_position).normalized()
	velocity.x = direction_to_player.x * movement_speed
	
	# Controllo ostacoli/precipizi (base)
	if is_on_floor() and (ray_cast_front.is_colliding() or not ray_cast_floor.is_colliding()):
		velocity.x = 0 # Fermati per non sbattere/cadere
	
	# Il facing è gestito da _update_sprite_facing_direction


func _state_attacking() -> void:
	# L'azione di spawn delle spine è gestita dalla chiamata di metodo nell'AnimationPlayer.
	# Mantieni il Golem girato verso il giocatore durante l'attacco (gestito da _update_sprite_facing_direction).
	pass


# --- Funzione di Attacco (chiamata tramite AnimationPlayer method call tracks) ---
func _spawn_spikes(attack_variation: int = 1) -> void:
	
	if not SPINE_SCENE:
		print_rich("[color=red]Errore: Scena delle spine non caricata! Controlla il path.[/color]")
		return
	if not spike_spawn_point:
		print_rich("[color=red]Errore: SpikeSpawnPoint non trovato! Le spine non possono essere spawnate.[/color]")
		return
	if not is_instance_valid(get_tree().current_scene):
		print_rich("[color=red]Errore: La scena corrente non è valida. Impossibile aggiungere le spine.[/color]")
		return
	
	var spikes_instance = SPINE_SCENE.instantiate()
	
	 # Passa esplicitamente la variazione d'attacco
	spikes_instance.set_variation(attack_variation)
	
	# Usa la posizione globale del golem come base
	var spawn_position = global_position
	
	# Personalizza la posizione in base al tipo di attacco
	match attack_variation:
		1: # Spine dal terreno
			spawn_position.y += 20  # Appena sopra il golem
		2: # Spine sopra la testa
			spawn_position.y -= 50  # Sopra il golem
		3: # Spine dirette verso il player
			if player_ref:
				# Direzione verso il player
				var direction = (player_ref.global_position - global_position).normalized()
				spawn_position += direction * 30  # Davanti al golem
	
	spikes_instance.global_position = spawn_position
	spikes_instance.rotation_degrees = randi_range(0, 360)  # Rotazione casuale
	
	get_tree().current_scene.add_child(spikes_instance)
	print("Spine spawnate! Tipo: ", attack_variation)



func take_damage(amount: int) -> void:
	if current_state == State.DEAD or current_state == State.HURT:
		return
	
	hp -= amount
	# print("GolemPietra colpito! Vita rimanente: ", hp)
	
	if hp <= 0:
		if current_state != State.DEAD: # Evita di chiamare change_state(DEAD) più volte
			change_state(State.DEAD)
	else:
		if current_state != State.HURT: # Evita di chiamare change_state(HURT) se già in HURT
			change_state(State.HURT)


# Segnale dall'AnimationPlayer
func _on_animation_finished() -> void:
	var current_anim = animated_sprite.animation
	
	if current_anim.begins_with("attack"):
		# Dopo un attacco, torna a idle o run
		if player_ref:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
	elif current_anim == "hurt":
		# Dopo essere stato colpito, torna a idle o run
		if player_ref:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
	elif current_anim == "death":
		queue_free() # Rimuovi il Golem dalla scena


func _on_player_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("giocatore"):
		player_ref = body as CharacterBody2D
		print("Player rilevato!")
		
		# Forza la transizione di stato se siamo in HURT
		if current_state == State.HURT:
			change_state(State.RUN)
		elif current_state == State.IDLE:
			change_state(State.RUN)


func _on_player_detection_area_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null
		# Se il Golem stava inseguendo o attaccando (o era appena tornato in RUN dopo un attacco)
		# e il giocatore esce, dovrebbe tornare a IDLE.
		if current_state != State.IDLE:
			change_state(State.IDLE)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_weapon"):
		var damage_amount = 10 # Danno di default
		if area.has_method("get_damage"): # Metodo preferito
			damage_amount = area.get_damage()
		elif "damage" in area: # Fallback a proprietà esportata
			damage_amount = area.damage
		
		take_damage(damage_amount)


func _update_sprite_facing_direction() -> void:
	# Se si muove (stato RUN e velocità effettiva)
	if current_state == State.RUN and abs(velocity.x) > 0.1:
		animated_sprite.flip_h = velocity.x < 0
	# Se sta attaccando o è fermo (IDLE/HURT) ma c'è un player, si gira verso il player
	elif player_ref and (current_state == State.ATTACKING or current_state == State.IDLE or current_state == State.HURT):
		if player_ref.global_position.x < global_position.x:
			animated_sprite.flip_h = true
		elif player_ref.global_position.x > global_position.x:
			animated_sprite.flip_h = false
	# Altrimenti (es. morto, o nessuna velocità e nessun player_ref), non cambiare flip_h
