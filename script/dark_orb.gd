extends Area2D

@export var speed: float = 150.0
var direction := Vector2.ZERO
var launched := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	anim.play("spawn")  # Animazione iniziale

func launch(towards: Vector2):
	direction = (towards - global_position).normalized()
	launched = true
	anim.play("attack")  # Passa all'animazione di lancio

func _physics_process(delta):
	if launched:
		position += direction * speed * delta

func _on_area_entered(area: Area2D):
	if area.is_in_group("giocatore"):
		area.Damage(10)  # o qualunque danno tu voglia
		anim.play("death")
		await anim.animation_finished
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("giocatore"):
		body.Damage(10)  # o qualunque danno tu voglia
		anim.play("death")
		await anim.animation_finished
		queue_free()
