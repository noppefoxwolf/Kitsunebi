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
  
  override func setUp() {
    super.setUp()
    
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testExample() {
    let asset = Asset(url: URL(fileURLWithPath: ""))
    _ = asset.status
    XCTAssert(true, "Pass")
  }
}

