extends Node2D

func _ready() -> void:
	DebuffManager.set_platform_mode(true)
	DebuffManager.apply_to_player($protagonista)
