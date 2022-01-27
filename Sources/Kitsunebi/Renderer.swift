//
//  Renderer.swift
//  
//
//  Created by Huiping Guo on 2022/01/27.
//

import Foundation
import MetalKit

internal class Renderer {
  
  private let mp4PipelineState: MTLRenderPipelineState
  private let hevcPipelineState: MTLRenderPipelineState
  private let renderQueue: DispatchQueue = .global(qos: .userInitiated)

  private let commandQueue: MTLCommandQueue
  private let textureCache: CVMetalTextureCache
 
  private var gpuLayer: CAMetalLayerInterface & CALayer
  
  init?(gpuLayer: CAMetalLayerInterface & CALayer, device: MTLDevice?) {
    self.gpuLayer = gpuLayer
    guard let device = device else { return nil }
    guard let commandQueue = device.makeCommandQueue() else { return nil }
    guard let textureCache = try? device.makeTextureCache() else { return nil }
    guard let metalLib = try? device.makeLibrary(URL: Bundle.module.defaultMetalLibraryURL) else {
      return nil
    }
    guard let mp4PipelineState = try? device.makeRenderPipelineState(metalLib: metalLib, fragmentFunctionName: "mp4FragmentShader") else {
      return nil
    }
    guard let hevcPipelineState = try? device.makeRenderPipelineState(metalLib: metalLib, fragmentFunctionName: "hevcFragmentShader") else {
      return nil
    }
    self.commandQueue = commandQueue
    self.textureCache = textureCache
    self.mp4PipelineState = mp4PipelineState
    self.hevcPipelineState = hevcPipelineState
  }
  
  
  func test(frame: Frame) {
    DispatchQueue.main.async { [weak self] in
      /// `gpuLayer` must access within main-thread.
      guard let nextDrawable = self?.gpuLayer.nextDrawable() else { return }
      self?.gpuLayer.drawableSize = frame.size
      self?.renderQueue.async { [weak self] in
        do {
          try self?.renderImage(with: frame, to: nextDrawable)
        } catch {
          self?.clear(nextDrawable: nextDrawable)
        }
      }
    }
  }
  
  private func renderImage(with frame: Frame, to nextDrawable: CAMetalDrawable) throws {
    let (baseYTexture, baseCbCrTexture, alphaYTexture) = try makeTexturesFrom(frame)
    
    let pipelineState: MTLRenderPipelineState

    switch frame {
    case .yCbCrWithA(_, _):
      pipelineState = mp4PipelineState
    case .yCbCrA(_):
      pipelineState = hevcPipelineState
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
