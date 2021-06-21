//
//  FPSDebugger.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import UIKit

class FPSDebugger {
  static let shared = FPSDebugger()
  
  private var prev: TimeInterval = 0.0
  
  internal func update(_ link: CADisplayLink) {
    debugPrint("\(Int(1.0 / (link.timestamp - prev)))fps")
    prev = link.timestamp
  }
}
