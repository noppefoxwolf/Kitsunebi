//
//  UnsupportedLayer.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2020/05/26.
//

import QuartzCore

class UnsupportedLayer: CALayer, CAMetalLayerInterface {
  var pixelFormat: MTLPixelFormat = .a8Unorm
  var framebufferOnly: Bool = false
  var presentsWithTransaction: Bool = false
  var drawableSize: CGSize = .zero
  func nextDrawable() -> CAMetalDrawable? {
    return nil
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
}
