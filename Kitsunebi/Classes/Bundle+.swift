//
//  Bundle+.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2020/04/02.
//

private final class BundleToken {}

extension Bundle {
  static var current: Bundle {
    Bundle(for: BundleToken.self)
  }
  
  var defaultMetalLibraryURL: URL {
    url(forResource: "default", withExtension: "metallib")!
  }
}
