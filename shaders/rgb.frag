#pragma header
vec2 uv = openfl_TextureCoordv.xy;

uniform vec3 red;
uniform vec3 green;
uniform vec3 blue;
uniform float visor;
uniform float opacity;

vec3 rgb2hsv(vec3 color) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(color.b, color.g, K.w, K.z), vec4(color.g, color.b, K.x, K.y), step(color.b, color.g));
    vec4 q = mix(vec4(p.x, p.y, p.w, color.r), vec4(color.r, p.y, p.z, p.x), step(p.x, color.r));
    float d = q.x - min(q.w, q.y);
    float e = 0.00001;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

void main() {
    vec4 texColor = texture2D(bitmap, uv);
    vec3 gHsv = rgb2hsv(vec3(texColor.r, texColor.g, texColor.b));
	float tAlpha = texColor.a * opacity;
    gl_FragColor = vec4(
    (((texColor.r * red.x) + (texColor.g * green.x) + (texColor.b * blue.x)) * gHsv.y + (1.0 - gHsv.y) * gHsv.z) * tAlpha,
    (((texColor.r * red.y) + (texColor.g * green.y) + (texColor.b * blue.y)) * gHsv.y + (1.0 - gHsv.y) * gHsv.z) * tAlpha,
    (((texColor.r * red.z) + (texColor.g * green.z) + (texColor.b * blue.z)) * gHsv.y + (1.0 - gHsv.y) * gHsv.z + visor * ((1 - texColor.g) * (1 - texColor.r) * (1 - texColor.b)) * gHsv.z) * tAlpha,
    tAlpha); //a
}
