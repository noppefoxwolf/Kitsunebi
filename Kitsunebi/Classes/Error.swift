//
//  Error.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import Foundation

public enum Error: Swift.Error {
  case unknown(String)
  case cannotAddOutput
}

internal enum AssetError: Swift.Error {
  case readerWasStopped
  case readerNotReturnedImage
}

internal enum RenderError: Swift.Error {
  case applicationBackground
  case failedToFetchNextDrawable
}

enum CVMetalError: Swift.Error {
  case cvReturn(CVReturn)
}
