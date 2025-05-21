shader_type canvas_item;

uniform float outline_thickness : hint_range(0, 10) = 1.0; // Spessore bordatura
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Bianco

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Controlla se il pixel è trasparente ma vicino a un pixel visibile
    if (tex_color.a == 0.0) {
        float max_alpha = 0.0;
        for (float x = -outline_thickness; x <= outline_thickness; x++) {
            for (float y = -outline_thickness; y <= outline_thickness; y++) {
                vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
                float alpha = texture(TEXTURE, UV + offset).a;
                max_alpha = max(max_alpha, alpha);
            }
        }
        
        if (max_alpha > 0.0) {
            tex_color = outline_color;
        }
    }
    
    COLOR = tex_color;
}