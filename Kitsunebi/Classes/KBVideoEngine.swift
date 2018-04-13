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

internal protocol KBVideoEngineDelegate: class {
  func engineDidFinishPlaying(_ engine: KBVideoEngine)
}

internal class KBVideoEngine: NSObject {
  private let mainAsset: KBAsset
  private let alphaAsset: KBAsset
  private let fpsKeeper: FPSKeeper
  private lazy var displayLink: CADisplayLink = .init(target: WeakProxy(target: self), selector: #selector(KBVideoEngine.update))
  internal weak var delegate: KBVideoEngineDelegate? = nil
  internal weak var updateDelegate: KBVideoEngineUpdateDelegate? = nil
  private var isRunningTheread = true
  private lazy var renderThread: Thread = .init(target: WeakProxy(target: self), selector: #selector(KBVideoEngine.threadLoop), object: nil)
  
  public init(mainVideoUrl: URL, alphaVideoUrl: URL, fps: Int) {
    mainAsset = KBAsset(url: mainVideoUrl)
    alphaAsset = KBAsset(url: alphaVideoUrl)
    fpsKeeper = FPSKeeper(fps: fps)
    super.init()
    renderThread.start()
  }
  
  @objc private func threadLoop() -> Void {
    print("thread loop done!")
    displayLink.add(to: .current, forMode: .commonModes)
    displayLink.isPaused = true
    displayLink.frameInterval = 0 //best effort
    while isRunningTheread {
      RunLoop.current.run(until: Date(timeIntervalSinceNow: 1/30))
    }
  }
  
  func purge() {
    isRunningTheread = false
  }
  
  deinit {
    displayLink.remove(from: .current, forMode: .commonModes)
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
    displayLink.isPaused = true
  }
  
  public func resume() {
    displayLink.isPaused = false
  }
  
  private func finish() {
    displayLink.isPaused = true
    fpsKeeper.clear()
    updateDelegate?.didCompleted()
    delegate?.engineDidFinishPlaying(self)
  }
  
  @objc private func update(_ link: CADisplayLink) {
    guard fpsKeeper.checkPast1Frame(link) else { return }
    FPSDebugger.shared.update(link)
    
    autoreleasepool(invoking: { [weak self] in
      self?.updateFrame()
    })
  }
  
  private func updateFrame() {
    guard !displayLink.isPaused else { return }
    if mainAsset.status == .completed || alphaAsset.status == .completed {
      finish()
      return
    }
    do {
      let (main, alpha) = try fetchNextCIImages()
      updateDelegate?.didOutputFrame(main, alphaImage: alpha)
    } catch (let error) {
      updateDelegate?.didReceiveError(error)
      finish()
    }
  }
  
  private func fetchNextCIImages() throws -> (CIImage, CIImage) {
    let main = try mainAsset.fetchNextCIImage()
    let alpha = try alphaAsset.fetchNextCIImage()
    return (main, alpha)
  }
}


