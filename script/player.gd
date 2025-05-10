extends CharacterBody2D

@onready var sword_hitbox = $SwordHitbox/CollisionShape2D
@onready var hitbox_timer = $HitboxTimer

const GRAVITY = 400.0
const JUMP_FORCE = -200
@export var speed = 200
var facing_direction = 1  # 1 = destra, -1 = sinistra

# Configurazione hitbox per ogni animazione perchè se cambio gli sprite urlo, accomodiamo per i prossimi attacchi anche
var attack_properties = {
	"attack": {"delay": 0.1, "duration": 0.15, "keyframes": [1,2]},
	"attackfermo": {"delay": 0.1, "duration": 0.15, "keyframes": [1,2]},
	"attack2": {"delay": 0.15, "duration": 0.2, "keyframes": [2,3]},
	"attackfermo2": {"delay": 0.15, "duration": 0.2, "keyframes": [2,3]}
}

func _ready():
	sword_hitbox.disabled = true #disattivato di default
	hitbox_timer.timeout.connect(_on_hitbox_timer_timeout)
	
func start_attack(anim_name: String):
	$AnimatedSprite2D.play(anim_name)
	var props = attack_properties[anim_name]
	hitbox_timer.start(props.delay) #si inizia ad attivarlo per la prima volta
func _physics_process(delta):
	# Movimento e gravità
	velocity.y += delta * GRAVITY
	
	# Input movimento
	if Input.is_action_pressed("ui_left"):
		velocity.x = -speed
		facing_direction = -1
	elif Input.is_action_pressed("ui_right"):
		velocity.x = speed
		facing_direction = 1
	else:
		velocity.x = 0
	
	# Salto
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_FORCE
	
	# Attacchi (solo se non sta già eseguendo un'animazione di attacco)
	if $AnimatedSprite2D.animation not in attack_properties.keys():
		if Input.is_action_just_pressed("attackfast"):
			start_attack("attack" if velocity.x == 0 else "attackfermo")
		elif Input.is_action_just_pressed("attackpesant"):
			start_attack("attack2" if velocity.x == 0 else "attackfermo2")
	# Animazioni normali (solo se non sta attaccando)
		elif not is_on_floor():
			$AnimatedSprite2D.play("jump" if velocity.y < 0 else "fall")
		elif velocity.x != 0:
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("idle")
	
	# Flip
	$AnimatedSprite2D.flip_h = facing_direction < 0
	$SwordHitbox/CollisionShape2D.x = -1
	
	move_and_slide()


func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation in attack_properties.keys():
		sword_hitbox.disabled = true #Non mi serve più tenerla attiva
		$AnimatedSprite2D.play("idle")


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
			var next_activation = props.delay * 1.5  # Regola questo valore
			hitbox_timer.start(next_activation)
