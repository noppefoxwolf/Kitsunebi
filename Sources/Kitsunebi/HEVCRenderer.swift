//
//  File.swift
//  
//
//  Created by Huiping Guo on 2022/01/27.
//

import Foundation
import MetalKit

class HEVCRenderer: SuperRenderer {
  private let hevcPipelineState: MTLRenderPipelineState
  
  override func getPipelineState() -> MTLRenderPipelineState {
    hevcPipelineState
  }
  
  override init?(gpuLayer: CAMetalLayerInterface & CALayer, device: MTLDevice?) {
    guard let metalLib = try? device?.makeLibrary(URL: Bundle.module.defaultMetalLibraryURL) else {
      return nil
    }
    guard let hevcPipelineState = try? device?.makeRenderPipelineState(metalLib: metalLib, fragmentFunctionName: "hevcFragmentShader") else {
      return nil
    }
    
    self.hevcPipelineState = hevcPipelineState
    
    super.init(gpuLayer: gpuLayer, device: device)
  }
  
  func render(yCbCrA: CVImageBuffer, size: CGSize) throws {
    let a = { [weak self] () throws -> (baseYTexture: MTLTexture?, baseCbCrTexture: MTLTexture?, alphaYTexture: MTLTexture?)? in
      guard let self = self else { return nil }
      let baseYTexture: MTLTexture?
      let baseCbCrTexture: MTLTexture?
      let alphaYTexture: MTLTexture?
      
      
      let basePixelBuffer = yCbCrA
      let alphaPixelBuffer = yCbCrA
      let alphaPlaneIndex = 2
      baseYTexture = try self.textureCache.makeTextureFromImage(
        basePixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0
      ).texture
      baseCbCrTexture = try self.textureCache.makeTextureFromImage(
        basePixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1
      ).texture
      alphaYTexture = try self.textureCache.makeTextureFromImage(
        alphaPixelBuffer, pixelFormat: .r8Unorm, planeIndex: alphaPlaneIndex
      ).texture
      
      return (baseYTexture, baseCbCrTexture, alphaYTexture)
    }
    
    super.render(textureBlock: a, size: size)
  }
  
  

}
