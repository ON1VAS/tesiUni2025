extends Area2D

@onready var slimechan = get_tree().get_first_node_in_group("giocatore")
@onready var anim = $AnimatedSprite2D


var level = 1
var hp = 1
var speed = 1000
var damage = 35
var knock_amount = 100
var attack_size = 1.0
var bullet_life_time = 2

#così colpisce il protagonista
var angle = Vector2.ZERO
var direction = Vector2.ZERO

func _ready():
	direction = (slimechan.global_position - global_position).normalized()
	rotation = direction.angle()  # Ruota lo sprite nella direzione del movimento
	anim.play("attacco")
	SelfDestruct()
	
func _physics_process(delta):
	position += direction*speed*delta

func player_hit():
	slimechan.Damage(damage)

func SelfDestruct():
	await (get_tree().create_timer(bullet_life_time).timeout)
	self.queue_free() #fa scomparire proiettile
