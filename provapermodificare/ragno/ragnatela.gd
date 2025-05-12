extends Area2D

@onready var slimechan = get_tree().get_first_node_in_group("giocatore")
@onready var anim = $AnimatedSprite2D


var level = 1
var hp = 1
var speed = 1000
var damage = 10
var knock_amount = 100
var attack_size = 1.0
var bullet_life_time = 2
var stick_time = 2
var stuck = false
var tempvel = 200

#var target = slimechan
var angle = Vector2.ZERO
var direction = Vector2.ZERO

func _ready():
	direction = (slimechan.global_position - global_position).normalized()
	rotation = direction.angle()  # Ruota lo sprite nella direzione del movimento
	anim.play("attacco")
	SelfDestruct()

func _physics_process(delta):
	if not stuck:
		position += direction*speed*delta

func player_hit():
	slimechan.Damage(damage)

func SelfDestruct():
	await (get_tree().create_timer(bullet_life_time).timeout)
	self.queue_free() #fa scomparire proiettile

func Stick():
	await (get_tree().create_timer(stick_time).timeout)
	self.queue_free()  # Fa scomparire la ragnatela dopo essere rimasta attaccata

func slow_player_temporarily():
	slimechan.speed = tempvel / 2
	await get_tree().create_timer(1).timeout
	RestorePlayerSpeed() #ora la velocità torna normale

func RestorePlayerSpeed():
	slimechan.speed = tempvel

func _on_body_entered(body):
	if body.is_in_group("giocatore"):
		self.stuck = true  # Ferma la ragnatela
		self.position = self.global_position  # Mantiene la posizione attuale
		Stick()  # Chiama la funzione per distruggere la ragnatela dopo un certo periodo
		slow_player_temporarily()
		body.Damage(damage)
	elif body is TileMap:
		self.queue_free()
