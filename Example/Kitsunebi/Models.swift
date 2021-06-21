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
    let url = URL(fileURLWithPath: NSHomeDirectory() + "/Documents")
    let directories = try FileManager.default.directoriesOfDirectory(at: url)
    resources = directories.map(Resource.init)
  }
}

struct Resource {
  let dirURL: URL
  var name: String { return dirURL.lastPathComponent }
  var baseVideoURL: URL { return dirURL.appendingPathComponent("/base.mp4") }
  var alphaVideoURL: URL { return dirURL.appendingPathComponent("/alpha.mp4") }
  let fps: Int = 30

  var hevcWithAlphaVideoURL: URL { return dirURL.appendingPathComponent("/hevc.mov") }
}

extension Resource {
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

  var hevcWithAlphaVideoSize: CGSize? {
    guard let track = AVAsset(url: alphaVideoURL).tracks(withMediaType: .video).first else { return nil }
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
