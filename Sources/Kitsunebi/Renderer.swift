//
//  Renderer.swift
//  
//
//  Created by Huiping Guo on 2022/01/27.
//

import Foundation
import MetalKit


protocol Renderer {
  
  func getPipelineState() -> MTLRenderPipelineState
}

class SuperRenderer: Renderer {
  func getPipelineState() -> MTLRenderPipelineState {
    fatalError("sub class")
  }
  
  private let renderQueue: DispatchQueue = .global(qos: .userInitiated)

  private let commandQueue: MTLCommandQueue
  let textureCache: CVMetalTextureCache
  let device: MTLDevice
  private var gpuLayer: CAMetalLayerInterface & CALayer
  
  init?(gpuLayer: CAMetalLayerInterface & CALayer, device: MTLDevice?) {
    self.gpuLayer = gpuLayer
    guard let device = device else { return nil }
    guard let commandQueue = device.makeCommandQueue() else { return nil }
    guard let textureCache = try? device.makeTextureCache() else { return nil }
    
    self.device = device
    self.commandQueue = commandQueue
    self.textureCache = textureCache
  }
  
  func render(textureBlock: @escaping (() throws -> (baseYTexture: MTLTexture?, baseCbCrTexture: MTLTexture?, alphaYTexture: MTLTexture?)?), size: CGSize) {
    DispatchQueue.main.async { [weak self] in
      /// `gpuLayer` must access within main-thread.
      guard let nextDrawable = self?.gpuLayer.nextDrawable() else { return }
      self?.gpuLayer.drawableSize = size
      self?.renderQueue.async { [weak self] in
        do {
          let group = try textureBlock()
          try self?.renderImage(baseYTexture: group?.baseYTexture, baseCbCrTexture: group?.baseCbCrTexture, alphaYTexture: group?.alphaYTexture, to: nextDrawable)
        } catch {
          self?.clear(nextDrawable: nextDrawable)
        }
      }
    }
  }
  
  private func renderImage(baseYTexture: MTLTexture?, baseCbCrTexture: MTLTexture?, alphaYTexture: MTLTexture?, to nextDrawable: CAMetalDrawable) throws {
    let pipelineState: MTLRenderPipelineState = getPipelineState()
      
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
  

  func clear() {
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
      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
        red: 0, green: 0, blue: 0, alpha: 0)

      let commandBuffer = self?.commandQueue.makeCommandBuffer()
      let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
      renderEncoder?.endEncoding()
      commandBuffer?.present(nextDrawable)
      commandBuffer?.commit()
      self?.textureCache.flush()
    }
  }

}
