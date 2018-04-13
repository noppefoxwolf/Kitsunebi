//
//  KBVideoEngine.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import AVFoundation
import CoreImage

internal protocol KBVideoEngineUpdateDelegate: class {
  func didOutputFrame(_ image: CIImage, alphaImage: CIImage)
  func didReceiveError(_ error: Error?)
  func didCompleted()
}

public protocol KBVideoEngineDelegate: class {
  func engineDidFinishPlaying(_ engine: KBVideoEngine)
  func engineDidCancelPlaying(_ engine: KBVideoEngine)
}

public class KBVideoEngine: NSObject {
  private let outputSettings: [String : Any] = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
  private let mainAsset: AVURLAsset
  private let alphaAsset: AVURLAsset
  private var mainAssetReader: AVAssetReader!
  private var alphaAssetReader: AVAssetReader!
  private var mainOutput: AVAssetReaderTrackOutput!
  private var alphaOutput: AVAssetReaderTrackOutput!
  public weak var delegate: KBVideoEngineDelegate? = nil
  internal weak var updateDelegate: KBVideoEngineUpdateDelegate? = nil
  private var previousFrameTime = kCMTimeZero
  private var previousActualFrameTime = CFAbsoluteTimeGetCurrent()
  private lazy var displayLink: CADisplayLink = .init(target: WeakProxy(target: self), selector: #selector(KBVideoEngine.update))
  private var beforeTimeStamp: CFTimeInterval? = nil
  private let timeInterval: CFTimeInterval
  private let cache = CIImageCache()
  
  public init(mainVideoUrl: URL, alphaVideoUrl: URL, fps: Int) {
    mainAsset = AVURLAsset(url: mainVideoUrl)
    alphaAsset = AVURLAsset(url: alphaVideoUrl)
    timeInterval = 1.0 / CFTimeInterval(fps)
    super.init()
    
    let thread = Thread(target: self, selector: #selector(self.threadLoop), object: nil)
    thread.start()
  }
  
  @objc func threadLoop() -> Void {
    print("thread loop done!")
    self.displayLink.add(to: .current, forMode: .commonModes)
    self.displayLink.isPaused = true
    displayLink.frameInterval = 0 //best effort
    while true {
      RunLoop.current.run(until: Date(timeIntervalSinceNow: 1/30))
    }
  }
  
  deinit {
    displayLink.invalidate()
  }
  
  private func reset() throws {
    mainAssetReader = try AVAssetReader(asset: mainAsset)
    alphaAssetReader = try AVAssetReader(asset: alphaAsset)
    mainOutput = AVAssetReaderTrackOutput(track: mainAsset.tracks(withMediaType: AVMediaType.video)[0], outputSettings: outputSettings)
    alphaOutput = AVAssetReaderTrackOutput(track: alphaAsset.tracks(withMediaType: AVMediaType.video)[0], outputSettings: outputSettings)
    if mainAssetReader.canAdd(mainOutput) {
      mainAssetReader.add(mainOutput)
    } else {
      throw NSError(domain: "", code: 12000, userInfo: nil)
    }
    if alphaAssetReader.canAdd(alphaOutput) {
      alphaAssetReader.add(alphaOutput)
    } else {
      throw NSError(domain: "", code: 12000, userInfo: nil)
    }
    mainOutput.alwaysCopiesSampleData = false
    alphaOutput.alwaysCopiesSampleData = false
    mainAssetReader.startReading()
    alphaAssetReader.startReading()
  }
  
  private func cancelReading() {
    mainAssetReader.cancelReading()
    alphaAssetReader.cancelReading()
  }
  
  public func play() throws {
    try reset()
    displayLink.isPaused = false
  }
  
  public func pause() {
    displayLink.isPaused = true
  }
  
  public func resume() {
    displayLink.isPaused = false
  }
  
  public func cancel() {
    let running = mainAssetReader.status != .completed && mainAssetReader.status != .cancelled
    cancelReading()
    updateDelegate?.didReceiveError(nil)
    displayLink.isPaused = true
    if running {
      delegate?.engineDidCancelPlaying(self)
    }
  }
  
  private func finish() {
    beforeTimeStamp = nil
    updateDelegate?.didCompleted()
    displayLink.isPaused = true
    delegate?.engineDidFinishPlaying(self)
  }
  
  
  @objc private func update(_ link: CADisplayLink) {
    
    if let beforeTimeStamp = beforeTimeStamp {
      guard timeInterval <= link.timestamp - beforeTimeStamp else {
        return
      }
    }
    beforeTimeStamp = link.timestamp

    FPSDebugger.shared.update(link)
    
    autoreleasepool(invoking: { [weak self] in
      self?.updateFrame()
    })
  }
  
  private func updateFrame() {
    guard !displayLink.isPaused else { return }
    switch mainAssetReader.status {
    case .completed: finish(); return
    default: break
    }
    guard let (main, alpha) = fetchNextCIImages() else { return }
    updateDelegate?.didOutputFrame(main, alphaImage: alpha)
  }
  
  private func fetchNextCIImages() -> (CIImage, CIImage)? {
    if let error = mainAssetReader.error {
      updateDelegate?.didReceiveError(error)
      finish()
      return nil
    }
    guard mainAssetReader.status == .reading else { return nil }
    guard let main = mainOutput.fetchNextCIImage() else { return nil }
    
    if let error = alphaAssetReader.error {
      updateDelegate?.didReceiveError(error)
      finish()
      return nil
    }
    guard alphaAssetReader.status == .reading else { return nil }
    guard let alpha = alphaOutput.fetchNextCIImage() else { return nil }
    
    return (main, alpha)
  }
}

extension AVAssetReaderTrackOutput {
  func fetchNextCIImage() -> CIImage? {
    guard let sampleBuffer = copyNextSampleBuffer() else { return nil }
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    let image = CIImage(cvImageBuffer: pixelBuffer)
    CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    return image
  }
}

class CIImageCache {
  private var cache: [(CIImage, CIImage)] = []
  private let cacheLimit: Int = 3
  
  func fetch() -> (CIImage, CIImage)? {
    guard cache.count > 0 else { return nil }
    return cache.removeFirst()
  }
  
  func store(images: (CIImage, CIImage)) {
    cache.append(images)
  }
}
