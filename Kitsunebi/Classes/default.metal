//
//  Kitsunebi.metal
//  Kitsunebi_Metal
//
//  Created by Tomoya Hirano on 2018/07/19.
//

#include <metal_stdlib>
using namespace metal;

struct ColorInOut {
  float4 position [[ position ]];
  float2 texCoords;
};

vertex ColorInOut vertexShader(const device float4 *position [[ buffer(0) ]],
                               const device float2 *texCoords [[ buffer(1) ]],
                               uint    vid      [[ vertex_id ]]) {
  ColorInOut out;
  out.position = position[vid];
  out.texCoords = texCoords[vid];
  return out;
}

fragment half4 fragmentShader(ColorInOut in [[ stage_in ]],
                              texture2d<half> baseTexture [[ texture(0) ]],
                              texture2d<half> alphaTexture [[ texture(1) ]]) {
  constexpr sampler colorSampler;
  half4 baseColor = baseTexture.sample(colorSampler, in.texCoords);
  half4 alphaColor = alphaTexture.sample(colorSampler, in.texCoords);
  return half4(baseColor.r, baseColor.g, baseColor.b, alphaColor.r);
}
