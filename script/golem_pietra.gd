# Golem Script - Full Version with Sprint and Collision Fix (aggiornato)
extends CharacterBody2D

# --- Variabili Esportabili ---
@export var movement_speed: float = 40.0
@export var sprint_speed: float = 120.0
@export var sprint_end_distance: float = 250.0
@export var gravity_strength: float = 980.0
@export var hp: int = 50
@export var attack_range: float = 150.0
@export var attack_cooldown_time: float = 2.5

# frame dell'animazione d'attacco in cui spawnare le spine
var attack_spawn_frame: int = 3
var attack_spawn_called: bool = false

# --- Riferimenti ai Nodi ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_attack_area: Area2D = $PlayerDetectionArea
@onready var hurtbox: Area2D = $Hurtbox
@onready var player_ref: CharacterBody2D = get_tree().get_first_node_in_group("giocatore")
@onready var spike_spawn_point: Marker2D = $SpikeSpawnPoint
@onready var ray_cast_floor: RayCast2D = $RayCastFloor
@onready var ray_cast_front: RayCast2D = $RayCastFront
@onready var audiohurt = $GolemPietraHurt
@onready var audiodeath = $GolemPietraDeath

# --- Variabili Floating (ondeggiamento idle/run) ---
@export var float_amplitude: float = 5.0
@export var float_speed: float = 2.0
var float_offset: float = 0.0

# --- Scena Spine ---
const SPINE_SCENE = preload("res://scene/spine.tscn")

# --- Stato ---
enum State { IDLE, RUN, ATTACKING, HURT, DEAD }
var current_state: State = State.IDLE
var is_player_in_attack_range: bool = false
var is_sprinting: bool = false
var can_attack: bool = true
var time_since_last_attack: float = 0.0

# --- Tipo di attacco corrente ---
var current_attack_type: int = 1

# --- Segnale Morte ---
signal dead
var death_sig_emitted := 0


func _ready() -> void:
	float_offset = randf_range(-50.0, -100.0)

	if not is_instance_valid(player_ref):
		print_rich("[color=red]Golem Error: Player not found. Golem will be idle.[/color]")
		change_state(State.IDLE)
	else:
		change_state(State.RUN)

	# Raycast: riallinea sul pavimento all'avvio (opzionale)
	ray_cast_floor.force_raycast_update()
	if ray_cast_floor.is_colliding():
		var floor_position := ray_cast_floor.get_collision_point()
		global_position.y = floor_position.y - 50.0

	# --- Collisioni ---
	# layer del golem
	set_collision_layer_value(3, true)  # 3 = "nemici"
	# pulisci la maschera
	collision_mask = 0
	# collide solo col terreno solido (1)
	set_collision_mask_value(1, true)

	# layer/mask hurtbox del golem
	hurtbox.set_collision_layer_value(6, true)  # enemy_hurtbox
	hurtbox.set_collision_mask_value(2, true)   # player_weapon

	# --- Signals ---
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	player_attack_area.body_entered.connect(_on_player_attack_area_body_entered)
	player_attack_area.body_exited.connect(_on_player_attack_area_body_exited)

	# raggio area attacco
	var attack_shape := player_attack_area.get_node_or_null("CollisionShape2D")
	if attack_shape and attack_shape is CollisionShape2D:
		if attack_shape.shape is CircleShape2D:
			var c := attack_shape.shape as CircleShape2D
			c.radius = attack_range

	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)

	time_since_last_attack = attack_cooldown_time


func _physics_process(delta: float) -> void:
	# gravità se vuoi farlo “saltellare” nell’aria (al momento disattivata)
	# if not is_on_floor():
	# 	velocity.y += gravity_strength * delta

	# ondeggiamento
	float_offset += float_speed * delta
	if animated_sprite:
		animated_sprite.position.y = sin(float_offset) * float_amplitude

	# cooldown attacchi
	if not can_attack:
		time_since_last_attack += delta
		if time_since_last_attack >= attack_cooldown_time:
			can_attack = true
			time_since_last_attack = 0.0

	# spawn delle spine al frame giusto mentre è in ATTACKING
	if current_state == State.ATTACKING:
		_handle_attack_spawn()

	# macchina a stati
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.RUN:
			_state_run(delta)
		State.ATTACKING:
			_state_attacking(delta)
		State.HURT:
			pass
		State.DEAD:
			pass

	if current_state != State.DEAD:
		move_and_slide()
		_update_sprite_facing_direction()


func change_state(new_state: State) -> void:
	if current_state == new_state and new_state != State.ATTACKING:
		return

	if animated_sprite:
		animated_sprite.speed_scale = 1.0

	if new_state == State.ATTACKING:
		attack_spawn_called = false

	current_state = new_state

	if not animated_sprite:
		return

	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
			velocity.x = 0.0

		State.RUN:
			animated_sprite.play("run")

		State.ATTACKING:
			velocity.x = 0.0
			# 1 = terra, 2 = cielo, 3 = lancio mirato
			current_attack_type = randi_range(1, 3)
			animated_sprite.play("attack" + str(current_attack_type))
			can_attack = false
			time_since_last_attack = 0.0

		State.HURT:
			audiohurt.play()
			animated_sprite.play("hurt")
			velocity.x = 0.0

		State.DEAD:
			animated_sprite.play("death")
			set_physics_process(false)
			collision_layer = 0
			collision_mask = 0
			if hurtbox and is_instance_valid(hurtbox):
				hurtbox.queue_free()


