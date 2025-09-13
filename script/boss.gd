extends CharacterBody2D

signal health_changed(current: int, max: int)
signal died

# --- NUOVO: stato attivo/inattivo ---
var active: bool = false
@export var display_name := "Mietitore Notturno"
var health = 100
@export var max_health := 250
@onready var hp = 250
@onready var min_distance = 10
@onready var speed = 150.0
@onready var player: Node2D = get_tree().get_first_node_in_group("giocatore")
var FireOrbScene = preload("res://scene/dark_orb.tscn")
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var scythe_hitbox1: CollisionShape2D = $ScytheHitbox1/CollisionShape2D
@onready var scythe_hitbox2: CollisionShape2D = $ScytheHitbox2/CollisionShape2D
@onready var hitbox_timer: Timer = $HitboxTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var teleport_timer: Timer = $TeleportTimer
@onready var healthbar: ProgressBar = $HealthBar
@onready var audiodeath: AudioStreamPlayer2D = $BossDeath
var damage = 10 * DebuffManager.enemy_damage_multiplier()
var is_dead = false
var can_move = true
var current_attack = ""
var attack_started = false
var rng = RandomNumberGenerator.new()

var attack_properties = {
	"attacco1": {"delay": 0.1, "duration": 0.15, "keyframes": [2,3]},
	"attacco2": {"delay": 0.15, "duration": 0.2, "keyframes": [2,3]}
}

func _ready():
	rng.randomize()
	hp = max_health  # inizializza coerenza HP
	# --- init barra vita
	healthbar.max_value = max_health
	healthbar.value = hp
	if not is_connected("health_changed", Callable(self, "_on_health_changed")):
		connect("health_changed", Callable(self, "_on_health_changed"))
	anim.play("idle")
	set_collision_layer_value(3, true) # "nemici"
	hurtbox.set_collision_layer_value(6, true) # "enemy_hurtbox"
	hurtbox.set_collision_mask_value(2, true)  # "player_weapon"
	$ScytheHitbox1.connect("body_entered", Callable(self, "_on_scythe_hitbox_1_body_entered"))
	$ScytheHitbox2.connect("body_entered", Callable(self, "_on_scythe_hitbox_2_body_entered"))
	$ScytheHitbox1.set_collision_layer_value(2, true)
	$ScytheHitbox1.set_collision_mask_value(6, true)
	$ScytheHitbox2.set_collision_layer_value(2, true)
	$ScytheHitbox2.set_collision_mask_value(6, true)
	

	attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
	teleport_timer.timeout.connect(_on_teleport_timer_timeout)
	teleport_timer.wait_time = 20.0

	# --- IMPORTANTE: all'avvio è INATTIVO ---
	deactivate()

func activate() -> void:
	if active:
		return
	active = true
	can_move = true
	_disable_hitboxes()
	# avvia timers solo ora
	attack_timer.start(rng.randf_range(1.0, 2.0))
	teleport_timer.start()
	set_physics_process(true)
	set_process(true)
	if is_instance_valid(healthbar):
		healthbar.visible = true

func deactivate() -> void:
	active = false
	can_move = false
	attack_started = false
	current_attack = ""
	_disable_hitboxes()
	# ferma timers e process
	attack_timer.stop()
	teleport_timer.stop()
	set_physics_process(true) # lasciato true per aggiornare flip/pos, ma bloccato dal check sotto
	set_process(true)
	velocity = Vector2.ZERO
	anim.play("idle")
	if is_instance_valid(healthbar):
		healthbar.visible = false

func _physics_process(delta):
	# --- BLOCCO: se non attivo, non fare nulla ---
	if not active or is_dead or player == null or not can_move:
		return

	var direction_vector = player.global_position - global_position
	var distance = global_position.distance_to(player.global_position)

	if not attack_started and distance > min_distance:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	if direction_vector.x < 0:
		anim.flip_h = true
	else:
		anim.flip_h = false

	var facing_dir = -sign(anim.scale.x) if anim.scale.x != 0 else 1
	if facing_dir < 0:
		$ScytheHitbox1.position.x = 31*facing_dir
		$ScytheHitbox2.position.x = 16*facing_dir
	else:
		$ScytheHitbox1.position.x = 2*facing_dir
		$ScytheHitbox2.position.x = 1*facing_dir

