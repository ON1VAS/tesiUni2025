extends Node

const PATH = "user://settings.cfg"
var config = ConfigFile.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	for action in InputMap.get_actions():
		if InputMap.action_get_events(action).size() != 0:
			config.set_value("Controls",action,InputMap.action_get_events(action)[0])
	
	
	for i in range(3):
		config.set_value("Audio", str(i), 0.0)
	
	load_data()

func save_data():
	config.save(PATH)

func load_data():
	if config.load("user://settings.cfg") != OK:
		save_data()
		return
