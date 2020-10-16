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

fragment float4 fragmentShader(ColorInOut in [[ stage_in ]],
                              texture2d<float> baseYTexture [[ texture(0) ]],
                              texture2d<float> alphaYTexture [[ texture(1) ]],
                              texture2d<float> baseCbCrTexture [[ texture(2) ]]) {
  constexpr sampler colorSampler;
  const float4x4 ycbcrToRGBTransform = float4x4(
      float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
      float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
      float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
      float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
  );
  
  float4 baseColor = ycbcrToRGBTransform * float4(baseYTexture.sample(colorSampler, in.texCoords).r,
                                                baseCbCrTexture.sample(colorSampler, in.texCoords).rg,
                                                1.0);
  
  float4 alphaColor = alphaYTexture.sample(colorSampler, in.texCoords).r;
  
  return float4(baseColor.r, baseColor.g, baseColor.b, alphaColor.r);
}


