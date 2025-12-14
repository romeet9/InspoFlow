#include <metal_stdlib>
using namespace metal;

// The original GLSL code ported to Metal
//
// for(int j = 0; j < 3; j++){
//   for(int i=0; i < 5; i++){
//     color[j] += lineWidth*float(i*i) / abs(fract(t - 0.01*float(j)+float(i)*0.01)*5.0 - length(uv) + mod(uv.x+uv.y, 0.2));
//   }
// }

[[ stitchable ]] half4 warpSpeed(float2 position, half4 color, float2 size, float time) {
    // Normalize position to -1.0 to 1.0 (uv)
    // GLSL: (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y)
    // Metal position is in pixels (0..width, 0..height)
    
    float2 uv = (position * 2.0 - size) / min(size.x, size.y);
    
    float t = time * 0.05;
    float lineWidth = 0.002;
    
    float3 finalColor = float3(0.0);
    
    for (int j = 0; j < 3; j++) {
        for (int i = 0; i < 5; i++) {
            float dist = abs(fract(t - 0.01 * float(j) + float(i) * 0.01) * 5.0 - length(uv) + fmod(uv.x + uv.y, 0.2));
            finalColor[j] += lineWidth * float(i * i) / dist;
        }
    }
    
    return half4(half(finalColor.r), half(finalColor.g), half(finalColor.b), 1.0);
}
