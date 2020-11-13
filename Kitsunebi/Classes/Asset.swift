//
//  Asset.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import AVFoundation

final class Asset {
  private let outputSettings: [String : Any] = [
    kCVPixelBufferMetalCompatibilityKey as String : true,
  ]
  let asset: AVURLAsset
  private var reader: AVAssetReader? = nil
  private var output: AVAssetReaderTrackOutput? = nil
  var status: AVAssetReader.Status? { reader?.status }
  
  init(url: URL) {
    asset = AVURLAsset(url: url)
  }
  
  func reset() throws {
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: AVMediaType.video)[0], outputSettings: outputSettings)
    if reader.canAdd(output) {
      reader.add(output)
    } else {
      throw Error.cannotAddOutput
    }
    output.alwaysCopiesSampleData = false
    reader.startReading()
    
    self.reader = reader
    self.output = output
  }
  
  func cancelReading() {
    reader?.cancelReading()
  }
  
  func copyNextImageBuffer() throws -> CVImageBuffer {
    if let error = reader?.error {
      throw error
    }
    if status != .reading {
      throw AssetError.readerWasStopped
    }
    if let sampleBuffer = output?.copyNextSampleBuffer(), let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
      return imageBuffer
    } else {
      throw AssetError.readerNotReturnedImage
    }
  }
}
