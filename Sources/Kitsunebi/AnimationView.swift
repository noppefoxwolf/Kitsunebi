//
//  PlayerView.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import MetalKit
import UIKit

public protocol PlayerViewDelegate: AnyObject {
  func playerView(_ playerView: PlayerView, didUpdateFrame index: Int)
  func didFinished(_ playerView: PlayerView)
}

open class PlayerView: UIView {
  typealias LayerClass = CAMetalLayerInterface & CALayer
  override open class var layerClass: Swift.AnyClass {
    return CAMetalLayer.self
  }
  private var gpuLayer: LayerClass { self.layer as! LayerClass }
 
  private var applicationHandler = ApplicationHandler()

  public weak var delegate: PlayerViewDelegate? = nil
  internal var engineInstance: VideoEngine? = nil
  private var render: RendererFacde!

  public func play(base baseVideoURL: URL, alpha alphaVideoURL: URL, fps: Int) throws {
    engineInstance?.purge()
    engineInstance = VideoEngine(base: baseVideoURL, alpha: alphaVideoURL, fps: fps)
    engineInstance?.updateDelegate = self
    engineInstance?.delegate = self
    try engineInstance?.play()
  }

  public func play(hevcWithAlpha hevcWithAlphaVideoURL: URL, fps: Int) throws {
    engineInstance?.purge()
    engineInstance = VideoEngine(hevcWithAlpha: hevcWithAlphaVideoURL, fps: fps)
    engineInstance?.updateDelegate = self
    engineInstance?.delegate = self
    try engineInstance?.play()
  }

  public init?(frame: CGRect, device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
    super.init(frame: frame)
    
    applicationHandler.delegate = self
    backgroundColor = .clear
    gpuLayer.isOpaque = false
    gpuLayer.drawsAsynchronously = true
    gpuLayer.contentsGravity = .resizeAspectFill
    gpuLayer.pixelFormat = .bgra8Unorm
    gpuLayer.framebufferOnly = false
    gpuLayer.presentsWithTransaction = false
    
    guard let render = RendererFacde(gpuLayer: gpuLayer, device: device) else {
      return nil
    }
    self.render = render
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    applicationHandler.delegate = self
    backgroundColor = .clear
    gpuLayer.isOpaque = false
    gpuLayer.drawsAsynchronously = true
    gpuLayer.contentsGravity = .resizeAspectFill
    gpuLayer.pixelFormat = .bgra8Unorm
    gpuLayer.framebufferOnly = false
    gpuLayer.presentsWithTransaction = false
    
    guard let render = RendererFacde(gpuLayer: gpuLayer, device: MTLCreateSystemDefaultDevice()) else {
      return nil
    }
    self.render = render
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}

extension PlayerView: VideoEngineUpdateDelegate {
  internal func didOutputFrame(_ frame: Frame) {
    guard applicationHandler.isActive else { return }
    render.render(frame: frame)
  }

  internal func didReceiveError(_ error: Swift.Error?) {
    guard applicationHandler.isActive else { return }
    render.clear()
  }

  internal func didCompleted() {
    guard applicationHandler.isActive else { return }
    render.clear()
  }
}

extension PlayerView: VideoEngineDelegate {
  internal func didUpdateFrame(_ index: Int, engine: VideoEngine) {
    delegate?.playerView(self, didUpdateFrame: index)
  }

  internal func engineDidFinishPlaying(_ engine: VideoEngine) {
    delegate?.didFinished(self)
  }
}

extension PlayerView: ApplicationHandlerDelegate {
  func didBecomeActive(_ notification: Notification) {
    engineInstance?.resume()
  }

  func willResignActive(_ notification: Notification) {
    engineInstance?.pause()
  }
}
