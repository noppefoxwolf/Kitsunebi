//
//  ViewController.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 04/13/2018.
//  Copyright (c) 2018 Tomoya Hirano. All rights reserved.
//

import UIKit
import AVFoundation
import Kitsunebi

final class PreviewViewController: UIViewController {
  private var currentResource: Resource? = nil
  private lazy var camera: AVCaptureDevice? = .default(for: .video)
  private lazy var cameraInput: AVCaptureDeviceInput? = try? .init(device: camera!)
  private lazy var cameraSession: AVCaptureSession = .init()
  private lazy var cameraLayer: AVCaptureVideoPreviewLayer = .init(session: cameraSession)
  @IBOutlet private weak var backgroundContentView: UIImageView!
  @IBOutlet private weak var playerView: Kitsunebi.PlayerView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if TARGET_OS_SIMULATOR == 0 {
      cameraSession.addInput(cameraInput!)
      cameraLayer.frame = view.bounds
      cameraLayer.videoGravity = .resizeAspectFill
      backgroundContentView.image = nil
      backgroundContentView.layer.insertSublayer(cameraLayer, at: 0)
      cameraSession.startRunning()
    }
    playerView.delegate = self
  }
  
  private func play() throws {
    guard let resource = currentResource else { return }
    if resource.hevcWithAlphaVideoSize != nil {
      try playerView.play(hevcWithAlpha: resource.hevcWithAlphaVideoURL, fps: resource.fps)
      return;
    }
    try playerView.play(base: resource.baseVideoURL, alpha: resource.alphaVideoURL, fps: resource.fps)
  }
  
  @IBAction func tappedResourceButton(_ sender: Any) {
    let vc = ResourceViewController.make(selected: currentResource)
    vc.delegate = self
    let nc =  UINavigationController(rootViewController: vc)
    present(nc, animated: true, completion: nil)
  }
}

extension PreviewViewController: PlayerViewDelegate {
  func playerView(_ playerView: PlayerView, didUpdateFrame index: Int) {
    print("INDEX : ", index)
  }
  
  func didFinished(_ playerView: PlayerView) {
    do {
      try play()
    } catch {
      debugPrint(error)
    }
  }
}

extension PreviewViewController: ResourceViewControllerDelegate {
  func resource(_ viewController: ResourceViewController,
                didSelected resource: Resource) {
    currentResource = resource
    viewController.dismiss(animated: true, completion: { [weak self] in
      do {
        try self?.play()
      } catch {
        debugPrint(error)
      }
    })
  }
}

