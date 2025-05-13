extends CharacterBody2D


var movement_speed = 100 
@onready var player = get_tree().get_first_node_in_group("giocatore") 
@onready var anim = $AnimatedSprite2D
@onready var hp = 20
@onready var min_distance = 30
@onready var hurtbox = $Hurtbox
@onready var sword_hitbox = $Pungiglione/CollisionShape2D
@onready var hitbox_timer = $HitboxTimer

var damage = 15
var is_attacking = false
var attack_direction = Vector2.ZERO
var attack_cooldown = 1 #Tempo di attesa tra gli attacchi
var last_attack_time = 0.0

func _ready():
	print(self.name)
	anim.play("move")
	sword_hitbox.disabled = true #disattivato di default
	$Pungiglione.set_collision_layer_value(2, true)  # Abilita layer 2 (player_weapon)
	$Pungiglione.set_collision_mask_value(6, true) #abilita la maschera per colpire i nemici
	hurtbox.set_collision_layer_value(6, true)
	hurtbox.set_collision_mask_value(2, true)
	if not hitbox_timer.timeout.is_connected(_on_hitbox_timer_timeout):
		hitbox_timer.timeout.connect(_on_hitbox_timer_timeout)
	if $Hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		$Hurtbox.area_entered.disconnect(_on_hurtbox_area_entered)
	$Hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	$Pungiglione.body_entered.connect(_on_pungiglione_body_entered)

func _physics_process(delta: float) -> void:
	if is_attacking:
		# Durante l'attacco, muovi l'ape in diagonale
		velocity = attack_direction * movement_speed * 1.5  # Aumenta la velocità durante l'attacco
		move_and_slide()
	elif hp > 0:
		var direction = (player.global_position - global_position).normalized()
		if global_position.distance_to(player.global_position) > min_distance:
			velocity = direction * movement_speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
		
		# Decidi quando fare l'attacco speciale (qui uso una probabilità del 10% ogni frame)
		if not is_attacking and (last_attack_time + attack_cooldown) < Engine.get_physics_frames():
			perform_sting_attack(direction)
# Configurazione hitbox per ogni animazione perchè se cambio gli sprite urlo, accomodiamo per i prossimi attacchi anche
var attack_properties = {
	"attack": {"delay": 0.1, "duration": 0.4, "keyframes": [1,3]},
	"sting_attack": {"delay": 0.1, "duration": 0.4, "keyframes": [1, 3]},
}

func perform_sting_attack(direction: Vector2):
	is_attacking = true
	# Scegli una direzione diagonale basata sulla direzione verso il giocatore
	attack_direction = direction
	anim.play("sting_attack")
	last_attack_time = Engine.get_physics_frames()
	# Attiva l'hitbox dopo un breve ritardo
	await get_tree().create_timer(attack_properties["sting_attack"]["delay"]).timeout
	sword_hitbox.disabled = false
	# Disattiva l'hitbox dopo la durata
	await get_tree().create_timer(attack_properties["sting_attack"]["duration"]).timeout
	sword_hitbox.disabled = true
	# Termina l'attacco dopo un po'
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	anim.play("idle")

func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation in attack_properties.keys():
		if $AnimatedSprite2D.animation == "sting_attack" and is_attacking:
			return
		sword_hitbox.disabled = true #Non mi serve più tenerla attiva
		$AnimatedSprite2D.play("idle")

func take_damage(amount: int):
	hp -= amount
	anim.play("hurt")
	print("Ape colpita! Vita rimanente: ", hp)
	
	if hp <= 0:
		self.collision_layer = false
		anim.play("death")
		set_physics_process(false)
		await anim.animation_finished
		self.queue_free()

func _on_hitbox_timer_timeout() -> void:
	var current_anim = $AnimatedSprite2D.animation
	
	if current_anim in attack_properties:
		var props = attack_properties[current_anim]
		
		if sword_hitbox.disabled:
			# Attiva hitbox
			sword_hitbox.disabled = false
			hitbox_timer.start(props.duration)  # Durata hitbox
		else:
			# Disattiva hitbox
			sword_hitbox.disabled = true
			
			# Se ci sono più keyframe, programma la prossima attivazione
			if props.keyframes.size() > 1:
				var next_keyframe = props.keyframes[1]
				hitbox_timer.start(next_keyframe)  # Attiva il prossimo keyframe
			else:
				hitbox_timer.stop()  # Ferma il timer se non ci sono più keyframeon)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_weapon"):
		anim.play("attack")
		take_damage(10)


func _on_pungiglione_body_entered(body: Node2D) -> void:
	print("Hitbox ha colpito: ", body.name)
	if body.is_in_group("giocatore"):
		print("E' un giocatore! Infliggo danno")
		body.Damage(damage)
