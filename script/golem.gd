extends CharacterBody2D

var movement_speed = 40 
@onready var player = get_tree().get_first_node_in_group("giocatore") 
@onready var anim = $AnimatedSprite2D
@onready var hp = 20
@onready var min_distance = 300
@onready var hurtbox = $Hurtbox

var palladifuoco = preload("res://scene/fireball.tscn")

# Palla di fuoco
var ragnatela_ammo = 0
var ragnatela_baseammo = 1
var ragnatela_attackspeed = 200
var ragnatela_level = 1
var attack_cooldown = 2  # Tempo di recupero tra gli attacchi

# Player detection
var player_in_area = false
var can_attack = true # Flag per gestire la possibilità di attacco

func _ready():
	anim.play("move")
	self.set_collision_layer_value(6, true)  # Abilita layer 6 (enemy_hurt)
	self.set_collision_mask_value(2, true)  # Deve rilevare layer 2 (player_weapon)
	hurtbox.set_collision_layer_value(6, true)
	hurtbox.set_collision_mask_value(2, true)
	hurtbox.area_entered.connect(_on_area_2d_area_entered)
	
func _process(delta):
	if can_attack and player:
		shoot_fireball()
		can_attack = false
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true
	


func shoot_fireball():
	var fireball = palladifuoco.instantiate()
	anim.play("attack")
	fireball.global_position = $FireballSpawnPoint.global_position
	var direction = (player.global_position - global_position).normalized()
	fireball.direction = direction
	fireball.speed = ragnatela_attackspeed
	fireball.damage = 20
	get_parent().add_child(fireball)

func take_damage(amount: int):
	hp -= amount
	anim.play("damage")
	print("Golem colpito! Vita rimanente: ", hp)
	
	if hp <= 0:
		can_attack = false
		self.collision_layer = false
		anim.play("death")
		set_physics_process(false)
		await (get_tree().create_timer(1.5).timeout)
		self.queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	# Se l'area è la SwordHitbox del giocatore
	if area.is_in_group("player_weapon"):
		anim.play("damage")
		take_damage(10)  # Danno base (puoi passare un valore dal player)
		


func _on_player_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("giocatore"):
		can_attack = true

func _on_player_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("giocatore"):
		can_attack = false
