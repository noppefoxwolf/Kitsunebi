//
//  Frame.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2021/02/09.
//

import CoreGraphics
import CoreVideo

enum Frame {
  case yCbCrWithA(yCbCr: CVImageBuffer, a: CVImageBuffer)
  case yCbCrA(yCbCrA: CVImageBuffer)

  var size: CGSize {
    switch self {
    case let .yCbCrWithA(yCbCr, _):
      return yCbCr.size
    case let .yCbCrA(yCbCrA):
      return yCbCrA.size
    }
  }
}
