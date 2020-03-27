//
//  KBAnimationView.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import UIKit
import QuartzCore.CAMetalLayer
import MetalKit

public protocol KBAnimationViewDelegate: class {
  func didUpdateFrame(_ index: Int, animationView: KBAnimationView)
  func animationViewDidFinish(_ animationView: KBAnimationView)
}

open class KBAnimationView: UIView, KBVideoEngineUpdateDelegate, KBVideoEngineDelegate {
  private let device: MTLDevice
  private let metalLib: MTLLibrary
  private let commandQueue: MTLCommandQueue
  private let textureCache: CVMetalTextureCache
  lazy var vertexBuffer: MTLBuffer = { device.makeVertexBuffer() }()
  lazy var texCoordBuffer: MTLBuffer = { device.makeTexureCoordBuffer() }()
  lazy var pipelineState: MTLRenderPipelineState = { device.makeRenderPipelineState(metalLib: metalLib) }()
  
  private var threadsafeSize: CGSize = .zero
  private var applicationHandler = KBApplicationHandler()
  
  public weak var delegate: KBAnimationViewDelegate? = nil
  internal var engineInstance: KBVideoEngine? = nil
  
  public func play(mainVideoURL: URL, alphaVideoURL: URL, fps: Int) throws {
    engineInstance?.purge()
    engineInstance = KBVideoEngine(mainVideoUrl: mainVideoURL,
                                   alphaVideoUrl: alphaVideoURL,
                                   fps: fps)
    engineInstance?.updateDelegate = self
    engineInstance?.delegate = self
    try engineInstance?.play()
  }
  
  override open class var layerClass: Swift.AnyClass { CAMetalLayer.self }
  private var gpuLayer: CAMetalLayer { self.layer as! CAMetalLayer }
  
  public init?(frame: CGRect, device: MTLDevice) {
    guard let commandQueue = device.makeCommandQueue() else { return nil }
    guard let textureCache = try? device.makeTextureCache() else { return nil }
    guard let metalLib = try? device.makeDefaultLibrary(bundle: Bundle.main) else { return nil }
    self.device = device
    self.commandQueue = commandQueue
    self.textureCache = textureCache
    self.metalLib = metalLib
    super.init(frame: frame)
    applicationHandler.delegate = self
    guard prepare(device: device) else { return nil }
  }
  
  required public init?(coder aDecoder: NSCoder) {
    guard let device = MTLCreateSystemDefaultDevice() else { return nil }
    guard let commandQueue = device.makeCommandQueue() else { return nil }
    guard let textureCache = try? device.makeTextureCache() else { return nil }
    guard let metalLib = try? device.makeDefaultLibrary(bundle: Bundle.main) else { return nil }
    self.device = device
    self.commandQueue = commandQueue
    self.textureCache = textureCache
    self.metalLib = metalLib
    super.init(coder: aDecoder)
    applicationHandler.delegate = self
    guard prepare(device: device) else { return nil }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  private func prepare(device: MTLDevice) -> Bool {
    backgroundColor = .clear
    gpuLayer.isOpaque = false
    gpuLayer.pixelFormat = .bgra8Unorm
    gpuLayer.framebufferOnly = false
    gpuLayer.presentsWithTransaction = false
    gpuLayer.drawsAsynchronously = true
    return true
  }
  
  override open func layoutSubviews() {
    super.layoutSubviews()
    threadsafeSize = bounds.size
  }
  
  func didOutputFrame(_ basePixelBuffer: CVPixelBuffer, alphaPixelBuffer: CVPixelBuffer) -> Bool {
    drawImage(with: basePixelBuffer, alphaPixelBuffer: alphaPixelBuffer)
  }
  
  func didReceiveError(_ error: Swift.Error?) {
    clear()
  }
  
  func didCompleted() {
    clear()
  }
  
  private func clear() {
//    glClearColor(0, 0, 0, 0)
//    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
//    glBindRenderbuffer(GLenum(GL_RENDERBUFFER), viewRenderbuffer)
//    glContext.presentRenderbuffer(Int(GL_RENDERBUFFER))
  }
  
  @discardableResult
  private func drawImage(with basePixelBuffer: CVPixelBuffer, alphaPixelBuffer: CVPixelBuffer) -> Bool {
    guard applicationHandler.isActive else { return false }
    guard let nextDrawable = gpuLayer.nextDrawable() else { return false }
    
    /*
    let width = CVPixelBufferGetWidth(basePixelBuffer)
    let height = CVPixelBufferGetHeight(basePixelBuffer)
    let extent = CGRect(x: 0, y: 0, width: width, height: height)
    let edge = fillEdge(from: extent)
    */
    
    do {
      let baseTexture = try textureCache.makeTextureFromImage(basePixelBuffer).texture
      let alphaTexture = try textureCache.makeTextureFromImage(alphaPixelBuffer).texture
      
      let commandBuffer = commandQueue.makeCommandBuffer()!
      
      let renderDesc = MTLRenderPassDescriptor()
      renderDesc.colorAttachments[0].texture = nextDrawable.texture
      renderDesc.colorAttachments[0].loadAction = .clear
      
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDesc)!
      renderEncoder.setRenderPipelineState(pipelineState)
      renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      renderEncoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
      renderEncoder.setFragmentTexture(baseTexture, index: 0)
      renderEncoder.setFragmentTexture(alphaTexture, index: 1)
      renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
      renderEncoder.endEncoding()
      
      commandBuffer.present(nextDrawable)
      commandBuffer.commit()
    } catch {
      
    }
    textureCache.flush()
    return true
  }

