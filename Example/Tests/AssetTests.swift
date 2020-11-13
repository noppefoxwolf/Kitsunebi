//
//  AssetTests.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2020/11/13.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

@testable import Kitsunebi
import XCTest

class AssetTests: XCTestCase {
  func testNotFatalBeforeReset() {
    let asset = Asset(url: URL(fileURLWithPath: ""))
    _ = asset.status
    XCTAssert(true, "Pass")
  }
}

