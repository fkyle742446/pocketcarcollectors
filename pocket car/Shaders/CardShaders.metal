
#include <metal_stdlib>
using namespace metal;

// Structure pour les données des sommets
struct VertexIn {
    float3 position [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
};

// Vertex Shader: passe les positions et coordonnées de texture
vertex VertexOut vertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 1.0);
    out.texCoords = in.texCoords;
    return out;
}

// Fragment Shader de base pour l'effet EX Holographique
// Pour l'instant, il retourne une couleur arc-en-ciel simple basée sur les coordonnées de texture
// pour vérifier que tout fonctionne.
fragment float4 fragmentShader_HolographicEX(VertexOut in [[stage_in]]
                                          /* , constant float &time [[buffer(0)]] -- Exemple d'uniform */) {
    
    // Simple animation de couleur pour test
    float r = 0.5 * (1.0 + sin(in.texCoords.x * 5.0 /* + time */ ));
    float g = 0.5 * (1.0 + sin(in.texCoords.y * 5.0 /* + time * 0.5 */));
    float b = 0.5 * (1.0 + cos((in.texCoords.x + in.texCoords.y) * 5.0 /* + time * 0.2 */));
    
    return float4(r, g, b, 1.0); // R, G, B, Alpha
}