func _process(delta):
	# se non attivo niente keyframe/hitbox
	if not active:
		return
	if attack_started and current_attack in attack_properties:
		var keyframes = attack_properties[current_attack].keyframes
		if anim.frame in keyframes:
			_enable_hitbox(current_attack)
		else:
			_disable_hitboxes()

func choose_attack():
	if is_dead or not active:
		return
	var attacks = ["attacco1", "attacco2", "teleport", "summon"]
	var chosen = attacks[randi() % attacks.size()]
	match chosen:
		"attacco1", "attacco2":
			start_attack(chosen)
		"teleport":
			perform_teleport()
		"summon":
			perform_summon()

func start_attack(anim_name: String):
	if not active: return
	current_attack = anim_name
	attack_started = true
	anim.play(anim_name)

func _enable_hitbox(attack_name: String):
	match attack_name:
		"attacco1":
			scythe_hitbox1.disabled = false
		"attacco2":
			scythe_hitbox2.disabled = false

func _disable_hitboxes():
	scythe_hitbox1.disabled = true
	scythe_hitbox2.disabled = true

func _on_hurtbox_area_entered(area: Area2D):
	if not active: return
	if area.is_in_group("player_weapon"):
		take_damage(player.damage)

func take_damage(amount: int):
	if is_dead or not active:
		return
	hp -= amount
	emit_signal("health_changed", hp, max_health)
	if hp > 0:
		anim.play("hurt")
	if hp <= 0:
		set_collision_layer_value(1, false)
		attack_timer.stop()
		teleport_timer.stop()
		audiodeath.play()
		anim.play("death")
		set_physics_process(false)
		await anim.animation_finished
		emit_signal("died")
		queue_free()

func perform_teleport():
	if is_dead or not active:
		return
	can_move = false
	var player_pos = player.global_position
	var new_x = rng.randf_range(player_pos.x - 300, player_pos.x + 300)
	var new_y = rng.randf_range(0, 100)
	global_position = Vector2(new_x, new_y)
	anim.play("teleport")
	await anim.animation_finished
	can_move = true
	print("Teleportato in: ", global_position)

func perform_summon():
	if is_dead or not active:
		return

	can_move = false
	anim.play("summon")
	await anim.animation_finished
	if is_dead or not active:
		can_move = true
		return

	var fire_orbs: Array = []
	var base_pos := global_position

	# Istanzia e posiziona subito
	for i in range(6):
		var orb = FireOrbScene.instantiate()
		var offset = Vector2(40 * (i - 1.5), -30)
		orb.global_position = base_pos + offset
		get_parent().add_child(orb)
		fire_orbs.append(orb)

	# Lascia passare un frame, così tutte le orb hanno fatto _ready()
	await get_tree().process_frame

	# (piccolo delay opzionale)
	await get_tree().create_timer(0.2).timeout
	if is_dead or not active:
		can_move = true
		return

	# Lancia solo orb ancora valide, in modo sicuro
	for orb in fire_orbs:
		if is_instance_valid(orb):
			orb.call_deferred("launch", player.global_position)

	can_move = true
	anim.play("idle2")


func _on_attack_timer_timeout() -> void:
	if not active: return
	choose_attack()
	attack_timer.start(rng.randf_range(2.0, 4.0))

func _on_scythe_hitbox_1_body_entered(body: Node2D) -> void:
	if not active: return
	if body.is_in_group("giocatore") or body.has_method("Damage"):
		body.Damage(damage)

func _on_scythe_hitbox_2_body_entered(body: Node2D) -> void:
	if not active: return
	if body.is_in_group("giocatore") or body.has_method("Damage"):
		body.Damage(damage)

func _on_teleport_timer_timeout() -> void:
	if not active: return
	perform_teleport()
	teleport_timer.start()

func _on_animation_finished() -> void:
	if current_attack == "attacco1" or current_attack == "attacco2":
		attack_started = false
		current_attack = ""
		anim.play("idle")


func _on_health_changed(current: int, max: int) -> void:
	if is_instance_valid(healthbar):
		healthbar.max_value = max
		healthbar.value = clamp(current, 0, max)
		# opzionale: mostra/nascondi barra
		healthbar.visible = active and current > 0.
