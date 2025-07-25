extends CharacterBody2D

@onready var hp = 250
@onready var min_distance = 10
@onready var speed = 150.0  # <<< VELOCITÀ DI MOVIMENTO
@onready var player: Node2D = get_tree().get_first_node_in_group("giocatore")
var FireOrbScene = preload("res://scene/dark_orb.tscn")
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var scythe_hitbox1: CollisionShape2D = $ScytheHitbox1/CollisionShape2D
@onready var scythe_hitbox2: CollisionShape2D = $ScytheHitbox2/CollisionShape2D
@onready var hitbox_timer: Timer = $HitboxTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var teleport_timer: Timer = $TeleportTimer
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
func _physics_process(delta):
	if is_dead or player == null or not can_move:
		return
	var direction_vector = player.global_position - global_position
	var distance = global_position.distance_to(player.global_position)
	# Se non sta attaccando e il player è lontano, muoviti verso di lui
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
	var facing_dir = -sign(anim.scale.x) if anim.scale.x != 0 else 1  # Direzione corrente
	if facing_dir < 0:
		$ScytheHitbox1.position.x = 31*facing_dir  # Aggiorna posizione incornata
		$ScytheHitbox2.position.x = 16*facing_dir  # Aggiorna posizione incornata
	else:
		$ScytheHitbox1.position.x = 2*facing_dir  # Aggiorna posizione incornata
		$ScytheHitbox2.position.x = 1*facing_dir  # Aggiorna posizione incornata
	
func _ready():
	rng.randomize()
	anim.play("idle")
	set_collision_layer_value(3, true) # Layer 3 = "nemici"
	hurtbox.set_collision_layer_value(6, true) # Layer "enemy_hurtbox"
	hurtbox.set_collision_mask_value(2, true) # Maschera "player_weapon"
	$ScytheHitbox1.connect("body_entered", Callable(self, "_on_scythe_hitbox_1_body_entered"))
	$ScytheHitbox2.connect("body_entered", Callable(self, "_on_scythe_hitbox_2_body_entered"))
	$ScytheHitbox1.set_collision_layer_value(2, true)  # Abilita layer 2 (player_weapon)
	$ScytheHitbox1.set_collision_mask_value(6, true) #abilita la maschera per colpire i nemici
	$ScytheHitbox2.set_collision_layer_value(2, true)  # Abilita layer 2 (player_weapon)
	$ScytheHitbox2.set_collision_mask_value(6, true) #abilita la maschera per colpire i nemici

	attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
	attack_timer.start(rng.randf_range(1.0, 2.0))  # primi attacco casuale
	teleport_timer.wait_time = 20.0
	teleport_timer.start()
	teleport_timer.timeout.connect(_on_teleport_timer_timeout)
	
	scythe_hitbox1.disabled = true
	scythe_hitbox2.disabled = true

func _process(delta):
	if attack_started and current_attack in attack_properties:
		var keyframes = attack_properties[current_attack].keyframes
		if anim.frame in keyframes:
			_enable_hitbox(current_attack)
		else:
			_disable_hitboxes()

func choose_attack():
	if is_dead:
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
	if area.is_in_group("player_weapon"):
		take_damage(player.damage)
		

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
		queue_free()

# Placeholder per gli altri due attacchi
func perform_teleport():
	if is_dead:
		return
	can_move = false
	var player_pos = player.global_position
	# Genera nuove coordinate relative al player
	var new_x = rng.randf_range(player_pos.x - 300, player_pos.x + 300)
	var new_y = rng.randf_range(0, 100)
	# Teletrasporta il boss
	global_position = Vector2(new_x, new_y)
	# Effetto visivo o animazione opzionale
	anim.play("teleport")  # se hai un'animazione, altrimenti "idle"
	await anim.animation_finished
	can_move = true
	print("Teleportato in: ", global_position)

func perform_summon():
	if is_dead:
		return
	can_move = false
	anim.play("summon")  # Se hai un’animazione specifica
	await anim.animation_finished

	var fire_orbs := []

	for i in range(6):
		var orb = FireOrbScene.instantiate()
		get_parent().add_child(orb)

		# Posiziona le sfere attorno al boss
		var offset = Vector2(40 * (i - 1.5), -30)  # Le mette in fila sopra il boss
		orb.global_position = global_position + offset

		fire_orbs.append(orb)

	# Delay prima di lanciarle (opzionale)
	await get_tree().create_timer(0.5).timeout

	for orb in fire_orbs:
		orb.launch(player.global_position)  # Le lancia verso il player
	can_move = true
	anim.play("idle2")



func _on_attack_timer_timeout() -> void:
	choose_attack()
	# riavvia timer per prossimo attacco (con pausa variabile)
	attack_timer.start(rng.randf_range(2.0, 4.0))


func _on_scythe_hitbox_1_body_entered(body: Node2D) -> void:
	print("HIT:", body.name)
	if body.is_in_group("giocatore") or body.has_method("Damage"):
		print("Giocatore colpito!")
		body.Damage(damage)


func _on_scythe_hitbox_2_body_entered(body: Node2D) -> void:
	print("HIT2:", body.name)
	if body.is_in_group("giocatore") or body.has_method("Damage"):
		print("Giocatore colpito at2!")
		body.Damage(damage)


func _on_teleport_timer_timeout() -> void:
	perform_teleport()
	teleport_timer.start()


func _on_animation_finished() -> void:
	if current_attack == "attacco1" or current_attack == "attacco2":
		attack_started = false
		current_attack = ""
		anim.play("idle")  # torna all'animazione idle
