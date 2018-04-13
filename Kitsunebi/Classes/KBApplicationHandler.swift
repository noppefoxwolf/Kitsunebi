//
//  KBApplicationHandler.swift
//  Kitsunebi
//
//  Created by Tomoya Hirano on 2018/04/13.
//

import UIKit

final class KBApplicationHandler {
  var isActive: Bool = true
  private var didBecomeActiveToken: NSObjectProtocol? = nil
  private var didEnterBackgroundToken: NSObjectProtocol? = nil
  
  init() {
    addObserver()
  }
  
  deinit {
    removeObserver()
  }
  
  private func addObserver() {
    let center = NotificationCenter.default
    didBecomeActiveToken = center.addObserver(forName: .UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { [weak self] (_) in
      self?.isActive = true
    }
    didEnterBackgroundToken = center.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main) { [weak self] (_) in
      self?.isActive = false
    }
  }
  
  private func removeObserver() {
    let center = NotificationCenter.default
    if let token = didBecomeActiveToken {
      center.removeObserver(token)
      didBecomeActiveToken = nil
    }
    if let token = didEnterBackgroundToken {
      center.removeObserver(token)
      didEnterBackgroundToken = nil
    }
  }
}
