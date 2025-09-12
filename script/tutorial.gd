extends Node2D
@onready var sfondo = $Sprite2D
@onready var player = $protagonista

func _process(delta):
	# Mantieni solo la coordinata X del player
	sfondo.position.x = player.position.x

func _ready():
	DebuffManager.set_platform_mode(false)
	DebuffManager.apply_to_player($protagonista)

func _on_debuff_salto_body_entered(body: Node2D) -> void:
	if body.is_in_group("giocatore"):
		DebuffManager.set_platform_mode(true)
		DebuffManager.add_debuff("NO_JUMP")
		DebuffManager.apply_to_player(player)


func _on_debuff_salto_body_exited(body: Node2D) -> void:
	if body.is_in_group("giocatore"):
		DebuffManager.remove_debuff("NO_JUMP")
		DebuffManager.apply_to_player(player)
		DebuffManager.set_platform_mode(false)
