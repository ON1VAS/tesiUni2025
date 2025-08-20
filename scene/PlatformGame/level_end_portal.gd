extends Area2D

@export_file("*.tscn") var rest_scene_path := "res://scene/PlatformGame/riposo_fine_livello.tscn"
@export var player_group: String = "giocatore"  # <-- usa il tuo gruppo
var _done := false

func _ready() -> void:
	monitoring = true
	monitorable = true
	# Assicurati che il CollisionShape2D sia abilitato
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Debug minimale per capire se entra qualcuno
	print("Portal: body entered -> ", body.name, " groups=", body.get_groups())

	if _done:
		return
	if not (body is PhysicsBody2D):
		return
	if not body.is_in_group(player_group):
		return

	_done = true
	# usciamo dal livello platform: la scena di riposo non è platform
	DebuffManager.set_platform_mode(false)

	# (se usi una transizione, falla qui)
	# TransitionScreen.transition()
	# await TransitionScreen.on_transition_finished

	get_tree().change_scene_to_file(rest_scene_path)
