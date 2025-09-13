extends CanvasLayer

@onready var color_rect      : ColorRect      = $ColorRect
@onready var center_container: CenterContainer= $CenterContainer
@onready var panel           : Panel          = $CenterContainer/Panel
@onready var vbox            : VBoxContainer  = $CenterContainer/Panel/VBoxContainer
@onready var main_label      : Label          = $CenterContainer/Panel/VBoxContainer/MainLabel
@onready var seconds_label   : Label          = $CenterContainer/Panel/VBoxContainer/SecondsLabel

var _counting := false

func _ready() -> void:
	# Full screen per sfondo e "centratore"
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Larghezza "contenuta": CenterContainer centra il Panel usando la sua minimum size
	_apply_layout()
	get_viewport().size_changed.connect(_apply_layout)

	# Testo
	main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	seconds_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# VBox: allinea al centro e lascia che riempia orizzontalmente il Panel
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Le label riempiono la VBox (così il centro funziona davvero)
	main_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seconds_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _apply_layout() -> void:
	var vw = float(get_viewport().size.x)
	var w = min(900.0, vw * 0.9)  # max 900px o 90% dello schermo
	panel.custom_minimum_size.x = w
	vbox.custom_minimum_size.x  = w  # garantisce che le label “vedano” quella larghezza

func show_countdown(start_at: int = 5) -> void:
	if _counting: return
	visible = true
	_counting = true
	main_label.text = "Hai perso! Tornerai al menù tra"
	for i in range(start_at, 0, -1):
		var unit := "secondi"
		if i == 1: unit = "secondo"
		seconds_label.text = "%d %s!" % [i, unit]
		await get_tree().create_timer(1.0).timeout
	_counting = false

func hide_overlay() -> void:
	visible = false
