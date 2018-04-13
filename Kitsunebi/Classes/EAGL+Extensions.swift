//
//  EAGL+Extensions.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import UIKit

extension EAGLContext {
  func use() -> Bool {
    guard EAGLContext.current() != self else { return true }
    return EAGLContext.setCurrent(self)
  }
}

