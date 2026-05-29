shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.6;

// Changed from 'uniform vec3 palette[32]' to 'const vec3 palette[32]'
const vec3 palette[32] = vec3[32](
    vec3(0.0, 0.0, 0.0), // 0: Black
    vec3(0.051, 0.012, 0.063), // 1: Deep purple-black
    vec3(0.102, 0.024, 0.125), // 2: Dark purple 
    vec3(0.082, 0.153, 0.024), // 3: Dark green
    vec3(0.133, 0.063, 0.227), // 4: Dark blue
    vec3(0.251, 0.086, 0.275), // 5: Mid purple
    vec3(0.153, 0.259, 0.075), // 6: Mid green
    vec3(0.294, 0.129, 0.416), // 7: Light purple
    vec3(0.125, 0.125, 0.502), // 8: Royal blue
    vec3(0.486, 0.169, 0.522), // 9: Magenta
    vec3(0.255, 0.412, 0.145), // 10: Lime green
    vec3(0.584, 0.216, 0.639), // 11: Pink purple
    vec3(0.196, 0.196, 0.757), // 12: Bright blue
    vec3(0.451, 0.584, 0.259), // 13: Light green
    vec3(0.780, 0.255, 0.780), // 14: Hot pink
    vec3(0.302, 0.302, 0.980), // 15: Cornflower blue
    vec3(0.667, 0.780, 0.416), // 16: Pale green
    vec3(0.255, 0.490, 0.639), // 17: Steel blue
    vec3(0.859, 0.314, 0.859), // 18: Light magenta
    vec3(0.420, 0.420, 1.0), // 19: Light blue
    vec3(0.639, 0.349, 0.227), // 20: Brown
    vec3(0.871, 0.871, 0.573), // 21: Pale yellow
    vec3(0.420, 0.678, 0.780), // 22: Sky blue
    vec3(0.859, 0.490, 0.314), // 23: Orange
    vec3(1.0, 0.459, 0.459), // 24: Salmon
    vec3(0.980, 0.671, 0.420), // 25: Peach
    vec3(0.537, 0.839, 0.922), // 26: Baby blue
    vec3(1.0, 0.627, 0.580), // 27: Light salmon
    vec3(1.0, 0.808, 0.580), // 28: Light orange
    vec3(0.690, 0.941, 1.0), // 29: Ice blue
    vec3(1.0, 0.890, 0.710), // 30: Cream
    vec3(1.0, 1.0, 1.0) // 31: White
);

const int palette_size = 32;

const mat4 bayer_matrix = mat4(
    vec4(0.0/16.0, 8.0/16.0, 2.0/16.0, 10.0/16.0),
    vec4(12.0/16.0, 4.0/16.0, 14.0/16.0, 6.0/16.0),
    vec4(3.0/16.0, 11.0/16.0, 1.0/16.0, 9.0/16.0),
    vec4(15.0/16.0, 7.0/16.0, 13.0/16.0, 5.0/16.0)
);

vec3 find_closest_color(vec3 color) {
    vec3 closest = palette[0];
    float min_dist = distance(color, palette[0]);
    
    for (int i = 1; i < palette_size; i++) {
        float dist = distance(color, palette[i]);
        if (dist < min_dist) {
            min_dist = dist;
            closest = palette[i];
        }
    }
    return closest;
}

void fragment() {
    // 1. CHUNKY PIXELS (Godot 4 compatible math)
    vec2 size = vec2(textureSize(SCREEN_TEXTURE, 0)) / pixel_size;
    vec2 pixelated_uv = floor(SCREEN_UV * size) / size;
    vec3 color = texture(SCREEN_TEXTURE, pixelated_uv).rgb;
    
    // 2. ORDERED DITHERING
    ivec2 pixel_coord = ivec2(mod(FRAGCOORD.xy / pixel_size, 4.0));
    float threshold = bayer_matrix[pixel_coord.x][pixel_coord.y];
    
    // Apply dither before quantization
    vec3 dithered_color = color + (threshold - 0.5) * dither_strength;
    
    // 3. PALETTE RESTRICTION
    COLOR.rgb = find_closest_color(dithered_color);
    COLOR.a = 1.0;
}