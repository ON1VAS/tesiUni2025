extends CharacterBody2D

const GRAVITY = 200.0
@export var speed = 200 #velocità, pixel al secondo
var screen_size #grandezza della finestra

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
	
	if velocity.x != 0:
		
			$AnimatedSprite2D.play("run" if velocity.x!= 0 else "up")
			$AnimatedSprite2D.flip_v = false
			$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
			$AnimatedSprite2D.play("idle")
	# "move_and_slide" already takes delta time into account.
	move_and_slide()

#func MovementLoop(delta): #funzione che gestisce il movimento
	var input_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_direction.x += 1
	if Input.is_action_pressed("ui_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_direction.y += 1
	if Input.is_action_pressed("ui_up"):
		input_direction.y -= 1
	
	input_direction = input_direction.normalized()
	velocity = input_direction * speed
	
	#move_and_slide() 
