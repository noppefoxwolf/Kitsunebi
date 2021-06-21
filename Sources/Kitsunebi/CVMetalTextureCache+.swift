//
//  CVMetalTextureCache+.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2020/04/02.
//

import CoreMedia
import CoreVideo

extension CVMetalTextureCache {
  func flush(options: CVOptionFlags = 0) {
    CVMetalTextureCacheFlush(self, options)
  }

  func makeTextureFromImage(_ buffer: CVImageBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int)
    throws -> CVMetalTexture
  {
    let width = CVPixelBufferGetWidthOfPlane(buffer, planeIndex)
    let height = CVPixelBufferGetHeightOfPlane(buffer, planeIndex)
    var imageTexture: CVMetalTexture?
    let result = CVMetalTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault,
      self,
      buffer,
      nil,
      pixelFormat,
      width,
      height,
      planeIndex,
      &imageTexture
    )
    if let imageTexture = imageTexture {
      return imageTexture
    } else {
      throw CVMetalError.cvReturn(result)
    }
  }
}
