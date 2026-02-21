#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 color;
    float progress;
    vec2 center;
    float aspect;
} ubuf;

// Pseudo-random noise for the "Sparkle" effect
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 dvec = uv - ubuf.center;
    dvec.x *= ubuf.aspect;
    
    // Scale progress to cover the entire screen even from corners.
    // The maximum distance from any point to a corner is sqrt(width^2 + height^2).
    // In UV space (0-1), max distance is sqrt(aspect^2 + 1.0).
    // We multiply progress by ~2.5 to ensure full coverage.
    float scaledProgress = ubuf.progress * 2.5;
    
    float d = length(dvec);

    // 1. The "Fluid" Expansion Mask
    // Use wider steps for better intensity and coverage
    float ring = smoothstep(scaledProgress - 0.2, scaledProgress, d) * 
                 smoothstep(scaledProgress + 0.2, scaledProgress, d);
    
    // 2. The "Sparkle" Shimmer
    float n = hash(uv * 150.0 + ubuf.progress);
    float sparkles = pow(n, 15.0) * ring * 4.0; // Increased intensity
    
    // 3. The "Aura" Glow
    float glow = exp(-pow(d - scaledProgress, 2.0) * 40.0) * 0.6;

    // Combine layers and apply alpha fade-out
    vec4 finalColor = ubuf.color * (ring + sparkles + glow);
    fragColor = finalColor * ubuf.qt_Opacity * (1.0 - ubuf.progress);
}
