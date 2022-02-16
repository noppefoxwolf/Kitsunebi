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
  // self.layer main thread使う必要あるので、事前に持つことでmain thread以外のthreadでも使えるように
  private lazy var gpuLayer: LayerClass = { fatalError("gpuLayer must be init") }()
  private let renderQueue: DispatchQueue = DispatchQueue(label: "dev.noppe.kitsunebi.PlayerView.renderQueue", qos: .userInitiated)
  private let commandQueue: MTLCommandQueue
  private let textureCache: CVMetalTextureCache
  private let mp4VideoRangePipelineState: MTLRenderPipelineState
  private let hevcVideoRangePipelineState: MTLRenderPipelineState
  private var applicationHandler = ApplicationHandler()

  public weak var delegate: PlayerViewDelegate? = nil
  internal var engineInstance: VideoEngine? = nil

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
    guard let device = device else { return nil }
    guard let commandQueue = device.makeCommandQueue() else { return nil }
    guard let textureCache = try? device.makeTextureCache() else { return nil }
    guard let metalLib = try? device.makeLibrary(URL: Bundle.module.defaultMetalLibraryURL) else {
      return nil
    }
    guard let mp4VideoRangePipelineState = try? device.makeRenderPipelineState(metalLib: metalLib, fragmentFunctionName: "mp4VideoRangeFragmentShader") else {
      return nil
    }
    guard let hevcVideoRangePipelineState = try? device.makeRenderPipelineState(metalLib: metalLib, fragmentFunctionName: "hevcVideoRangeFragmentShader") else {
      return nil
    }
    self.commandQueue = commandQueue
    self.textureCache = textureCache
    self.mp4VideoRangePipelineState = mp4VideoRangePipelineState
    self.hevcVideoRangePipelineState = hevcVideoRangePipelineState
    super.init(frame: frame)
    applicationHandler.delegate = self
    backgroundColor = .clear
    
    gpuLayer = self.layer as! LayerClass
    gpuLayer.isOpaque = false
    gpuLayer.drawsAsynchronously = true
    gpuLayer.contentsGravity = .resizeAspectFill
    gpuLayer.pixelFormat = .bgra8Unorm
    gpuLayer.framebufferOnly = false
    gpuLayer.presentsWithTransaction = false
  }

  required public init?(coder aDecoder: NSCoder) {
    guard let device = MTLCreateSystemDefaultDevice() else { return nil }
    guard let commandQueue = device.makeCommandQueue() else { return nil }
    guard let textureCache = try? device.makeTextureCache() else { return nil }
    guard let metalLib = try? device.makeLibrary(URL: Bundle.module.defaultMetalLibraryURL) else {
      return nil
    }
    guard let mp4VideoRangePipelineState = try? device.makeRenderPipelineState(metalLib: metalLib, fragmentFunctionName: "mp4VideoRangeFragmentShader") else {
      return nil
    }
    guard let hevcVideoRangePipelineState = try? device.makeRenderPipelineState(metalLib: metalLib, fragmentFunctionName: "hevcVideoRangeFragmentShader") else {
      return nil
    }
    self.commandQueue = commandQueue
    self.textureCache = textureCache
    self.mp4VideoRangePipelineState = mp4VideoRangePipelineState
    self.hevcVideoRangePipelineState = hevcVideoRangePipelineState
    super.init(coder: aDecoder)
    applicationHandler.delegate = self
    backgroundColor = .clear
    
    gpuLayer = self.layer as! LayerClass
    gpuLayer.isOpaque = false
    gpuLayer.drawsAsynchronously = true
    gpuLayer.contentsGravity = .resizeAspectFill
    gpuLayer.pixelFormat = .bgra8Unorm
    gpuLayer.framebufferOnly = false
    gpuLayer.presentsWithTransaction = false
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private func renderImage(with frame: Frame, to nextDrawable: CAMetalDrawable) throws {
    dispatchPrecondition(condition: .onQueue(renderQueue))

    let (baseYTexture, baseCbCrTexture, alphaYTexture) = try makeTexturesFrom(frame)
    
    let pipelineState: MTLRenderPipelineState

    switch frame {
    case .yCbCrWithA(_, _):
      pipelineState = mp4VideoRangePipelineState
    case .yCbCrA(_):
      pipelineState = hevcVideoRangePipelineState
    }
      
    let renderDesc = MTLRenderPassDescriptor()
    renderDesc.colorAttachments[0].texture = nextDrawable.texture
    renderDesc.colorAttachments[0].loadAction = .clear

    if let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDesc)
    {
      renderEncoder.setRenderPipelineState(pipelineState)
      renderEncoder.setFragmentTexture(baseYTexture, index: 0)
      renderEncoder.setFragmentTexture(alphaYTexture, index: 1)
      renderEncoder.setFragmentTexture(baseCbCrTexture, index: 2)
      renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
      renderEncoder.endEncoding()

      commandBuffer.present(nextDrawable)
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
    }

    textureCache.flush()
  }

  private func clear() {
    renderQueue.async { [weak self] in
      guard let nextDrawable = self?.gpuLayer.nextDrawable() else { return }
      self?.clear(nextDrawable: nextDrawable)
    }
  }

  private func clear(nextDrawable: CAMetalDrawable) {
    // render queueで実行する必要がある
    dispatchPrecondition(condition: .onQueue(renderQueue))
    
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = nextDrawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
      red: 0, green: 0, blue: 0, alpha: 0)
    
    let commandBuffer = commandQueue.makeCommandBuffer()
    let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    renderEncoder?.endEncoding()
    commandBuffer?.present(nextDrawable)
    commandBuffer?.commit()
    textureCache.flush()
  }

  private func makeTexturesFrom(_ frame: Frame) throws -> (
    y: MTLTexture?, cbcr: MTLTexture?, a: MTLTexture?
  ) {
    let baseYTexture: MTLTexture?
    let baseCbCrTexture: MTLTexture?
    let alphaYTexture: MTLTexture?

    switch frame {
    case let .yCbCrWithA(yCbCr, a):
      let basePixelBuffer = yCbCr
      let alphaPixelBuffer = a
      let alphaPlaneIndex = 0
      baseYTexture = try textureCache.makeTextureFromImage(
        basePixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0
      ).texture
      baseCbCrTexture = try textureCache.makeTextureFromImage(
        basePixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1
      ).texture
      alphaYTexture = try textureCache.makeTextureFromImage(
        alphaPixelBuffer, pixelFormat: .r8Unorm, planeIndex: alphaPlaneIndex
      ).texture

    case let .yCbCrA(yCbCrA):
      let basePixelBuffer = yCbCrA
      let alphaPixelBuffer = yCbCrA
      let alphaPlaneIndex = 2
      baseYTexture = try textureCache.makeTextureFromImage(
        basePixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0
      ).texture
      baseCbCrTexture = try textureCache.makeTextureFromImage(
        basePixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1
      ).texture
      alphaYTexture = try textureCache.makeTextureFromImage(
        alphaPixelBuffer, pixelFormat: .r8Unorm, planeIndex: alphaPlaneIndex
      ).texture
    }

    return (baseYTexture, baseCbCrTexture, alphaYTexture)
  }
}

extension PlayerView: VideoEngineUpdateDelegate {
  internal func didOutputFrame(_ frame: Frame) {
    renderQueue.async { [weak self] in
      guard let self = self, self.applicationHandler.isActive else { return }
      guard let nextDrawable = self.gpuLayer.nextDrawable() else { return }
      self.gpuLayer.drawableSize = frame.size
      do {
        try self.renderImage(with: frame, to: nextDrawable)
      } catch {
        self.clear(nextDrawable: nextDrawable)
      }
    }
  }

  internal func didReceiveError(_ error: Swift.Error?) {
    guard applicationHandler.isActive else { return }
    clear()
  }

  internal func didCompleted() {
    guard applicationHandler.isActive else { return }
    clear()
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
