extends CanvasLayer

@onready var icon_rect: TextureRect = $MarginContainer/Icon

func _ready() -> void:
	print("HUD Ready")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_ui(DebuffManager.get_primary_debuff())
	# reagisce sia ai cambi debuff sia al cambio platform_mode
	DebuffManager.debuffs_updated.connect(_on_state_changed)

func _on_state_changed() -> void:
	print("[HUD] debuffs_updated ->", DebuffManager.get_active_debuffs())
	_refresh_ui(DebuffManager.get_primary_debuff())

func _refresh_ui(debuff_name: String) -> void:
	if not DebuffManager.platform_mode or debuff_name == "":
		hide()
		icon_rect.texture = null
		return
	show()
	icon_rect.texture = DebuffManager.DEBUFF_ICON.get(debuff_name, null)
