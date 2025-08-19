extends Node

enum Mode { PLATFORM_CAMPAIGN, SURVIVOR_MODE }

# Queste restano tipate e visibili in Inspector
@export var platform_campaign_levels: Array[PackedScene] = []
@export var survivor_mode_levels: Array[PackedScene] = []

# Nota: niente Dictionary generico (in alcune versioni crea warning->error)
var _index_by_mode: Dictionary = {
	Mode.PLATFORM_CAMPAIGN: -1,
	Mode.SURVIVOR_MODE: -1,
}

var current_mode: int = Mode.PLATFORM_CAMPAIGN

func _get_levels(mode: int) -> Array[PackedScene]:
	match mode:
		Mode.PLATFORM_CAMPAIGN:
			return platform_campaign_levels
		Mode.SURVIVOR_MODE:
			return survivor_mode_levels
		_:
			# Ritorna un array vuoto ma CASTATO al tipo corretto
			return ([] as Array[PackedScene])

func start_run(mode: int) -> void:
	current_mode = mode
	_index_by_mode[mode] = 0

func get_current_scene(mode: int = -1) -> PackedScene:
	if mode == -1:
		mode = current_mode
	var levels: Array[PackedScene] = _get_levels(mode) as Array[PackedScene]
	var idx: int = int(_index_by_mode.get(mode, -1))
	if idx >= 0 and idx < levels.size():
		return levels[idx]
	return null

func get_next_scene(mode: int = -1) -> PackedScene:
	if mode == -1:
		mode = current_mode
	var levels: Array[PackedScene] = _get_levels(mode) as Array[PackedScene]
	var idx: int = int(_index_by_mode.get(mode, -1)) + 1
	if idx >= 0 and idx < levels.size():
		return levels[idx]
	return null

func advance_and_get_next(mode: int = -1) -> PackedScene:
	if mode == -1:
		mode = current_mode
	var levels: Array[PackedScene] = _get_levels(mode) as Array[PackedScene]
	var next_idx: int = int(_index_by_mode.get(mode, -1)) + 1
	if next_idx < levels.size():
		_index_by_mode[mode] = next_idx
		return levels[next_idx]
	return null

func is_last_level(mode: int = -1) -> bool:
	if mode == -1:
		mode = current_mode
	var levels: Array[PackedScene] = _get_levels(mode) as Array[PackedScene]
	var idx: int = int(_index_by_mode.get(mode, -1))
	return idx >= 0 and idx == levels.size() - 1
