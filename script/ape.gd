extends CharacterBody2D

# --- Tuning ---
var movement_speed := 100
var min_distance := 30
var damage := 15

var attack_windup := 0.30     # preparazione prima dello scatto
var dash_speed := 320.0        # velocità dello scatto
var dash_distance := 200.0      # distanza coperta dallo scatto
var attack_recover := 0.40     # recovery dopo lo scatto
var attack_cooldown := 0.60    # tempo minimo dal termine dell'attacco
var hurt_stun := 0.25
var knockback := 120.0

# --- State machine ---
enum State { CHASE, WINDUP, DASH, RECOVER, HURT, DEAD }
var state : State = State.CHASE
var can_attack := true
var attack_dir := Vector2.ZERO
var last_attack_end_time := 0.0

# controllo del dash
var dash_remaining := 0.0

# --- Nodes ---
@onready var player = get_tree().get_first_node_in_group("giocatore")
@onready var anim : AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox : Area2D = $Hurtbox
@onready var sword_hitbox : CollisionShape2D = $Pungiglione/CollisionShape2D
@onready var hitbox_area : Area2D = $Pungiglione
@onready var audiohurt = $ApeHurt
@onready var audiodeath = $ApeDeath
@onready var hitbox_timer : Timer = $HitboxTimer

@onready var effects = $Effects
@onready var hurt_timer = $DamageEffectTimer

var hp := 20
var is_dead := false
signal dead

func _ready() -> void:
	
	effects.play("RESET")
	
	anim.play("move")
	sword_hitbox.disabled = true
	hitbox_area.set_collision_layer_value(2, true)
	hitbox_area.set_collision_mask_value(6, true)
	hurtbox.set_collision_layer_value(6, true)
	hurtbox.set_collision_mask_value(2, true)
	if not hitbox_timer.timeout.is_connected(_on_hitbox_timer_timeout):
		hitbox_timer.timeout.connect(_on_hitbox_timer_timeout)
	if hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		hurtbox.area_entered.disconnect(_on_hurtbox_area_entered)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	hitbox_area.body_entered.connect(_on_pungiglione_body_entered)

func _physics_process(delta: float) -> void:
	# flip + offset del pungiglione
	var flip_left = player.global_position.x < global_position.x
	anim.flip_h = not flip_left
	sword_hitbox.position.x = -10.5 if flip_left else 10.5

	match state:
		State.CHASE:
			var dir = (player.global_position - global_position).normalized()
			if global_position.distance_to(player.global_position) > min_distance:
				velocity = dir * movement_speed
				move_and_slide()
			else:
				velocity = Vector2.ZERO
			# attacca solo se è passato il cooldown
			if can_attack and (Time.get_ticks_msec() / 1000.0 - last_attack_end_time) >= attack_cooldown:
				start_windup(dir)

		State.WINDUP:
			velocity = Vector2.ZERO
			move_and_slide()

		State.DASH:
			# muovi per coprire una distanza reale
			var step = min(dash_remaining, dash_speed * delta)
			var motion = attack_dir * step
			var col := move_and_collide(motion)
			dash_remaining -= step
			if col or dash_remaining <= 0.0:
				sword_hitbox.disabled = true
				start_recover()

		State.RECOVER:
			velocity = Vector2.ZERO
			move_and_slide()

		State.HURT, State.DEAD:
			move_and_slide()

# --- Attack sequence ---
func start_windup(dir: Vector2) -> void:
	can_attack = false
	state = State.WINDUP
	attack_dir = dir
	anim.play("sting_attack")
	await get_tree().create_timer(attack_windup).timeout
	if state != State.WINDUP:
		return
	start_dash()

func start_dash() -> void:
	state = State.DASH
	dash_remaining = dash_distance
	sword_hitbox.disabled = false

func start_recover() -> void:
	state = State.RECOVER
	anim.play("move")
	await get_tree().create_timer(attack_recover).timeout
	if state != State.RECOVER:
		return
	end_attack()

func end_attack() -> void:
	state = State.CHASE
	last_attack_end_time = Time.get_ticks_msec() / 1000.0
	can_attack = true
	anim.play("move")

# --- Damage / Hurt ---
func take_damage(amount: int, from_dir: Vector2 = Vector2.ZERO) -> void:
	effects.play("hurt_blink")
	hurt_timer.start()
	if is_dead:
		return
	hp -= amount
	if hp > 0:
		state = State.HURT
		can_attack = false
		sword_hitbox.disabled = true
		velocity = -from_dir.normalized() * knockback
		audiohurt.play()
		anim.play("hurt")
		await get_tree().create_timer(hurt_stun).timeout
		velocity = Vector2.ZERO
		if not is_dead:
			state = State.CHASE
			anim.play("move")
		can_attack = true
	else:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	state = State.DEAD
	set_collision_layer_value(1, false)
	sword_hitbox.disabled = true
	velocity = Vector2.ZERO
	audiodeath.play()
	anim.play("death")
	set_physics_process(false)
	await anim.animation_finished
	dead.emit()
	queue_free()

# --- Signals/Hit detection ---
func _on_hitbox_timer_timeout() -> void:
	pass

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_weapon") and not is_dead:
		var dir := (global_position - area.global_position)
		var dmg := 1
		if area.get_parent().has_method("get"): # evita errori se non esiste
			if "damage" in area.get_parent():
				dmg = area.get_parent().damage
		take_damage(dmg, dir)

func _on_pungiglione_body_entered(body: Node2D) -> void:
	if state == State.DASH and body.is_in_group("giocatore"):
		body.Damage(damage)


func _on_damage_effect_timer_timeout() -> void:
	effects.play("RESET")
