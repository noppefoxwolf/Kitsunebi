//
//  File.swift
//  
//
//  Created by Huiping Guo on 2022/01/27.
//

import Foundation
import MetalKit

class HEVCRenderer: SuperRenderer {
  let hevcPipelineState: MTLRenderPipelineState
  
  override init?(gpuLayer: CAMetalLayerInterface & CALayer, device: MTLDevice?) {
    guard let metalLib = try? device?.makeLibrary(URL: Bundle.module.defaultMetalLibraryURL) else {
      return nil
    }
    guard let hevcPipelineState = try? device?.makeRenderPipelineState(metalLib: metalLib, fragmentFunctionName: "mp4FragmentShader") else {
      return nil
    }
    
    self.hevcPipelineState = hevcPipelineState
    
    super.init(gpuLayer: gpuLayer, device: device)
  }
  
  
  
  
  override func makeTexturesFrom(_ frame: Frame) throws -> (
    y: MTLTexture?, cbcr: MTLTexture?, a: MTLTexture?
  ) {
    let baseYTexture: MTLTexture?
    let baseCbCrTexture: MTLTexture?
    let alphaYTexture: MTLTexture?

    switch frame {
    case let .yCbCrWithA(yCbCr, a):
      break

    case let .yCbCrA(yCbCrA):
      let basePixelBuffer = yCbCrA
      let alphaPixelBuffer = yCbCrA
      let alphaPlaneIndex = 2
      baseYTexture = try textureCache.makeTextureFromImage(
        basePixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0
      ).texture
      baseCbCrTexture = try textureCache.makeTextureFromImage(
        basePixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1
      ).texture
      alphaYTexture = try textureCache.makeTextureFromImage(
        alphaPixelBuffer, pixelFormat: .r8Unorm, planeIndex: alphaPlaneIndex
      ).texture
    }

    return (baseYTexture, baseCbCrTexture, alphaYTexture)
  }

}
