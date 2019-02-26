//
//  KUTableViewCell.swift
//  EmitterKit
//
//  Created by John Kotz on 2/25/19.
//

import Foundation
import UIKit
import FutureKit

public class KUTableViewCell: UITableViewCell, KUUpdatableView {
    public func updateUI(animated: Bool) -> Future<Bool> {
        preconditionFailure("This method must be overridden")
    }
}