  private func fillEdge(from extent: CGRect) -> UIEdgeInsets {
    let imageRatio = extent.width / extent.height
    let viewRatio = threadsafeSize.width / threadsafeSize.height
    if viewRatio < imageRatio { // viewの方が細長い //横がはみ出るパターン //iPhoneX
      let imageWidth = threadsafeSize.height * imageRatio
      // 0.0 ~ 1.0
      let overWidthRatio = ((imageWidth / threadsafeSize.width) - 1.0)
      // -1.0 ~ 1.0 本来左にoverWidthRatio/2分ズラすが、範囲が2倍なのでその2倍でoverWidthRatio分ズラしている
      return UIEdgeInsets(top: 0, left: overWidthRatio, bottom: 0, right: overWidthRatio)
    } else if viewRatio > imageRatio { //iPadとか
      let viewWidth = extent.height * viewRatio
      let overHeightRatio = ((viewWidth / extent.width) - 1.0)
      return UIEdgeInsets(top: overHeightRatio, left: 0, bottom: overHeightRatio, right: 0)
    } else {
      return UIEdgeInsets.zero
    }
  }
  
  internal func didUpdateFrame(_ index: Int, engine: KBVideoEngine) {
    delegate?.didUpdateFrame(index, animationView: self)
  }
  
  internal func engineDidFinishPlaying(_ engine: KBVideoEngine) {
    delegate?.animationViewDidFinish(self)
  }
}

extension KBAnimationView: KBApplicationHandlerDelegate {
  func didBecomeActive(_ notification: Notification) {
    engineInstance?.resume()
  }
  func willResignActive(_ notification: Notification) {
    engineInstance?.pause()
  }
}

extension CVMetalTextureCache {
  func flush(options: CVOptionFlags = 0) {
    CVMetalTextureCacheFlush(self, options)
  }
  
  func makeTextureFromImage(_ buffer: CVImageBuffer) throws -> CVMetalTexture {
    let size = CVImageBufferGetEncodedSize(buffer)
    
    var imageTexture: CVMetalTexture?
    let result = CVMetalTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault,
      self,
      buffer,
      nil,
      .bgra8Unorm,
      Int(size.width),
      Int(size.height),
      0,
      &imageTexture
    )
    if let imageTexture = imageTexture {
      return imageTexture
    } else {
      throw CVMetalError.cvReturn(result)
    }
  }
}

enum CVMetalError: Swift.Error {
  case cvReturn(CVReturn)
}

extension CVMetalTexture {
  var texture: MTLTexture? { CVMetalTextureGetTexture(self) }
}

extension MTLDevice {
  internal func makeTextureCache() throws -> CVMetalTextureCache {
    var textureCache: CVMetalTextureCache?
    let result = CVMetalTextureCacheCreate(
      kCFAllocatorDefault,
      nil,
      self,
      nil,
      &textureCache
    )
    if let textureCache = textureCache {
      return textureCache
    } else {
      throw CVMetalError.cvReturn(result)
    }
  }
  
  internal func makeTexureCoordBuffer() -> MTLBuffer {
    let texCoordinateData: [Float] = [
      0, 1,
      1, 1,
      0, 0,
      1, 0
    ]
    let texCoordinateDataSize = MemoryLayout<Float>.size * texCoordinateData.count
    return makeBuffer(bytes: texCoordinateData, length: texCoordinateDataSize)!
  }
  
  internal func makeVertexBuffer(edge: UIEdgeInsets = .zero) -> MTLBuffer {
    let vertexData: [Float] = [
      -1.0 - Float(edge.left), -1.0 - Float(edge.bottom), 0, 1,
      1.0 + Float(edge.right), -1.0 - Float(edge.bottom), 0, 1,
      -1.0 - Float(edge.left),  1.0 + Float(edge.top), 0, 1,
      1.0 + Float(edge.right),  1.0 + Float(edge.top), 0, 1,
    ]
    let size = vertexData.count * MemoryLayout<Float>.size
    return makeBuffer(bytes: vertexData, length: size)!
  }
  
  internal func makeRenderPipelineState(metalLib: MTLLibrary,
                                        pixelFormat: MTLPixelFormat = .bgra8Unorm,
                                        vertexFunctionName: String = "vertexShader",
                                        fragmentFunctionName: String = "fragmentShader") -> MTLRenderPipelineState {
    let pipelineDesc = MTLRenderPipelineDescriptor()
    pipelineDesc.vertexFunction = metalLib.makeFunction(name: vertexFunctionName)
    pipelineDesc.fragmentFunction = metalLib.makeFunction(name: fragmentFunctionName)
    pipelineDesc.colorAttachments[0].pixelFormat = pixelFormat
    
    return try! makeRenderPipelineState(descriptor: pipelineDesc)
  }
}
