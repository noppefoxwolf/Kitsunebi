//
//  Bundle+.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2020/04/02.
//

import Foundation

extension Bundle {
  var defaultMetalLibraryURL: URL {
    url(forResource: "default", withExtension: "metallib")!
  }
}
