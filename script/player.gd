extends CharacterBody2D

const GRAVITY = 400.0
const JUMP_FORCE = -200
@export var speed = 200
var facing_direction = 1  # 1 = destra, -1 = sinistra

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
	if $AnimatedSprite2D.animation not in ["attack", "attack2"]:
		if Input.is_action_just_pressed("attackfast"):
			$AnimatedSprite2D.play("attack")
		elif Input.is_action_just_pressed("attackpesant"):
			$AnimatedSprite2D.play("attack2")
	
	# Animazioni normali (solo se non sta attaccando)
	if $AnimatedSprite2D.animation not in ["attack", "attack2"]:
		if not is_on_floor():
			$AnimatedSprite2D.play("jump" if velocity.y < 0 else "fall")
		elif velocity.x != 0:
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("idle")
	
	# Flip
	$AnimatedSprite2D.flip_h = facing_direction < 0
	
	move_and_slide()


func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation in ["attack", "attack2"]:
		$AnimatedSprite2D.play("idle")
