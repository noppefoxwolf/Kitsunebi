//
//  CVMetalTexture+.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2020/04/02.
//

import CoreVideo.CVMetalTexture

extension CVMetalTexture {
  var texture: MTLTexture? { CVMetalTextureGetTexture(self) }
}
