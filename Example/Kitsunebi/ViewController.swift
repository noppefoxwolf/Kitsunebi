//
//  ViewController.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 04/13/2018.
//  Copyright (c) 2018 Tomoya Hirano. All rights reserved.
//

import UIKit
import Kitsunebi

final class ViewController: UIViewController, KBAnimationViewDelegate {
  private lazy var playerView: KBAnimationView = KBAnimationView(frame: view.bounds)!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    playerView.delegate = self
    view.addSubview(playerView)
    view.backgroundColor = UIColor.white
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    playerView.play(mainVideoURL: Bundle.main.url(forResource: "main", withExtension: "mp4")!,
                    alphaVideoURL: Bundle.main.url(forResource: "alpha", withExtension: "mp4")!,
                    fps: 30)
    print("start")
  }
  
  func animationViewDidFinish(_ animationView: KBAnimationView) {
    print("finish")
  }
}

