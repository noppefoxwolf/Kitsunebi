//
//  Asset.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import AVFoundation

final class Asset {
  private let outputSettings: [String : Any] = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
  let asset: AVURLAsset
  lazy var reader: AVAssetReader = { preconditionFailure() }()
  lazy var output: AVAssetReaderTrackOutput = { preconditionFailure() }()
  var status: AVAssetReader.Status { return reader.status }
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
      throw Error.cannotAddOutput
    }
    output.alwaysCopiesSampleData = false
    reader.startReading()
  }
  
  func cancelReading() {
    reader.cancelReading()
  }
  
  func copyNextImageBuffer() throws -> CVImageBuffer {
    if let error = reader.error {
      throw error
    }
    if status != .reading {
      throw AssetError.readerWasStopped
    }
    if let sampleBuffer = output.copyNextSampleBuffer(), let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
      return imageBuffer
    } else {
      throw AssetError.readerNotReturnedImage
    }
  }
}
