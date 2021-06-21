//
//  CVPixelBuffer+.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2020/04/02.
//

import CoreVideo

extension CVPixelBuffer {
  var width: Int { CVPixelBufferGetWidth(self) }
  var height: Int { CVPixelBufferGetHeight(self) }
  
  var size: CGSize { CGSize(width: width, height: height) }
}
