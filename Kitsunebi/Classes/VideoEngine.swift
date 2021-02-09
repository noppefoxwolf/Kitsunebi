//
//  VideoEngine.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import AVFoundation
import CoreImage

internal protocol VideoEngineUpdateDelegate: class {
  func didOutputFrame(_ basePixelBuffer: [CVPixelBuffer])
  func didReceiveError(_ error: Swift.Error?)
  func didCompleted()
}

internal protocol VideoEngineDelegate: class {
  func didUpdateFrame(_ index: Int, engine: VideoEngine)
  func engineDidFinishPlaying(_ engine: VideoEngine)
}

internal class VideoEngine: NSObject {
  private let assets: [Asset]
  private let fpsKeeper: FPSKeeper
  private lazy var displayLink: CADisplayLink = .init(target: WeakProxy(target: self), selector: #selector(VideoEngine.update))
  internal weak var delegate: VideoEngineDelegate? = nil
  internal weak var updateDelegate: VideoEngineUpdateDelegate? = nil
  private var isRunningTheread = true
  private lazy var renderThread: Thread = .init(target: WeakProxy(target: self), selector: #selector(VideoEngine.threadLoop), object: nil)
  private lazy var currentFrameIndex: Int = 0
  
  public init(base baseVideoURL: URL, alpha alphaVideoURL: URL, fps: Int) {
    let baseAsset = Asset(url: baseVideoURL)
    let alphaAsset = Asset(url: alphaVideoURL)
    assets = [baseAsset, alphaAsset]
    fpsKeeper = FPSKeeper(fps: fps)
    super.init()
    renderThread.start()
    
  }
  
  @available(iOS 13.0, *)
  public init(hevcWithAlpha hevcWithAlphaVideoURL: URL, fps: Int) {
    let hevcWithAlphaAsset = Asset(url: hevcWithAlphaVideoURL)
    assets = [hevcWithAlphaAsset]
    fpsKeeper = FPSKeeper(fps: fps)
    super.init()
    renderThread.start()
  }

  @objc private func threadLoop() -> Void {
    displayLink.add(to: .current, forMode: .common)
    displayLink.isPaused = true
    if #available(iOS 10.0, *) {
      displayLink.preferredFramesPerSecond = 0
    } else {
      displayLink.frameInterval = 1
    }
    while isRunningTheread {
      RunLoop.current.run(until: Date(timeIntervalSinceNow: 1/60))
    }
  }
  
  func purge() {
    isRunningTheread = false
  }
  
  deinit {
    displayLink.remove(from: .current, forMode: .common)
    displayLink.invalidate()
  }
  
  private func reset() throws {
    for asset in assets {
      try asset.reset()
    }
  }
  
  private func cancelReading() {
    for asset in assets {
      asset.cancelReading()
    }
  }
  
  public func play() throws {
    try reset()
    displayLink.isPaused = false
  }
  
  public func pause() {
    guard !isCompleted else { return }
    displayLink.isPaused = true
  }
  
  public func resume() {
    guard !isCompleted else { return }
    displayLink.isPaused = false
  }
  
  private func finish() {
    displayLink.isPaused = true
    fpsKeeper.clear()
    updateDelegate?.didCompleted()
    delegate?.engineDidFinishPlaying(self)
    purge()
  }
  
  @objc private func update(_ link: CADisplayLink) {
    guard fpsKeeper.checkPast1Frame(link) else { return }
    
    #if DEBUG
      FPSDebugger.shared.update(link)
    #endif
    
    autoreleasepool(invoking: { [weak self] in
      self?.updateFrame()
    })
  }
  
  private var isCompleted: Bool {
    for asset in assets {
      if asset.status == .completed {
        return true
      }
    }
    return false
  }
  
  private func updateFrame() {
    guard !displayLink.isPaused else { return }
    if isCompleted {
      finish()
      return
    }
    do {
      let pixelBuffers = try copyNextSampleBuffers()
      updateDelegate?.didOutputFrame(pixelBuffers)
      
      currentFrameIndex += 1
      delegate?.didUpdateFrame(currentFrameIndex, engine: self)
    } catch (let error) {
      updateDelegate?.didReceiveError(error)
      finish()
    }
  }
  
  private func copyNextSampleBuffers() throws -> [CVImageBuffer] {
    var pixelBuffers: [CVImageBuffer] = []
    for asset in assets {
      let pixelBuffer = try asset.copyNextImageBuffer()
      pixelBuffers.append(pixelBuffer)
    }
    return pixelBuffers
  }
}


