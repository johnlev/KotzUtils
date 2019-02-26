//
//  KUTableViewDiffCell.swift
//  EmitterKit
//
//  Created by John Kotz on 2/25/19.
//

import Foundation
import UIKit
import FutureKit

public class KUTableViewDiffCell<T>: KUTableViewCell {
    public func updateUI(animated: Bool, with item: T?) -> Future<Bool> {
        preconditionFailure("This method must be overridden")
    }
    
    public override func updateUI(animated: Bool) -> Future<Bool> {
        return self.updateUI(animated: true, with: nil)
    }
}
