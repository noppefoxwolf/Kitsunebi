//
//  Asset.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import AVFoundation

final class Asset {
  private var outputSettings: [String: Any] {
    if let pixelFormatType = pixelFormatType {
      return [
        kCVPixelBufferPixelFormatTypeKey as String: pixelFormatType,
        kCVPixelBufferMetalCompatibilityKey as String: true
      ]
    }
    
    return [kCVPixelBufferMetalCompatibilityKey as String: true]
  }
  let asset: AVURLAsset
  private let pixelFormatType: OSType?
  private var reader: AVAssetReader? = nil
  private var output: AVAssetReaderTrackOutput? = nil
  var status: AVAssetReader.Status? { reader?.status }

  init(url: URL, pixelFormatType: OSType? = nil) {
    self.asset = AVURLAsset(url: url)
    self.pixelFormatType = pixelFormatType
  }

  func reset() throws {
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(
      track: asset.tracks(withMediaType: AVMediaType.video)[0], outputSettings: outputSettings)
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
    if let sampleBuffer = output?.copyNextSampleBuffer(),
      let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    {
      return imageBuffer
    } else {
      throw AssetError.readerNotReturnedImage
    }
  }
}
