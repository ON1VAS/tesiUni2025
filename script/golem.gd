extends CharacterBody2D

var movement_speed = 40 
@onready var player = get_tree().get_first_node_in_group("giocatore") 
@onready var anim = $AnimatedSprite2D
@onready var hp = 20
@onready var min_distance = 100
@onready var hurtbox = $Hurtbox
@onready var audiohurt = $GolemHurt
@onready var audiodeath = $GolemDeath

var palladifuoco = preload("res://scene/fireball.tscn")
var direction = Vector2.ZERO  # Aggiunta direzione per il movimento


# Palla di fuoco
var ragnatela_ammo = 0
var ragnatela_baseammo = 1
var ragnatela_attackspeed = 200
var ragnatela_level = 1
var attack_cooldown = 2  # Tempo di recupero tra gli attacchi

# Player detection
var player_in_area = false
var can_attack = true # Flag per gestire la possibilità di attacco
var is_attacking = false


#servono pe capire quando il nemico è morto e far progredire i progressi della wave
signal dead
var death_sig_emitted = 0
var is_dead = false

func _ready():
	anim.play("move")
	self.set_collision_layer_value(6, true)  # Abilita layer 6 (enemy_hurt)
	self.set_collision_mask_value(2, true)   # Deve rilevare layer 2 (player_weapon)
	hurtbox.set_collision_layer_value(6, true)
	hurtbox.set_collision_mask_value(2, true)
	hurtbox.area_entered.connect(_on_area_2d_area_entered)

func _physics_process(delta):
	# Controllo se il golem è morto
	if hp <= 0:
		return
	
	if is_attacking:
		move_and_slide()
		return
	# Calcola distanza dal giocatore
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		# Movimento verso il giocatore
		if distance_to_player > min_distance:
			direction = (player.global_position - global_position).normalized()
			velocity.x = lerp(velocity.x, direction.x * movement_speed, delta * 5.0)
			anim.play("move")
		else:
			# Fermati se sei abbastanza vicino
			direction = Vector2.ZERO
			velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
			if is_zero_approx(velocity.x):
				anim.play("idle")
		
		# Orientamento dello sprite
		flip_sprite(player.global_position - global_position)
	
	move_and_slide()

func _process(delta):
	if not can_attack or is_dead or player == null:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= min_distance + 150:
		shoot_fireball()
		can_attack = false
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true

func shoot_fireball():
	is_attacking = true
	anim.play("attack")
	await anim.animation_finished
	is_attacking = false
	
	if is_dead:
		return
	
	var fireball = palladifuoco.instantiate()
	fireball.global_position = $FireballSpawnPoint.global_position
	var direction = (player.global_position - global_position).normalized()
	fireball.direction = direction
	fireball.speed = ragnatela_attackspeed
	fireball.damage = 20 * DebuffManager.enemy_damage_multiplier()
	get_parent().add_child(fireball)


func take_damage(amount: int):
	if is_dead:
		return
	hp -= amount
	
	if hp > 0:
		audiohurt.play()
		anim.play("damage")
	if hp <= 0:
		is_dead = true
		can_attack = false
		set_collision_layer_value(1, false)
		audiodeath.play()
		anim.play("death")
		set_physics_process(false)
		await anim.animation_finished
		if death_sig_emitted == 0:
			dead.emit()
			death_sig_emitted += 1
		queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_weapon"):
		take_damage(player.damage)

func _on_player_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("giocatore"):
		can_attack = true

func _on_player_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("giocatore"):
		can_attack = false

func flip_sprite(vector):
	if vector.x < 0:
		anim.flip_h = true
		$FireballSpawnPoint.position.x = -abs($FireballSpawnPoint.position.x)
	elif vector.x > 0:
		anim.flip_h = false
		$FireballSpawnPoint.position.x = abs($FireballSpawnPoint.position.x)
