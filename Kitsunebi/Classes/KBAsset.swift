//
//  KBAsset.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import AVFoundation

final class KBAsset {
  private let outputSettings: [String : Any] = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
  let asset: AVURLAsset
  lazy var reader: AVAssetReader = { preconditionFailure() }()
  lazy var output: AVAssetReaderTrackOutput = { preconditionFailure() }()
  var status: AVAssetReaderStatus { return reader.status }
  var isRunning: Bool { return reader.status != .completed && reader.status != .cancelled }
  
  init(url: URL) {
    asset = AVURLAsset(url: url)
  }
  
  func reset() throws {
    reader = try AVAssetReader(asset: asset)
    output = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: AVMediaType.video)[0], outputSettings: outputSettings)
    if reader.canAdd(output) {
      reader.add(output)
    } else {
      throw NSError(.cannotAddOutput)
    }
    output.alwaysCopiesSampleData = false
    reader.startReading()
  }
  
  func cancelReading() {
    reader.cancelReading()
  }
  
  func fetchNextCIImage() throws -> CIImage {
    if let error = reader.error {
      throw error
    }
    if status != .reading {
      throw NSError(domain: "KBAssetErrorDomain", code: 0, userInfo: ["message" : "reader not reading"])
    }
    if let image = output.copyNextCIImage() {
      return image
    } else {
      throw NSError(domain: "KBAssetErrorDomain", code: 0, userInfo: ["message" : "reader not return image"])
    }
  }
}

extension AVAssetReaderTrackOutput {
  internal func copyNextCIImage() -> CIImage? {
    guard let sampleBuffer = copyNextSampleBuffer() else { return nil }
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    let image = CIImage(cvImageBuffer: pixelBuffer)
    CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    return image
  }
}
