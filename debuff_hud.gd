extends CanvasLayer

const MAX_ICONS := 9  # quante icone mostrare al massimo (poi appare +N)
const ICON_SIZE := Vector2i(20, 20) # se l'inspector dovesse non essere letto, 20 px è il min

@onready var icons_row: HBoxContainer = $MarginContainer/Icons

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not DebuffManager.debuffs_updated.is_connected(_on_state_changed):
		DebuffManager.debuffs_updated.connect(_on_state_changed)
	_rebuild_icons()

func _on_state_changed() -> void:
	_rebuild_icons()

func _rebuild_icons() -> void:
	_clear_icons()

	# Prendi i debuff attivi (accetta sia Array[String] sia PackedStringArray)
	var names := DebuffManager.get_active_debuffs()
	var count := int(names.size())
	var in_platform := DebuffManager.platform_mode if "platform_mode" in DebuffManager else true

	if count == 0 or not in_platform:
		hide()
		return

	# Ordina in modo stabile (prima quelli più “gameplay”, poi alfabetico)
	var sorted: Array[String] = _sorted_names(names)

	var shown := 0
	for n in sorted:
		if shown >= MAX_ICONS:
			break
		var tex: Texture2D = DebuffManager.DEBUFF_ICON.get(n, null) if "DEBUFF_ICON" in DebuffManager else null
		if tex == null:
			print("[HUD] Nessuna icona per ", n)
			continue
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = ICON_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tr.tooltip_text = _tooltip_for(n)
		icons_row.add_child(tr)
		shown += 1

	# Se hai più di MAX_ICONS, mostra “+N”
	if count > MAX_ICONS and shown > 0:
		var extra := count - MAX_ICONS
		var lbl := Label.new()
		lbl.text = "+" + str(extra)
		icons_row.add_child(lbl)

	# Se non ha mostrato nulla (tutte icone mancanti), nascondi
	if shown == 0:
		hide()
	else:
		show()

func _clear_icons() -> void:
	for c in icons_row.get_children():
		c.queue_free()

func _sorted_names(names_in) -> Array[String]:
	# Converte in Array[String] e ordina con una priorità definita
	var arr: Array[String] = []
	for s in names_in:
		arr.append(String(s))

	# Mappa di priorità visiva (0 = prima). Aggiungi/togli a piacere.
	var order := {
		"HP_DRAIN": 0,
		"SLOW": 1,
		"HALF_JUMP": 2,
		"NO_ROLL": 3,
		"ATTACK_DELAY": 4,
		"LOW_DAMAGE": 5,
		"ENEMY_DAMAGE_UP": 6,
		"INVERT_COMMANDS": 7,
		"SLIDING": 8,
		"VIGNETTE": 9,
	}
	arr.sort_custom(func(a, b):
		var ia = order.get(a, 1000)
		var ib = order.get(b, 1000)
		if ia == ib:
			return a < b
		else:
			return ia < ib
	)
	return arr

func _tooltip_for(n: String) -> String:
	if "DEBUFF_DESC" in DebuffManager and DebuffManager.DEBUFF_DESC.has(n):
		return DebuffManager.DEBUFF_DESC[n]
	return _humanize(n)

func _humanize(key: String) -> String:
	var p := key.split("_")                 # PackedStringArray
	var parts: Array[String] = []           # Array tipizzato
	for s in p:
		parts.append(String(s).capitalize())
	return " ".join(parts)
