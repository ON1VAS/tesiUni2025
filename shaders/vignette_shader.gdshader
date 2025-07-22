
shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);      // Centro vignetta (fra 0 e 1)
uniform float radius = 0.4;                // Raggio vignetta (fra 0 e 1)
uniform float softness = 0.3;              // Morbidezza bordo vignetta
uniform vec4 color = vec4(0.0, 0.0, 0.0, 0.8);  // Colore vignetta (nero semitrasparente ad es.)

void fragment() {
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE.xy;
    // Normalizziamo le UV alla viewport (valori 0-1)
    vec2 norm_uv = uv / vec2(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);

    // Calcoliamo distanza dal centro normalizzato
    float dist = distance(norm_uv, center);

    // Calcoliamo l’intensità scura basata sulla distanza dal centro
    float vignette = smoothstep(radius, radius - softness, dist);

    // Colore finale con alpha dipendente da vignette
    COLOR = color * vignette;
}
