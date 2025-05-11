extends CharacterBody2D

var movement_speed = 100 
@onready var player = get_tree().get_first_node_in_group("giocatore") 
@onready var anim = $AnimatedSprite2D
@onready var hp = 20
@onready var min_distance = 300
@onready var hurtbox = $Area2D

var exp = preload("res://scene/exp_points.tscn")

var direction = Vector2.ZERO

# Attack (png della palla di fuoco)
var ragnatela = preload("res://provapermodificare/ragno/ragnatela.tscn")

# AttackNodes
@onready var ragnatelaTimer = get_node("%ragnatelaTimer") # % è accessibile con get_node
@onready var attacco_ragnatelaTimer = get_node("%attacco_ragnatelaTimer")
@onready var cooldownTimer = get_node("%cooldownTimer") # Aggiungiamo un nuovo timer per il cooldown

# Palla di fuoco
var ragnatela_ammo = 0
var ragnatela_baseammo = 1
var ragnatela_attackspeed = 1.5
var ragnatela_level = 1
var attack_cooldown = 4  # Tempo di recupero tra gli attacchi

# Player detection
var player_in_area = false
var can_attack = true # Flag per gestire la possibilità di attacco

func _ready():
	anim.play("move")
	self.set_collision_layer_value(6, true)  # Abilita layer 6 (enemy_hurt)
	self.set_collision_mask_value(2, true)  # Deve rilevare layer 2 (player_weapon)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func attack():
	if player_in_area and ragnatela_level > 0 and can_attack:
		ragnatelaTimer.wait_time = ragnatela_attackspeed
		if ragnatelaTimer.is_stopped():
			ragnatelaTimer.start()

func _physics_process(_delta): 
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player > min_distance: # Il nemico si muove solo fino ad una certa distanza dallo slime
		direction = (player.global_position - global_position).normalized()
		velocity = direction * movement_speed
		move_and_slide()
	elif hp > 0:
		direction = Vector2.ZERO  # Ferma il nemico
		anim.play("idle")
	
	flip_sprite(player.global_position - global_position)

func flip_sprite(vector):
	if vector.x > 0:
		anim.flip_h = true
	elif vector.x < 0:
		anim.flip_h = false

func _on_detect_area_body_entered(body):
	if body.is_in_group("giocatore"):
		player_in_area = true
		attack()

func _on_player_detection_area_body_exited(body):
	if body.is_in_group("giocatore"):
		player_in_area = false
		ragnatelaTimer.stop()
		attacco_ragnatelaTimer.stop()
		cooldownTimer.stop()

func _on_ragnatela_timer_timeout():
	ragnatela_ammo += ragnatela_baseammo
	attacco_ragnatelaTimer.start()

func _on_attacco_ragnatela_timer_timeout():
	if ragnatela_ammo > 0 and can_attack:
		var ragnatela_attack = ragnatela.instantiate()
		ragnatela_attack.position = global_position # Ensure the fireball starts at the enemy's current position
		ragnatela_attack.direction = (player.global_position - global_position).normalized() # Set the direction towards the player
		ragnatela_attack.speed = 300 # Ensure the speed is sufficient for forward movement
		get_parent().add_child(ragnatela_attack) # Add the fireball to the same parent as the enemy to maintain the same coordinate system
		ragnatela_ammo -= 1
		can_attack = false
		cooldownTimer.start(attack_cooldown) # Start cooldown timer

func _on_cooldown_timer_timeout():
	can_attack = true # Re-enable attacking after cooldown
	attacco_ragnatelaTimer.stop() # Stop attack timer during cooldown

func EnemyDamage(slime_dam):
	hp -= slime_dam
	anim.play("damage")
	$TimerDannoPreso.start()
	

func setExpGround():
	await (get_tree().create_timer(1.5).timeout)
	var exp_instance = exp.instantiate() 
	get_parent().add_child(exp_instance)
	exp_instance.add_to_group("monete")
	exp_instance.position = self.position


func _on_timer_danno_preso_timeout():
	if player_in_area and ragnatela_level > 0 and can_attack:
		anim.play("move")
		ragnatelaTimer.wait_time = ragnatela_attackspeed
		if ragnatelaTimer.is_stopped():
			ragnatelaTimer.start()
	elif hp <= 0:
		self.collision_layer = false
		anim.play("morte")
		setExpGround()
		await (get_tree().create_timer(1.5).timeout)
		self.queue_free()
	else:
		anim.play("move")
		
		

func _on_hurtbox_area_entered(area: Area2D):
	# Se l'area è la SwordHitbox del giocatore
	if area.is_in_group("player_weapon"):
		anim.play("damage")
		take_damage(10)  # Danno base (puoi passare un valore dal player)

func take_damage(amount: int):
	hp -= amount
	print("Manichino colpito! Vita rimanente: ", hp)
	
	if hp <= 0:
		queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
