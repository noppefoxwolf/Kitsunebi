//
//  File.swift
//  
//
//  Created by Huiping Guo on 2022/01/27.
//

import Foundation
import MetalKit

internal class RendererFacde {
  
  private let mp4Renderer: MP4Renderer
  private let hevcRenderer: HEVCRenderer
  
  init?(gpuLayer: CAMetalLayerInterface & CALayer, device: MTLDevice?) {
    mp4Renderer = MP4Renderer(gpuLayer: gpuLayer, device: device)!
    hevcRenderer = HEVCRenderer(gpuLayer: gpuLayer, device: device)!
  }
  
  func render(frame: Frame) {
    switch frame {
    case let .yCbCrWithA(yCbCr, alpha):
      try? mp4Renderer.render(yCbCr: yCbCr, alpha: alpha, size: frame.size)
    case let .yCbCrA(yCbCrA):
      try? hevcRenderer.render(yCbCrA: yCbCrA, size: frame.size)
    }
  }
  
  func clear() {
    mp4Renderer.clear()
    hevcRenderer.clear()
  }
  
}
