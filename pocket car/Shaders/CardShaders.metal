
#include <metal_stdlib>
using namespace metal;

// ... (VertexIn, VertexOut, vertexShader, calculateScanlineEffect, hash, simpleNoise, blendOverlay restent identiques) ...
struct VertexIn {
    float3 position [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
};

vertex VertexOut vertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 1.0);
    out.texCoords = in.texCoords;
    return out;
}

float calculateScanlineEffect(float2 uv, float time, float speed, float thickness, float intensity) {
    float scanlineCenterY = fract(time * speed);
    float distanceToScanline = abs(uv.y - scanlineCenterY);
    float halfThickness = thickness / 2.0;
    float line = 1.0 - smoothstep(0.0, halfThickness, distanceToScanline);
    return line * intensity;
}

float hash(float2 p) {
    float co = dot(p, float2(12.9898, 78.233));
    return fract(sin(co) * 43758.5453);
}

float simpleNoise(float2 uv, float scale) {
    float2 scaled_uv = uv * scale;
    float2 ipos = floor(scaled_uv);
    float2 fpos = fract(scaled_uv);
    fpos = fpos * fpos * (3.0 - 2.0 * fpos);
    float bottom_left = hash(ipos + float2(0.0, 0.0));
    float bottom_right = hash(ipos + float2(1.0, 0.0));
    float top_left = hash(ipos + float2(0.0, 1.0));
    float top_right = hash(ipos + float2(1.0, 1.0));
    float mix_bottom = mix(bottom_left, bottom_right, fpos.x);
    float mix_top = mix(top_left, top_right, fpos.x);
    return mix(mix_bottom, mix_top, fpos.y);
}

float overlayComponent(float b, float t) {
    return (b <= 0.5) ? (2.0 * b * t) : (1.0 - 2.0 * (1.0 - b) * (1.0 - t));
}

float3 blendOverlay(float3 base, float3 top) {
    return float3(
        overlayComponent(base.r, top.r),
        overlayComponent(base.g, top.g),
        overlayComponent(base.b, top.b)
    );
}


