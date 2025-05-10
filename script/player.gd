extends CharacterBody2D

const GRAVITY = 400.0
const JUMP_FORCE = -200 #Forza del salto
@export var speed = 200 #velocità, pixel al secondo
var screen_size #grandezza della finestra
var is_jumping = false

func _ready() -> void:
	pass

func _physics_process(delta):
	velocity.y += delta * GRAVITY
	if Input.is_action_pressed("ui_left"):
		velocity.x = -speed
	elif Input.is_action_pressed("ui_right"):
		velocity.x =  speed
	else:
		velocity.x = 0
	
	# Salto (solo se è a terra)
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_FORCE
		is_jumping = true
	
	if is_jumping and not is_on_floor():
		$AnimatedSprite2D.play("jump")
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.x != 0:
		$AnimatedSprite2D.play("run")
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
		$AnimatedSprite2D.play("idle")
		is_jumping = false
	# "move_and_slide" already takes delta time into account.
	move_and_slide()
