extends CharacterBody2D

# --- Variabili Esportabili ---
@export var movement_speed: float = 30.0
@export var gravity: float = 980.0 # Assicurati che sia lo stesso del progetto o un valore sensato
@export var hp: int = 150
@export var detection_range_agro: float = 250.0
@export var attack_cooldown_time: float = 2.5

# --- Riferimenti ai Nodi ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # Per flip_h
@onready var animation_player: AnimationPlayer = $AnimationPlayer # Per gestire le animazioni e i method calls
@onready var player_detection_area: Area2D = $PlayerDetectionArea
@onready var hurtbox: Area2D = $Hurtbox
@onready var spike_spawn_point: Marker2D = $SpikeSpawnPoint
@onready var ray_cast_floor: RayCast2D = $RayCastFloor
@onready var ray_cast_front: RayCast2D = $RayCastFront

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

	# Connetti il segnale animation_finished dall'AnimationPlayer
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
	else:
		print_rich("[color=red]ATTENZIONE: AnimationPlayer non trovato per GolemPietra. Le animazioni e i method call non funzioneranno correttamente.[/color]")


	change_state(State.IDLE)
	time_since_last_attack = attack_cooldown_time # Permette di attaccare subito all'inizio se il player è in range


func _physics_process(delta: float) -> void:
	# Gravità (solo se non sei in stato DEAD, altrimenti potrebbe cadere all'infinito)
	if current_state != State.DEAD and not is_on_floor():
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

	if not animation_player:
		print_rich("[color=red]GolemPietra: AnimationPlayer non trovato. Impossibile cambiare animazione.[/color]")
		return

	match current_state:
		State.IDLE:
			animation_player.play("idle")
			velocity.x = 0
		State.RUN:
			animation_player.play("run")
		State.ATTACKING:
			velocity.x = 0 # Fermati mentre attacchi
			current_attack_type = randi_range(1, 3)
			animation_player.play("attack" + str(current_attack_type)) # Es. "attack1", "attack2", "attack3"
			can_attack = false
			time_since_last_attack = 0.0
		State.HURT:
			animation_player.play("hurt")
			velocity.x = 0
		State.DEAD:
			animation_player.play("death")
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
	if can_attack: # Il check se player_ref esiste è già fatto implicitamente (non saremmo in RUN)
		change_state(State.ATTACKING)
		return # Esci subito per non eseguire il codice di movimento sottostante

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
	
	if spikes_instance.has_method("set_variation"):
		spikes_instance.set_variation(attack_variation)
	elif "variation" in spikes_instance:
		spikes_instance.variation = attack_variation
	
	spikes_instance.global_position = spike_spawn_point.global_position
	
		
	# Aggiungi le spine alla scena (preferibilmente non come figlio del Golem)
	get_tree().current_scene.add_child(spikes_instance)
	# print("GolemPietra: Spine (variazione ", attack_variation, ") evocate!")


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
func _on_animation_finished(anim_name: StringName) -> void:
	var current_animation_name_str = str(anim_name)
	
	if current_animation_name_str.begins_with("attack"):
		# Dopo un attacco, torna a idle o run
		if player_ref:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
	elif current_animation_name_str == "hurt":
		# Dopo essere stato colpito, torna a idle o run
		if player_ref:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
	elif current_animation_name_str == "death":
		queue_free() # Rimuovi il Golem dalla scena


func _on_player_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("giocatore") and body is CharacterBody2D:
		player_ref = body as CharacterBody2D
		if current_state == State.IDLE: # Se era fermo, inizia a muoversi/valutare attacco
			change_state(State.RUN)


func _on_player_detection_area_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null
		# Se il Golem stava inseguendo o attaccando (o era appena tornato in RUN dopo un attacco)
		# e il giocatore esce, dovrebbe tornare a IDLE.
		if current_state == State.RUN or current_state == State.ATTACKING:
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
