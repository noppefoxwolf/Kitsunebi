//
//  File.swift
//  
//
//  Created by Huiping Guo on 2022/01/27.
//

import Foundation
import MetalKit

class MP4Renderer: SuperRenderer {
  private let pipelineState: MTLRenderPipelineState
    
  override func getPipelineState() -> MTLRenderPipelineState {
    pipelineState
  }
  
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
  
  func render(yCbCr: CVImageBuffer, alpha: CVImageBuffer, size: CGSize) throws {
    let a = { [weak self] () throws -> (baseYTexture: MTLTexture?, baseCbCrTexture: MTLTexture?, alphaYTexture: MTLTexture?)? in
      guard let self = self else { return nil }

    let baseYTexture: MTLTexture?
    let baseCbCrTexture: MTLTexture?
    let alphaYTexture: MTLTexture?
    
    let basePixelBuffer = yCbCr
    let alphaPixelBuffer = alpha
    let alphaPlaneIndex = 0
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
