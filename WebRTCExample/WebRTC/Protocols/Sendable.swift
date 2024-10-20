//
//  Sendable.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation

/// In our protocol architecture,
/// the purpose of sending notifications from the viewModel to the viewController on the main thread is to ensure thread safety.
public protocol ActionSendable {
  associatedtype ActionType
  var observer: Callback<ActionType>! { get set }
  func sendAction(_ action: ActionType)
}

public extension ActionSendable where Self: AnyObject {
    func sendAction(_ action: ActionType) {
        if #available(iOS 13, *) {
            Task {
                async let _ = await MainActor.run {
                    observer(action)
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.observer(action)
            }
        }
    }
}

/// This protocol was designed so that the viewController doesn't have visibility into all sendable properties.
public protocol ObserveManageable {
  associatedtype ActionType
  /// This method called on viewController for binding viewModel <-> viewController
  var observer: Callback<ActionType>! { get set }
}
