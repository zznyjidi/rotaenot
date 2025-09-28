shader_type canvas_item;

// Mask parameters
uniform vec2 ellipse_size = vec2(144.0, 200.0);  // Size of the ellipse in pixels
uniform float edge_softness = 2.0;  // Pixels for edge fade
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform bool use_screen_copy = true;  // Whether to copy screen or use solid color
uniform vec4 solid_color : source_color = vec4(0.02, 0.02, 0.05, 1.0);  // Fallback color

void fragment() {
    // Get the position in world space (relative to mask center)
    vec2 world_size = vec2(288.0, 400.0);  // Total size of mask area
    vec2 world_pos = (UV - 0.5) * world_size;

    // Calculate if we're inside the ellipse
    float x_norm = world_pos.x / ellipse_size.x;
    float y_norm = world_pos.y / ellipse_size.y;
    float dist_sq = x_norm * x_norm + y_norm * y_norm;

    if (dist_sq <= 1.0) {
        // Inside the ellipse
        vec4 color;

        if (use_screen_copy) {
            // Sample the background from screen
            color = texture(screen_texture, SCREEN_UV);
        } else {
            // Use solid color
            color = solid_color;
        }

        // Apply edge softness
        float edge_dist = sqrt(dist_sq);
        float alpha = 1.0 - smoothstep(1.0 - (edge_softness / min(ellipse_size.x, ellipse_size.y)), 1.0, edge_dist);

        COLOR = vec4(color.rgb, color.a * alpha);
    } else {
        // Outside the ellipse - fully transparent
        COLOR = vec4(0.0);
    }
}