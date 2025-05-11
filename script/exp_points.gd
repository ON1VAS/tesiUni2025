extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	self.is_in_group("monete")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	pass


func _on_body_entered(body):
	if body.is_in_group("giocatore"):
		queue_free()
		body.exp += 50
		body.health += 30 #si cura quando raccoglie exp
		body.SetHealthBar()
		body.SetExpBar()
