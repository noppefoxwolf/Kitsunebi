//
//  VideoEngine.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import AVFoundation
import CoreImage

internal protocol VideoEngineUpdateDelegate: class {
  func didOutputFrame(_ basePixelBuffer: CVPixelBuffer, alphaPixelBuffer: CVPixelBuffer)
  func didReceiveError(_ error: Swift.Error?)
  func didCompleted()
}

internal protocol VideoEngineDelegate: class {
  func didUpdateFrame(_ index: Int, engine: VideoEngine)
  func engineDidFinishPlaying(_ engine: VideoEngine)
}

internal class VideoEngine: NSObject {
  private let mainAsset: Asset
  private let alphaAsset: Asset
  private let fpsKeeper: FPSKeeper
  private lazy var displayLink: CADisplayLink = .init(target: WeakProxy(target: self), selector: #selector(VideoEngine.update))
  internal weak var delegate: VideoEngineDelegate? = nil
  internal weak var updateDelegate: VideoEngineUpdateDelegate? = nil
  private var isRunningTheread = true
  private lazy var renderThread: Thread = .init(target: WeakProxy(target: self), selector: #selector(VideoEngine.threadLoop), object: nil)
  private lazy var currentFrameIndex: Int = 0
  
  public init(mainVideoUrl: URL, alphaVideoUrl: URL, fps: Int) {
    mainAsset = Asset(url: mainVideoUrl)
    alphaAsset = Asset(url: alphaVideoUrl)
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
    try mainAsset.reset()
    try alphaAsset.reset()
  }
  
  private func cancelReading() {
    mainAsset.cancelReading()
    alphaAsset.cancelReading()
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
    return mainAsset.status == .completed || alphaAsset.status == .completed
  }
  
  private func updateFrame() {
    guard !displayLink.isPaused else { return }
    if isCompleted {
      finish()
      return
    }
    do {
      let (basePixelBuffer, alphaPixelBuffer) = try copyNextSampleBuffer()
      updateDelegate?.didOutputFrame(basePixelBuffer, alphaPixelBuffer: alphaPixelBuffer)
      
      currentFrameIndex += 1
      delegate?.didUpdateFrame(currentFrameIndex, engine: self)
    } catch (let error) {
      updateDelegate?.didReceiveError(error)
      finish()
    }
  }
  
  private func copyNextSampleBuffer() throws -> (CVImageBuffer, CVImageBuffer) {
    let main = try mainAsset.copyNextImageBuffer()
    //let alpha = try alphaAsset.copyNextImageBuffer()
    return (main, main)
  }
}


