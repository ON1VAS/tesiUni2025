extends CanvasLayer

const DEBUG_FORCE := false   # metti true per vedere sempre l’overlay
const LOG := true

@onready var rect: ColorRect = $Vignette
@onready var mat: ShaderMaterial = rect.material

var _is_platform_scene := false

func _ready() -> void:
	if rect == null:
		push_error("[VignetteOverlay] ERRORE: ColorRect 'Vignette' non trovato!")
		return

	layer = 100
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Full screen
	rect.anchors_preset = Control.PRESET_FULL_RECT
	rect.offset_left = 0
	rect.offset_top = 0
	rect.offset_right = 0
	rect.offset_bottom = 0
	rect.size = get_viewport().get_visible_rect().size

	# Shader vignette semplice (SCREEN_UV)
	if not mat:
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;

/* Regola il buco centrale (più alti = visione più stretta) */
uniform float start : hint_range(0.0, 1.0) = 0.4;
uniform float end   : hint_range(0.0, 1.0) = 0.7;

/* >1.0 = visione più stretta in orizzontale; 1.0 = cerchio */
uniform float horiz_tightness : hint_range(0.1, 5.0) = 1.6;
/* opzionale: verticale, lascia 1.0 se non ti serve */
uniform float vert_tightness  : hint_range(0.1, 5.0) = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;          // 0..1 su tutto lo schermo
	vec2 center = vec2(0.5, 0.5); // centro
	vec2 d = uv - center;         // vettore dal centro

	// schiaccia/espandi gli assi per ottenere un'ellisse
	d.x *= horiz_tightness;
	d.y *= vert_tightness;

	float dist = length(d);       // distanza ellittica
	float vignette = smoothstep(start, end, dist);

	// nero con alpha = vignette (solo i bordi diventano opachi)
	COLOR = vec4(0.0, 0.0, 0.0, vignette);
}
"""
		mat = ShaderMaterial.new()
		mat.shader = shader
		rect.material = mat

	# evita che il colore annulli lo shader
	rect.color = Color(1, 1, 1, 1)

	get_viewport().size_changed.connect(_on_viewport_resized)

	if not DebuffManager.debuffs_updated.is_connected(_on_debuffs_updated):
		DebuffManager.debuffs_updated.connect(_on_debuffs_updated)
	get_tree().tree_changed.connect(_on_tree_changed)

	_recalc_scene_and_refresh()

	if LOG:
		var cs := get_tree().current_scene
		var scene_name := "null"
		var in_group := false
		if cs != null:
			scene_name = cs.name
			in_group = cs.is_in_group("PLATFORM_CAMPAIGN")
		print("[VignetteOverlay] ready  size=", rect.size, "  scene=", scene_name, "  in_group=", in_group)


func _on_viewport_resized() -> void:
	rect.size = get_viewport().get_visible_rect().size

func _on_tree_changed() -> void:
	# Ogni volta che cambia l'albero (carichi/unloadi un livello), ricontrolla
	call_deferred("_recalc_scene_and_refresh")

func _on_debuffs_updated() -> void:
	_refresh_visibility()

func _recalc_scene_and_refresh() -> void:
	# Niente group scan: ci fidiamo del platform_mode del DebuffManager
	_refresh_visibility()

func _refresh_visibility() -> void:
	var show := DebuffManager.platform_mode and DebuffManager.is_vignette_active()
	rect.visible = show
	if LOG:
		print("[VignetteOverlay] refresh  visible=", rect.visible,
			  "  platform_mode=", DebuffManager.platform_mode,
			  "  debuff=", DebuffManager.is_vignette_active())
