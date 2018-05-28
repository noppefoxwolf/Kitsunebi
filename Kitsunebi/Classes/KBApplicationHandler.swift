//
//  KBApplicationHandler.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import UIKit

protocol KBApplicationHandlerDelegate: class {
  func willResignActive(_ notification: Notification)
  func didBecomeActive(_ notification: Notification)
}

final class KBApplicationHandler {
  private(set) var isActive: Bool = true
  internal weak var delegate: KBApplicationHandlerDelegate? = nil
  
  init() {
    let center = NotificationCenter.default
    center.addObserver(self, selector: #selector(willResignActive), name: .UIApplicationWillResignActive, object: nil)
    center.addObserver(self, selector: #selector(didBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
  }
  
  deinit {
    let center = NotificationCenter.default
    center.removeObserver(self)
  }
  
  @objc private func willResignActive(_ notification: Notification) {
    isActive = false
    delegate?.willResignActive(notification)
  }
  
  @objc private func didBecomeActive(_ notification: Notification) {
    isActive = true
    delegate?.didBecomeActive(notification)
  }
}
