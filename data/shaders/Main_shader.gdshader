shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform float pixel_size : hint_range(1.0, 16.0) = 8.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.15;

// High-contrast dungeon palette
const vec3 palette[16] = vec3[16](
    vec3(0.000, 0.000, 0.000), // Black
    vec3(0.050, 0.050, 0.090), // Near-black blue
    vec3(0.090, 0.120, 0.220), // Dark navy
    vec3(0.120, 0.180, 0.380), // Deep blue
    vec3(0.200, 0.280, 0.550), // Mid blue
    vec3(0.380, 0.520, 0.850), // Bright blue

    vec3(0.090, 0.180, 0.100), // Dark green
    vec3(0.250, 0.500, 0.250), // Mid green
    vec3(0.600, 0.800, 0.350), // Bright green

    vec3(0.450, 0.250, 0.150), // Brown
    vec3(0.700, 0.350, 0.150), // Orange-brown
    vec3(0.950, 0.550, 0.200), // Torch orange
    vec3(1.000, 0.800, 0.400), // Warm light

    vec3(0.650, 0.350, 0.850), // Purple accent
    vec3(0.850, 0.650, 1.000), // Bright purple

    vec3(1.000, 1.000, 1.000)  // White
);

const int palette_size = 16;

const mat4 bayer_matrix = mat4(
    vec4(0.0/16.0, 8.0/16.0, 2.0/16.0, 10.0/16.0),
    vec4(12.0/16.0, 4.0/16.0, 14.0/16.0, 6.0/16.0),
    vec4(3.0/16.0, 11.0/16.0, 1.0/16.0, 9.0/16.0),
    vec4(15.0/16.0, 7.0/16.0, 13.0/16.0, 5.0/16.0)
);

float luminance(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 find_closest_color(vec3 color) {

    vec3 closest = palette[0];
    float best_score = 99999.0;

    float color_luma = luminance(color);

    for (int i = 0; i < palette_size; i++) {

        vec3 pal = palette[i];

        float rgb_dist = distance(color, pal);

        float lum_dist = abs(color_luma - luminance(pal));

        // Weight brightness more heavily than raw RGB distance.
        float score = rgb_dist + lum_dist * 1.5;

        if (score < best_score) {
            best_score = score;
            closest = pal;
        }
    }

    return closest;
}

void fragment() {

    // Pixelation
    vec2 size = vec2(textureSize(SCREEN_TEXTURE, 0)) / pixel_size;
    vec2 pixelated_uv = floor(SCREEN_UV * size) / size;

    vec3 color = texture(SCREEN_TEXTURE, pixelated_uv).rgb;

    // Contrast boost
    color = (color - 0.5) * 1.4 + 0.5;

    // Slight saturation boost
    float lum = luminance(color);
    color = mix(vec3(lum), color, 1.25);

    // Optional brightness quantization
    color = floor(color * 8.0) / 8.0;

    // Bayer dithering
    ivec2 pixel_coord = ivec2(mod(FRAGCOORD.xy / pixel_size, 4.0));
    float threshold = bayer_matrix[pixel_coord.x][pixel_coord.y];

    vec3 dithered_color =
        color +
        (threshold - 0.5) * dither_strength;

    dithered_color = clamp(dithered_color, 0.0, 1.0);

    COLOR.rgb = find_closest_color(dithered_color);
    COLOR.a = 1.0;
}