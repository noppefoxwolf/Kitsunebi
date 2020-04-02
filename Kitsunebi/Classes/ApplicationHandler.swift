//
//  ApplicationHandler.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import UIKit

protocol ApplicationHandlerDelegate: class {
  func willResignActive(_ notification: Notification)
  func didBecomeActive(_ notification: Notification)
}

final class ApplicationHandler {
  private(set) var isActive: Bool = true
  internal weak var delegate: ApplicationHandlerDelegate? = nil
  
  init() {
    let center = NotificationCenter.default
    center.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    center.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
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
