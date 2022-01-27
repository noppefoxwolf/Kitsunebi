//
//  File.swift
//  
//
//  Created by Huiping Guo on 2022/01/27.
//

import Foundation
import MetalKit

class MP4Renderer: SuperRenderer {
  let pipelineState: MTLRenderPipelineState
    
  override init?(gpuLayer: CAMetalLayerInterface & CALayer, device: MTLDevice?) {
    guard let metalLib = try? device?.makeLibrary(URL: Bundle.module.defaultMetalLibraryURL) else {
      return nil
    }
    guard let mp4PipelineState = try? device?.makeRenderPipelineState(metalLib: metalLib, fragmentFunctionName: "mp4FragmentShader") else {
      return nil
    }
    
    self.pipelineState = mp4PipelineState
    
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
      let basePixelBuffer = yCbCr
      let alphaPixelBuffer = a
      let alphaPlaneIndex = 0
      baseYTexture = try textureCache.makeTextureFromImage(
        basePixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0
      ).texture
      baseCbCrTexture = try textureCache.makeTextureFromImage(
        basePixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1
      ).texture
      alphaYTexture = try textureCache.makeTextureFromImage(
        alphaPixelBuffer, pixelFormat: .r8Unorm, planeIndex: alphaPlaneIndex
      ).texture

    case let .yCbCrA(yCbCrA):
     break
    }

    return (baseYTexture, baseCbCrTexture, alphaYTexture)
  }
}
