
//
//  MTLDevice+.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2020/04/02.
//

import Metal
import CoreVideo

extension MTLDevice {
  internal func makeTextureCache() throws -> CVMetalTextureCache {
    var textureCache: CVMetalTextureCache?
    let result = CVMetalTextureCacheCreate(
      kCFAllocatorDefault,
      nil,
      self,
      nil,
      &textureCache
    )
    if let textureCache = textureCache {
      return textureCache
    } else {
      throw CVMetalError.cvReturn(result)
    }
  }
  
  internal func makeTexureCoordBuffer() -> MTLBuffer {
    let texCoordinateData: [Float] = [
      0, 1,
      1, 1,
      0, 0,
      1, 0
    ]
    let texCoordinateDataSize = MemoryLayout<Float>.size * texCoordinateData.count
    return makeBuffer(bytes: texCoordinateData, length: texCoordinateDataSize)!
  }
  
  internal func makeVertexBuffer() -> MTLBuffer {
    let vertexData: [Float] = [
      -1.0, -1.0, 0, 1,
      1.0, -1.0, 0, 1,
      -1.0, 1.0, 0, 1,
      1.0, 1.0, 0, 1,
    ]
    let size = vertexData.count * MemoryLayout<Float>.size
    return makeBuffer(bytes: vertexData, length: size)!
  }
  
  internal func makeRenderPipelineState(metalLib: MTLLibrary,
                                        pixelFormat: MTLPixelFormat = .bgra8Unorm,
                                        vertexFunctionName: String = "vertexShader",
                                        fragmentFunctionName: String = "fragmentShader") throws -> MTLRenderPipelineState {
    let pipelineDesc = MTLRenderPipelineDescriptor()
    pipelineDesc.vertexFunction = metalLib.makeFunction(name: vertexFunctionName)
    pipelineDesc.fragmentFunction = metalLib.makeFunction(name: fragmentFunctionName)
    pipelineDesc.colorAttachments[0].pixelFormat = pixelFormat
    
    return try makeRenderPipelineState(descriptor: pipelineDesc)
  }
}
