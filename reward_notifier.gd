extends Control

@onready var panel = $PanelContainer
@onready var container = $PanelContainer/VBoxContainer

func show_reward(text: String, icon: Texture2D = null):
	self.visible = true
	
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	if icon:
		var tex_rect := TextureRect.new()
		tex_rect.texture = icon
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_rect.custom_minimum_size = Vector2(32, 32)
		hbox.add_child(tex_rect)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = false
	hbox.add_child(label)
	container.add_child(hbox)
	await get_tree().create_timer(3).timeout
	hbox.queue_free()
	self.visible = true
