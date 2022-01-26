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

vertex ColorInOut vertexShader(uint vid [[ vertex_id ]]) {
  const ColorInOut vertices[4] = {
    { float4(-1.0f, -1.0f, 0.0f, 1.0f), float2(0.0f, 1.0f) },
    { float4(1.0f, -1.0f, 0.0f, 1.0f), float2(1.0f, 1.0f) },
    { float4(-1.0f, 1.0f, 0.0f, 1.0f), float2(0.0f, 0.0f) },
    { float4(1.0f, 1.0f, 0.0f, 1.0f), float2(1.0f, 0.0f) },
  };
  return vertices[vid];
}

fragment float4 mp4VideoRangeFragmentShader(ColorInOut in [[ stage_in ]],
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
  float4 baseYUVColor = float4(baseYTexture.sample(colorSampler, in.texCoords).r,
                               baseCbCrTexture.sample(colorSampler, in.texCoords).rg,
                               1.0f);
  // yuv video range to full range
  baseYUVColor.r = (baseYUVColor.r - (16.0f/255.0f)) * (255.0f/(235.0f-16.0f));
  baseYUVColor.g = (baseYUVColor.g - (16.0f/255.0f)) * (255.0f/(240.0f-16.0f));
  baseYUVColor.b = (baseYUVColor.b - (16.0f/255.0f)) * (255.0f/(240.0f-16.0f));

  // yuv to rgb
  float4 baseColor = ycbcrToRGBTransform * baseYUVColor;


  // get alpha value
  float alphaColor = alphaYTexture.sample(colorSampler, in.texCoords).r;
  // video range to full range
  alphaColor = (alphaColor - (16.0f/255.0f)) * (255.0f/(235.0f-16.0f));

  return float4(baseColor.r, baseColor.g, baseColor.b, alphaColor);
}


fragment float4 hevcVideoRangeFragmentShader(ColorInOut in [[ stage_in ]],
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
  
  float4 baseYUVColor = float4(baseYTexture.sample(colorSampler, in.texCoords).r,
                                                  baseCbCrTexture.sample(colorSampler, in.texCoords).rg,
                                                  1.0f);
  
  // yuv video range to full range
  baseYUVColor.r = (baseYUVColor.r - (16.0f/255.0f)) * (255.0f/(235.0f-16.0f));
  baseYUVColor.g = (baseYUVColor.g - (16.0f/255.0f)) * (255.0f/(240.0f-16.0f));
  baseYUVColor.b = (baseYUVColor.b - (16.0f/255.0f)) * (255.0f/(240.0f-16.0f));
  
  // yuv to rgb
  float4 baseColor = ycbcrToRGBTransform * baseYUVColor;
  
  // kCVPixelFormatType_420YpCbCr8VideoRange_8A_TriPlanar
  // alphaはfull rangeのため、変更必要ない
  float alphaColor = alphaYTexture.sample(colorSampler, in.texCoords).r;

  return float4(baseColor.r, baseColor.g, baseColor.b, alphaColor);
}

