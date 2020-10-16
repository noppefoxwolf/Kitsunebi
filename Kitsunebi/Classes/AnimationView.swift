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
      return UnsupportedLayer.self
    }
    #else
    return CAMetalLayer.self
    #endif
  }
  private var gpuLayer: LayerClass { self.layer as! LayerClass }
  private let renderQueue: DispatchQueue = .global(qos: .userInitiated)
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
    let baseYTexture = try textureCache.makeTextureFromImage(basePixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0).texture
    let baseCbCrTexture = try textureCache.makeTextureFromImage(basePixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1).texture
    let alphaYTexture = try textureCache.makeTextureFromImage(alphaPixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0).texture
    
    let renderDesc = MTLRenderPassDescriptor()
    renderDesc.colorAttachments[0].texture = nextDrawable.texture
    renderDesc.colorAttachments[0].loadAction = .clear
    
    if let commandBuffer = commandQueue.makeCommandBuffer(), let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDesc) {
      renderEncoder.setRenderPipelineState(pipelineState)
      renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      renderEncoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
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
    DispatchQueue.main.async { [weak self] in
      /// `gpuLayer` must access within main-thread.
      guard let nextDrawable = self?.gpuLayer.nextDrawable() else { return }
      self?.renderQueue.async { [weak self] in
        self?.clear(nextDrawable: nextDrawable)
      }
    }
  }
  
  private func clear(nextDrawable: CAMetalDrawable) {
    renderQueue.async { [weak self] in
      let renderPassDescriptor = MTLRenderPassDescriptor()
      renderPassDescriptor.colorAttachments[0].texture = nextDrawable.texture
      renderPassDescriptor.colorAttachments[0].loadAction = .clear
      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
      
      let commandBuffer = self?.commandQueue.makeCommandBuffer()
      let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
      renderEncoder?.endEncoding()
      commandBuffer?.present(nextDrawable)
      commandBuffer?.commit()
      self?.textureCache.flush()
    }
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
          self?.clear(nextDrawable: nextDrawable)
        }
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

