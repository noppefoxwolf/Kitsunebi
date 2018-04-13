//
//  ViewController.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 04/13/2018.
//  Copyright (c) 2018 Tomoya Hirano. All rights reserved.
//

import UIKit
import Kitsunebi

final class ViewController: UIViewController {
  private lazy var playerView: KBAnimationView = KBAnimationView(frame: view.bounds)!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(playerView)
    view.backgroundColor = UIColor.green
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    playerView.play(mainVideoURL: Bundle.main.url(forResource: "gift", withExtension: "mp4")!,
                    alphaVideoURL: Bundle.main.url(forResource: "alpha", withExtension: "mp4")!,
                    fps: 30)
  }
}

