//
//  PlayerView.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import UIKit
import MetalKit

public protocol PlayerViewDelegate: class {
  func playerView(_ playerView: PlayerView, didUpdateFrame index: Int)
  func didFinished(_ playerView: PlayerView)
}

open class PlayerView: UIView {
  typealias LayerClass = CAMetalLayerInterface & CALayer
  override open class var layerClass: Swift.AnyClass {
    #if targetEnvironment(simulator)
    if #available(iOS 13, *) {
      return CAMetalLayer.self
    } else {
      preconditionFailure("Kitsunebi not support simurator older than iOS12.")
    }
    #else
    return CAMetalLayer.self
    #endif
  }
  private var gpuLayer: LayerClass { self.layer as! LayerClass }
  private let renderQueue: DispatchQueue = .global()
  private let commandQueue: MTLCommandQueue
  private let textureCache: CVMetalTextureCache
  private let vertexBuffer: MTLBuffer
  private let texCoordBuffer: MTLBuffer
  private let pipelineState: MTLRenderPipelineState
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
  
  public init?(frame: CGRect, device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
    guard let device = MTLCreateSystemDefaultDevice() else { return nil }
    guard let commandQueue = device.makeCommandQueue() else { return nil }
    guard let textureCache = try? device.makeTextureCache() else { return nil }
    guard let metalLib = try? device.makeLibrary(URL: Bundle.current.defaultMetalLibraryURL) else { return nil }
    guard let pipelineState = try? device.makeRenderPipelineState(metalLib: metalLib) else { return nil }
    self.commandQueue = commandQueue
    self.textureCache = textureCache
    self.vertexBuffer = device.makeVertexBuffer()
    self.texCoordBuffer = device.makeTexureCoordBuffer()
    self.pipelineState = pipelineState
    super.init(frame: frame)
    applicationHandler.delegate = self
    backgroundColor = .clear
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
    guard let metalLib = try? device.makeLibrary(URL: Bundle.current.defaultMetalLibraryURL) else { return nil }
    guard let pipelineState = try? device.makeRenderPipelineState(metalLib: metalLib) else { return nil }
    self.commandQueue = commandQueue
    self.textureCache = textureCache
    self.vertexBuffer = device.makeVertexBuffer()
    self.texCoordBuffer = device.makeTexureCoordBuffer()
    self.pipelineState = pipelineState
    super.init(coder: aDecoder)
    applicationHandler.delegate = self
    backgroundColor = .clear
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
  
  private func renderImage(with basePixelBuffer: CVPixelBuffer, alphaPixelBuffer: CVPixelBuffer, to nextDrawable: CAMetalDrawable) throws {
    let baseTexture = try textureCache.makeTextureFromImage(basePixelBuffer).texture
    let alphaTexture = try textureCache.makeTextureFromImage(alphaPixelBuffer).texture
    
    
    let renderDesc = MTLRenderPassDescriptor()
    renderDesc.colorAttachments[0].texture = nextDrawable.texture
    renderDesc.colorAttachments[0].loadAction = .clear
    
    if let commandBuffer = commandQueue.makeCommandBuffer(), let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDesc) {
      renderEncoder.setRenderPipelineState(pipelineState)
      renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      renderEncoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
      renderEncoder.setFragmentTexture(baseTexture, index: 0)
      renderEncoder.setFragmentTexture(alphaTexture, index: 1)
      renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
      renderEncoder.endEncoding()
      
      commandBuffer.present(nextDrawable)
      commandBuffer.commit()
    }
    
    textureCache.flush()
  }
  
  private func clear() {
    let renderDesc = MTLRenderPassDescriptor()
    renderDesc.colorAttachments[0].loadAction = .clear
    renderDesc.renderTargetWidth = 1
    renderDesc.renderTargetHeight = 1
    renderDesc.defaultRasterSampleCount = 1
    let commandBuffer = commandQueue.makeCommandBuffer()
    let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderDesc)
    renderEncoder?.endEncoding()
    commandBuffer?.commit()
    textureCache.flush()
  }
}

extension PlayerView: VideoEngineUpdateDelegate {
  internal func didOutputFrame(_ basePixelBuffer: CVPixelBuffer, alphaPixelBuffer: CVPixelBuffer) {
    guard applicationHandler.isActive else { return }
    DispatchQueue.main.async { [weak self] in
      /// `gpuLayer` must access within main-thread.
      guard let nextDrawable = self?.gpuLayer.nextDrawable() else { return }
      self?.gpuLayer.drawableSize = basePixelBuffer.size
      self?.renderQueue.async { [weak self] in
        do {
          try self?.renderImage(with: basePixelBuffer, alphaPixelBuffer: alphaPixelBuffer, to: nextDrawable)
        } catch {
          self?.clear()
        }
      }
    }
  }
  
  internal func didReceiveError(_ error: Swift.Error?) {
    guard applicationHandler.isActive else { return }
    renderQueue.async { [weak self] in
      self?.clear()
    }
  }
  
  internal func didCompleted() {
    guard applicationHandler.isActive else { return }
    renderQueue.async { [weak self] in
      self?.clear()
    }
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