# --- Stati --------------------------------------------------------

func _state_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, movement_speed * delta * 2.0)
	if is_instance_valid(player_ref):
		change_state(State.RUN)


func _state_run(delta: float) -> void:
	if not is_instance_valid(player_ref):
		change_state(State.IDLE)
		return

	if can_attack and is_player_in_attack_range:
		change_state(State.ATTACKING)
		return

	var distance_to_player := global_position.distance_to(player_ref.global_position)
	is_sprinting = distance_to_player > sprint_end_distance

	var current_speed := movement_speed
	if is_sprinting:
		current_speed = sprint_speed

	if animated_sprite:
		animated_sprite.play("run")
		if is_sprinting:
			animated_sprite.speed_scale = 2.0
		else:
			animated_sprite.speed_scale = 1.0

	var direction_to_player := (player_ref.global_position - global_position).normalized()
	velocity.x = direction_to_player.x * current_speed

	# evita di cadere da bordi o urtare muri
	if is_on_floor():
		if ray_cast_front.is_colliding() or not ray_cast_floor.is_colliding():
			velocity.x = 0.0


func _state_attacking(delta: float) -> void:
	velocity.x = 0.0


# --- Attacco / Danno ----------------------------------------------

func _handle_attack_spawn() -> void:
	if attack_spawn_called:
		return
	if not animated_sprite:
		return

	var current_anim := animated_sprite.animation
	if not current_anim.begins_with("attack"):
		return

	var total_frames := animated_sprite.sprite_frames.get_frame_count(current_anim)
	var spawn_frame := attack_spawn_frame
	if spawn_frame > total_frames - 1:
		spawn_frame = total_frames - 1

	if animated_sprite.frame >= spawn_frame:
		_spawn_spikes(current_attack_type)
		attack_spawn_called = true


func _spawn_spikes(attack_variation: int) -> void:
	if not SPINE_SCENE:
		return

	var num_spikes := 1
	var positions: Array[Vector2] = []
	var rotations: Array[float] = []

	var ground_y_pos := global_position.y

	match attack_variation:
		1:
			# --- Spine dal terreno, più elementi davanti al golem ---
			num_spikes = 4

			var dir := 1
			if animated_sprite and animated_sprite.flip_h:
				dir = -1

			var start_x := global_position.x + (dir * 50.0)
			for i in range(num_spikes):
				var px := start_x + (i * 50.0 * dir)
				positions.append(Vector2(px, ground_y_pos))
				rotations.append(0.0)

		2:
			# --- Spine che cadono dal cielo ---
			num_spikes = 4
			var start_x2 := global_position.x - 75.0
			for i in range(num_spikes):
				positions.append(Vector2(start_x2 + i * 50.0, global_position.y - 150.0))
				rotations.append(PI)

		3:
			# --- Lancio mirato: singolo proiettile dallo SpikeSpawnPoint ---
			if spike_spawn_point:
				positions.append(spike_spawn_point.global_position)
			else:
				positions.append(global_position)
			rotations.append(0.0)

	for i in range(num_spikes):
		var spikes_inst := SPINE_SCENE.instantiate()
		if spikes_inst == null:
			continue
		spikes_inst.global_position = positions[i]
		# per 1 e 2 manteniamo la rotazione predefinita
		if attack_variation != 3:
			spikes_inst.rotation = rotations[i]
		# imposta la variation
		if spikes_inst.has_method("set_variation"):
			spikes_inst.set_variation(attack_variation)
		# passa il bersaglio solo per la variation 3 (lancio mirato)
		if attack_variation == 3 and is_instance_valid(player_ref):
			if spikes_inst.has_method("set_target_position"):
				spikes_inst.set_target_position(player_ref.global_position)
		if spikes_inst.has_method("set_variation"):
			spikes_inst.set_variation(attack_variation)
		get_tree().current_scene.add_child(spikes_inst)


func take_damage(amount: int) -> void:
	if current_state == State.DEAD or current_state == State.HURT:
		return

	hp -= amount
	if hp <= 0:
		if current_state != State.DEAD:
			change_state(State.DEAD)
			if death_sig_emitted == 0:
				dead.emit()
				death_sig_emitted += 1
	else:
		change_state(State.HURT)


# --- Signals -------------------------------------------------------

func _on_animation_finished() -> void:
	if not animated_sprite:
		return
	var current_anim := animated_sprite.animation

	if current_anim.begins_with("attack") or current_anim == "hurt":
		if is_instance_valid(player_ref):
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
	elif current_anim == "death":
		queue_free()


func _on_player_attack_area_body_entered(body: Node2D) -> void:
	if body == player_ref:
		is_player_in_attack_range = true


func _on_player_attack_area_body_exited(body: Node2D) -> void:
	if body == player_ref:
		is_player_in_attack_range = false


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_weapon"):
		var damage_amount := 10
		if "damage" in area:
			damage_amount = area.damage
		# se vuoi usare il danno dell'arma del player:
		if is_instance_valid(player_ref) and "damage" in player_ref:
			take_damage(player_ref.damage)
		else:
			take_damage(damage_amount)


# --- Utility -------------------------------------------------------

func _update_sprite_facing_direction() -> void:
	if not is_instance_valid(player_ref) or not animated_sprite:
		return

	if abs(velocity.x) > 1.0:
		animated_sprite.flip_h = velocity.x < 0.0
	else:
		animated_sprite.flip_h = player_ref.global_position.x < global_position.x
