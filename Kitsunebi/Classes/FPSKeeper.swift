//
//  FPSKeeper.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import UIKit

final class FPSKeeper {
  private var beforeTimeStamp: CFTimeInterval? = nil
  private let timeInterval: CFTimeInterval
  init(fps: Int) {
    self.timeInterval = 1.0 / CFTimeInterval(fps)
  }
  
  func clear() {
    beforeTimeStamp = nil
  }
  
  func checkPast1Frame(_ link: CADisplayLink) -> Bool {
    if let beforeTimeStamp = beforeTimeStamp {
      guard timeInterval <= link.timestamp - beforeTimeStamp else {
        return false
      }
    }
    beforeTimeStamp = link.timestamp
    return true
  }
}
