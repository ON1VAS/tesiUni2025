extends Node
signal lock_changed

var _until_unix: int = 0 # timestamp unix in secondi

func start(seconds: int = 300) -> void:
	_until_unix = Time.get_unix_time_from_system() + seconds
	emit_signal("lock_changed")

func is_active() -> bool:
	return remaining() > 0

func remaining() -> int:
	var rem := _until_unix - Time.get_unix_time_from_system()
	if rem > 0:
		return rem
	else:
		return 0


func clear() -> void:
	_until_unix = 0
	emit_signal("lock_changed")
