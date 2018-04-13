//
//  GLESHelper.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import UIKit

struct GLESHelper {
  internal static func linkProgram(_ prog: GLuint) -> Bool {
    var status: GLint = 0
    glLinkProgram(prog)
    glGetProgramiv(prog, GLenum(GL_LINK_STATUS), &status)
    return status != 0
  }
  
  internal static func compileShader(_ shader: UnsafeMutablePointer<GLuint>, type: GLenum, shaderString: String) -> Bool {
    var status: GLint = 0
    let shaderStringUTF8 = shaderString.cString(using: String.defaultCStringEncoding)
    var source = UnsafePointer<GLchar>(shaderStringUTF8)
    
    if source == nil {
      print("STGLPreview : failed to load vertex shader")
      return false
    }
    
    shader.pointee = glCreateShader(type)
    glShaderSource(shader.pointee, 1, &source, nil)
    glCompileShader(shader.pointee)
    glGetShaderiv(shader.pointee, GLenum(GL_COMPILE_STATUS), &status)
    if status == 0 {
      glDeleteShader(shader.pointee)
      return false
    }
    return true
  }
  
  internal static func setupOriginTexture(with pixelBuffer: CVPixelBuffer,
                                          texture: UnsafeMutablePointer<CVOpenGLESTexture?>,
                                          textureCahce: CVOpenGLESTextureCache,
                                          textureOriginInput: UnsafeMutablePointer<GLuint>,
                                          width: GLsizei,
                                          height: GLsizei) -> Bool {
    
    let cvRet = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                             textureCahce,
                                                             pixelBuffer,
                                                             nil,
                                                             GLenum(GL_TEXTURE_2D),
                                                             GL_RGBA,
                                                             width,
                                                             height,
                                                             GLenum(GL_BGRA),
                                                             GLenum(GL_UNSIGNED_BYTE),
                                                             0,
                                                             texture)
    if texture.pointee == nil || kCVReturnSuccess != cvRet {
      return false
    }
    
    textureOriginInput.pointee = CVOpenGLESTextureGetName(texture.pointee!)
    glBindTexture(GLenum(GL_TEXTURE_2D) , textureOriginInput.pointee)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
    glBindTexture(GLenum(GL_TEXTURE_2D), 0)
    
    return true
  }
}
