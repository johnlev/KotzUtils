//
//  KUUpdatableView.swift
//  EmitterKit
//
//  Created by John Kotz on 2/25/19.
//

import Foundation
import FutureKit

public protocol KUUpdatableView {
    /**
     Update the UI
     */
    func updateUI(animated: Bool) -> Future<Bool>
}
