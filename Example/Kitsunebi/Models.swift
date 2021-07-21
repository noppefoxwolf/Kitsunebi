//
//  Models.swift
//  Kitsunebi_Example
//
//  Created by Tomoya Hirano on 2018/09/06.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

final class ResourceStore {
  private(set) var resources: [Resource] = []
  
  func fetch() throws {
    let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let url = URL(fileURLWithPath: documentPath)
    let directories = try FileManager.default.directoriesOfDirectory(at: url)
    resources = directories.compactMap(Resource.init)
  }
}

enum Resource {
  case twin(TwinResource)
  case hevc(HevcResource)
  
  var name: String {
    switch self {
    case let .hevc(resource):
      return resource.name
    case let .twin(resource):
      return resource.name
    }
  }
  
  init?(url: URL) {
    let hevcResource = HevcResource(dirURL: url)
    if hevcResource.hevcWithAlphaVideoSize != nil {
      self = .hevc(hevcResource)
      return
    }
    
    let twinResource = TwinResource(dirURL: url)
    if twinResource.baseVideoSize != nil {
      self = .twin(twinResource)
      return
    }
    
    return nil
  }
}

struct TwinResource {
  let dirURL: URL
  let fps: Int = 30
  var name: String { dirURL.lastPathComponent }
  var baseVideoURL: URL { dirURL.appendingPathComponent("/base.mp4") }
  var alphaVideoURL: URL { dirURL.appendingPathComponent("/alpha.mp4") }
  
  var baseVideoSize: CGSize? {
    guard let track = AVAsset(url: baseVideoURL).tracks(withMediaType: .video).first else { return nil }
    let size = track.naturalSize.applying(track.preferredTransform)
    return CGSize(width: abs(size.width), height: abs(size.height))
  }
  
  var alphaVideoSize: CGSize? {
    guard let track = AVAsset(url: alphaVideoURL).tracks(withMediaType: .video).first else { return nil }
    let size = track.naturalSize.applying(track.preferredTransform)
    return CGSize(width: abs(size.width), height: abs(size.height))
  }
}

struct HevcResource {
  let dirURL: URL
  let fps: Int = 30
  var name: String { dirURL.lastPathComponent }
  var hevcWithAlphaVideoURL: URL { dirURL.appendingPathComponent("/hevc.mov") }
  
  var hevcWithAlphaVideoSize: CGSize? {
    guard let track = AVAsset(url: hevcWithAlphaVideoURL).tracks(withMediaType: .video).first else { return nil }
    let size = track.naturalSize.applying(track.preferredTransform)
    return CGSize(width: abs(size.width), height: abs(size.height))
  }
}

extension FileManager {
  func directoriesOfDirectory(at url: URL) throws -> [URL] {
    let contents = try contentsOfDirectory(at: url,
                                           includingPropertiesForKeys: [.isDirectoryKey],
                                           options: FileManager.DirectoryEnumerationOptions(rawValue: 0))
    return try contents.filter({ (try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false })
  }
}
