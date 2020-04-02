//
//  CVMetalTextureCache+.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2020/04/02.
//

import CoreVideo

extension CVMetalTextureCache {
  func flush(options: CVOptionFlags = 0) {
    CVMetalTextureCacheFlush(self, options)
  }
  
  func makeTextureFromImage(_ buffer: CVImageBuffer) throws -> CVMetalTexture {
    let size = CVImageBufferGetEncodedSize(buffer)
    var imageTexture: CVMetalTexture?
    let result = CVMetalTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault,
      self,
      buffer,
      nil,
      .bgra8Unorm,
      Int(size.width),
      Int(size.height),
      0,
      &imageTexture
    )
    if let imageTexture = imageTexture {
      return imageTexture
    } else {
      throw CVMetalError.cvReturn(result)
    }
  }
}
