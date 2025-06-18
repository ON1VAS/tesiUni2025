# This script can be attached to the ColorRect node.
# It creates and assigns a ShaderMaterial with a vignette effect shader.

extends ColorRect


func _ready():
	anchors_preset = Control.PRESET_FULL_RECT
	size = get_viewport_rect().size
	var shader_code := """
shader_type canvas_item;
uniform float aspect_ratio;
void fragment() {
	// UV coords from 0 to 1 (bottom-left to top-right)
	vec2 uv = UV;
	// Center position at (0.5, 0.5)
	vec2 center = vec2(0.5, 0.5);
	vec2 scaled_uv = vec2(uv.x, (uv.y - center.y) * aspect_ratio + center.y);
	float dist = distance(scaled_uv, center);
	// Vignette radius adjustments:
	// Start of darkening from center (e.g., 0.3)
	float start = 0.2;
	// Full black at edge (e.g., 0.7)
	float end = 0.4;

	// Smoothstep for smooth gradient
	float vignette = smoothstep(start, end, dist);

	// Alpha is vignette, color black
	COLOR = vec4(0.0, 0.0, 0.0, vignette);
}
	"""
	var shader = Shader.new()
	shader.code = shader_code
	var mat = ShaderMaterial.new()
	mat.shader = shader
	self.material = mat
	update_aspect_ratio_uniform()
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_resize"))

func _process(delta):
	# Access the vignette activation state from DebuffManager singleton
	if DebuffManager.is_vignette_active():
		self.visible = true
	else:
		self.visible = false

func update_aspect_ratio_uniform():
	var w = get_viewport_rect().size.x
	var h = get_viewport_rect().size.y
	var aspect = h / w   # Notice: height divided by width to scale y correctly
	if material and material.shader:
		material.set_shader_parameter("aspect_ratio", aspect)

func _on_viewport_resize():
	size = get_viewport_rect().size
	update_aspect_ratio_uniform()
