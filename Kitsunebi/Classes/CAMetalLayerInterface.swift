//
//  CAMetalLayerInterface.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2020/04/02.
//

import Metal
import QuartzCore.CAMetalLayer

public protocol CAMetalLayerInterface: class {
  var pixelFormat: MTLPixelFormat { get set }
  var framebufferOnly: Bool { get set }
  var presentsWithTransaction: Bool { get set }
  var drawableSize: CGSize { get set }
  func nextDrawable() -> CAMetalDrawable?
}

#if targetEnvironment(simulator)
@available(iOS 13, *)
extension CAMetalLayer: CAMetalLayerInterface {}
#else
@available(iOS 12, *)
extension CAMetalLayer: CAMetalLayerInterface {}
#endif