// Fragment Shader pour l'effet EX Holographique animé
fragment float4 fragmentShader_HolographicEX(VertexOut in [[stage_in]],
                                           constant float &time [[buffer(0)]],
                                           constant float2 &touchUV [[buffer(1)]]) {
    
    float2 uv = in.texCoords;

    // --- Couche 1: Dégradé Arc-en-ciel Amélioré (Base) ---
    // (Identique à la version précédente)
    float rainbowSpeed = 0.5;
    float freq_r1 = 2.5, freq_r2 = 3.5;
    float freq_g1 = 3.0, freq_g2 = 4.0;
    float freq_b1 = 3.5, freq_b2 = 2.5;
    float phase_r = time * rainbowSpeed;
    float phase_g = time * rainbowSpeed * 0.9 + 0.5;
    float phase_b = time * rainbowSpeed * 1.1 + 1.0;
    float r_wave = 0.5 + 0.25 * sin(uv.x * freq_r1 + uv.y * freq_r2 * 0.8 + phase_r) +
                   0.25 * sin(uv.x * freq_r2 * 1.2 - uv.y * freq_r1 + phase_r * 1.5);
    float g_wave = 0.5 + 0.25 * sin(uv.x * freq_g1 * 0.9 + uv.y * freq_g2 + phase_g) +
                   0.25 * sin(uv.x * freq_g2 - uv.y * freq_g1 * 1.1 + phase_g * 1.3);
    float b_wave = 0.5 + 0.25 * sin(uv.x * freq_b1 + uv.y * freq_b2 * 1.1 + phase_b) +
                   0.25 * sin(uv.x * freq_b2 * 0.8 - uv.y * freq_b1 * 0.9 + phase_b * 1.7);
    float3 baseGradientColor = saturate(float3(r_wave, g_wave, b_wave));

    // --- Couche 2: Bruit ---
    // (Identique à la version précédente)
    float noiseScalePrimary = 15.0;
    float noiseIntensityPrimary = 0.2;
    float noiseAnimationSpeed = 0.2;
    float2 noise_uv1 = uv + float2(time * noiseAnimationSpeed, time * noiseAnimationSpeed * 0.7);
    float noiseVal1 = simpleNoise(noise_uv1, noiseScalePrimary);
    float3 noisyBaseColor = baseGradientColor * (1.0 - noiseIntensityPrimary + noiseVal1 * noiseIntensityPrimary * 1.5);
    noisyBaseColor = saturate(noisyBaseColor);


    // --- Couche 3: Motif Holographique (Lignes Diagonales Animées - PLUS FINES) ---
    float patternSpeed = 0.3; // Peut-être un peu plus lent pour des lignes fines
    float lineDensity = 45.0;  // **AUGMENTER** pour plus de lignes (donc plus fines individuellement si l'épaisseur reste petite)
    float lineThickness = 0.008; // **RÉDUIRE** pour des lignes plus fines
    float patternIntensity = 0.20; // **RÉDUIRE LÉGÈREMENT** l'intensité si les lignes sont plus nombreuses/fines
    
    float diagValue = uv.x * 0.707 + uv.y * 0.707;
    float wave = sin(diagValue * lineDensity + time * patternSpeed);
    // Pour des lignes plus fines, la transition du smoothstep doit être plus abrupte
    // Si lineThickness est très petit, la différence entre les deux bornes du smoothstep doit être faible.
    // float linePattern = smoothstep(0.5 - lineThickness, 0.5, wave) - smoothstep(0.5, 0.5 + lineThickness, wave); // Ancien
    // Pour des lignes très fines avec smoothstep, on peut faire:
    float halfThickness = lineThickness / 2.0;
    float linePattern = smoothstep(0.5 - halfThickness, 0.5 - halfThickness + 0.001, wave) - // Montée rapide
                        smoothstep(0.5 + halfThickness - 0.001, 0.5 + halfThickness, wave);   // Descente rapide
    // Encore plus simple et souvent efficace pour des lignes fines à partir d'une onde :
    // On veut une valeur proche de 1 quand `wave` est proche de 0.5 (par exemple)
    // float linePattern = 1.0 - smoothstep(0.0, lineThickness, abs(wave - 0.5)); // Crée des lignes autour de wave = 0.5
    // Ou pour plusieurs lignes fines à partir de sin:
    // Le sin va de -1 à 1. On veut des pics.
    // L'ancien `smoothstep(0.5 - lineThickness, 0.5, wave) - smoothstep(0.5, 0.5 + lineThickness, wave)`
    // crée des bandes lorsque `wave` est proche de 0.5. Si `wave` est normalisé (0-1), c'est bon.
    // Notre `wave = sin(...)` va de -1 à 1.
    // Pour des lignes fines, on peut prendre les pics du sin:
    // linePattern = smoothstep(1.0 - lineThickness, 1.0, abs(wave)); // Lignes aux crêtes de la valeur absolue de la vague sin
    // Si on veut des lignes plus espacées, on peut utiliser fract() sur une valeur qui augmente
    // float lineProgression = fract((uv.x + uv.y + time * patternSpeed) * lineDensity);
    // linePattern = smoothstep(0.0, lineThickness, lineProgression) - smoothstep(1.0 - lineThickness, 1.0, lineProgression); // crée des lignes fines aux bords
    // Gardons la méthode précédente (wave autour de 0.5), mais assurons-nous que `wave` est dans un range adapté.
    // Si sin(X) est utilisé, il est entre -1 et 1. Normalisons-le à 0-1:
    float normalizedWave = 0.5 + 0.5 * wave; // Maintenant entre 0 et 1
    linePattern = smoothstep(0.5 - lineThickness, 0.5, normalizedWave) - smoothstep(0.5, 0.5 + lineThickness, normalizedWave);


    float3 patternColorEffect = float3(0.5) + (float3(linePattern) - 0.5) * patternIntensity;


    // --- Couche 4: Reflet Spéculaire Dynamique (MOINS PUISSANT) ---
    float specularIntensity = 0.45; // **RÉDUIRE** (était 0.8)
    float specularRadius = 0.35;    // Peut-être légèrement augmenter le rayon pour compenser la baisse d'intensité
    float specularFalloff = 0.3;   // Ajuster pour que la transition soit douce
    
    float distToTouch = distance(uv, touchUV);
    float reflectionAmount = smoothstep(specularRadius, specularRadius - specularFalloff, distToTouch);
    float3 specularColor = float3(1.0, 1.0, 1.0) * reflectionAmount * specularIntensity;


    // --- Combinaison des Couches ---
    float3 baseWithPattern = blendOverlay(noisyBaseColor, patternColorEffect);
    float3 finalCombinedColor = saturate(baseWithPattern + specularColor);

    // Scanline (toujours désactivé)
    // float scanline = 0.0;
    // finalCombinedColor = saturate(finalCombinedColor + float3(scanline));

    return float4(finalCombinedColor, 1.0);
}

