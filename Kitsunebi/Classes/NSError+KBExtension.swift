//
//  NSError+KBExtension.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import UIKit

extension NSError {
  internal static let KBErrorDoamin = "com.noppelabs.kitsunebi.error"
  
  enum KBErrorKind: Int {
    case unknown
    case cannotAddOutput
    
    var localizedDescription: String {
      return ""
    }
  }
  
  convenience init(_ kind: KBErrorKind) {
    self.init(domain: NSError.KBErrorDoamin, code: kind.rawValue, userInfo: [NSLocalizedDescriptionKey : kind.localizedDescription])
  }
}
