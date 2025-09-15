# pause_menu.gd (Godot 4.x)
extends CanvasLayer
class_name PauseMenu

const ACTION_PAUSE := "ui_cancel"   # mappata a ESC

# --- autoload ---
@onready var level_flow: Node = get_node("/root/LevelFlow")
@onready var persist := get_node_or_null("/root/Persist") 

# --- UI (match alla tua gerarchia dello screenshot) ---
@onready var root_ctrl: Control      = $Control
@onready var backdrop: ColorRect     = $Control/BackDrop
@onready var panel: PanelContainer   = $Control/Center/Panel
@onready var resume_btn: Button      = $Control/Center/Panel/MarginContainer/VBoxContainer/HBoxContainer/ResumeBtn
@onready var main_btn: Button        = $Control/Center/Panel/MarginContainer/VBoxContainer/HBoxContainer/MainMenuBtn
# Slider: nella tua AudioGrid i controlli con icona % sono gli HSlider
@onready var master_slider: HSlider  = $Control/Center/Panel/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/Master
@onready var music_slider: HSlider   = $Control/Center/Panel/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/Music
@onready var sfx_slider: HSlider     = $Control/Center/Panel/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/SFX

# Indici bus audio (adattali ai tuoi)
const BUS_MASTER := 0
const BUS_MUSIC  := 1
const BUS_SFX    := 2

var _open := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_apply_visible(false)

	# sanity check: se un path è sbagliato lo vedi subito
	assert(root_ctrl and backdrop and panel and resume_btn and main_btn and master_slider and music_slider and sfx_slider)

	# --- init slider da Persist (lineare 0..1) ---
	_load_and_apply_volume(BUS_MASTER, master_slider)
	_load_and_apply_volume(BUS_MUSIC,  music_slider)
	_load_and_apply_volume(BUS_SFX,    sfx_slider)

	# --- connessioni come in audio.gd ---
	master_slider.value_changed.connect(func(v): _set_volume_and_save(BUS_MASTER, v))
	music_slider.value_changed.connect(func(v): _set_volume_and_save(BUS_MUSIC,  v))
	sfx_slider.value_changed.connect(func(v): _set_volume_and_save(BUS_SFX,    v))

	resume_btn.pressed.connect(_on_resume_pressed)
	main_btn.pressed.connect(_on_main_menu_pressed)

func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_platform_campaign():
		return
	if event.is_action_pressed(ACTION_PAUSE) and not event.is_echo():
		toggle()

func _is_platform_campaign() -> bool:
	return int(level_flow.current_mode) == int(level_flow.Mode.PLATFORM_CAMPAIGN)

func toggle() -> void:
	_open = not _open
	_apply_visible(_open)

func _apply_visible(v: bool) -> void:
	root_ctrl.visible = v        # mostra/nascondi tutto il menu
	backdrop.visible = v         # oscura lo sfondo
	get_tree().paused = v
	if v:
		resume_btn.grab_focus()

func _on_resume_pressed() -> void:
	if _open:
		toggle()

func _on_main_menu_pressed() -> void:
	_apply_visible(false)
	_open = false
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://scene/menu.tscn")  
	LevelFlow.current_mode = LevelFlow.Mode.NONE

# ---- helpers audio ----
func _db_to_norm(db: float) -> float:
	var min_db := -80.0
	var max_db := 6.0
	return clamp((db - min_db) / (max_db - min_db), 0.0, 1.0)

func _norm_to_db(n: float) -> float:
	var min_db := -80.0
	var max_db := 6.0
	return lerp(min_db, max_db, clamp(n, 0.0, 1.0))

func _set_bus_norm(bus_idx: int, n: float) -> void:
	AudioServer.set_bus_volume_db(bus_idx, _norm_to_db(n))

func _load_and_apply_volume(bus_idx: int, slider: HSlider) -> void:
	var value := 1.0  # fallback se non troviamo Persist o la chiave
	if persist:
		# assicuriamoci che il file sia caricato
		if persist.config.load(Persist.PATH) != OK:
			persist.save_data()  # crea il file se manca
		value = float(persist.config.get_value("Audio", str(bus_idx), 1.0))
	slider.value = value
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _set_volume_and_save(bus_idx: int, value: float) -> void:
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	if "Persist" in Engine.get_singleton_list():
		Persist.config.set_value("Audio", str(bus_idx), value)
		Persist.save_data()
