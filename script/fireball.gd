extends Area2D

@export var speed = 400
@export var damage = 35
@export var lifetime = 1.0
@onready var slimechan = get_tree().get_first_node_in_group("giocatore")
var direction = Vector2.ZERO
@onready var anim = $AnimatedSprite2D

func _ready():
	direction = (slimechan.global_position - global_position).normalized()
	rotation = direction.angle()  # Ruota lo sprite nella direzione del movimento
	anim.play("default")
	area_entered.connect(_on_area_entered)
	var notifier = VisibleOnScreenNotifier2D.new()
	notifier.rect = Rect2(Vector2(-16, -16), Vector2(32, 32))  # Dimensione adattiva
	add_child(notifier)
	notifier.connect("screen_exited", Callable(self, "destroy"))

func _physics_process(delta):
	position += direction * speed * delta

func player_hit():
	slimechan.Damage(damage)

func start_lifetime_timer():
	await get_tree().create_timer(lifetime).timeout
	destroy()

func _on_body_entered(body: Node2D):
	if body.is_in_group("giocatore"):
		body.Damage(damage)
		destroy()

func _on_area_entered(area: Area2D):
	if area.is_in_group("player_hitbox"):
		if area.get_parent().has_method("take_damage"):
			area.get_parent().Damage(damage)
		destroy()

func destroy():
	self.queue_free()
