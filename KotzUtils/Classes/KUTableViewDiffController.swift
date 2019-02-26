//
//  KUTableViewDiffController.swift
//  KotzUtils
//
//  Created by John Kotz on 2/25/19.
//
import Foundation
import UIKit
import FutureKit

/**
 A difference controller for table views. When new data is provided, will animate the table view between states
 
 Requirements:
 - Data backing the table view cells is of a single (Hashable) type
 - Takes over table view data source, so doesn't support table views with other data sources
 */
@available(iOS 11.0, *)
public class KUTableViewDiffController<T: TableViewDiffControllerData>: NSObject, UITableViewDataSource {
    /// The data as it is shown on the table view
    public private(set) var data: [[T]]
    /// The table view being controlled
    public private(set) var tableView: UITableView
    /// Delegate to this controller (required to provide cells for each T item in the data)
    public let delegate: TableViewDiffControllerDelegate
    
    /// The animation to be used when doing row opperations
    public var rowAnimation = UITableView.RowAnimation.automatic
    
    /// The currently active batch update promise
    private var activeUpdatePromise: Promise<Void>?
    /// The data (if any) waiting for the currently active update to be over so it can be used
    private var waitingData: [[T]]?
    /// The promise for the waiting update request
    private var waitingUpdatePromise: Promise<Void>?
    
    /**
     Initialize the difference controller
     
     - parameter tableView: The table view to control
     - parameter delegate: The delegate for this controller
     - parameter initialData: The data to start the table view out with
     */
    init(tableView: UITableView, delegate: TableViewDiffControllerDelegate, initialData: [[T]]? = nil) {
        self.data = initialData ?? []
        self.tableView = tableView
        self.delegate = delegate
        
        super.init()
        
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    // MARK: - Public API
    
    /**
     - note: Assumes that number of sections is not changing
     */
    public func update(with newData: [[T]]) -> Future<Void> {
        // If an update is already running, this update request will be postponsed...
        if activeUpdatePromise != nil {
            // Cancel the previous update. Only ever use the most recent request,
            // so if another request was postponed before this one cancel it
            if let waitingUpdatePromise = waitingUpdatePromise {
                waitingUpdatePromise.completeWithCancel()
            }
            
            // Save the information about the update
            waitingUpdatePromise = Promise<Void>()
            waitingData = newData
            
            return waitingUpdatePromise!.future
        }
        
        activeUpdatePromise = Promise<Void>()
        var diffs = newData.enumerated().map { KUDifference(before: data[$0.offset], after: $0.element) }
        data = newData
        
        // Do ALL the updates!
        tableView.performBatchUpdates({
            for section in 0..<diffs.count {
                var diff = diffs[section]
                
                let insertedIndexPaths = diff.inserted.map { IndexPath(row: $0.to, section: section) }
                let removedIndexPaths = diff.removed.map { IndexPath(row: $0.from, section: section) }
                
                // Insert the added cells
                tableView.insertRows(at: insertedIndexPaths, with: rowAnimation)
                // Delete the removed cells
                tableView.deleteRows(at: removedIndexPaths, with: rowAnimation)
                
                // Move the moved cells
                diff.informedMoved.forEach({ (tuple) in
                    tableView.moveRow(at: IndexPath(row: tuple.start, section: section), to: IndexPath(row: tuple.end, section: section))
                })
            }
        }) { (complete) in
            guard complete else {
                self.activeUpdatePromise!.completeWithFail("Didn't complete batch updates successfully")
                return
            }
            
            // Update all the unmoved cells in each section which have had their data changed since the value before
            let futures = self.data.enumerated().flatMap({ (sectionTuple) -> [Future<Any>] in
                let section = sectionTuple.offset
                return diffs[section].unmoved.compactMap({ (rowTuple) -> Future<Any>? in
                    let item = rowTuple.object // Unpack the tuple
                    let row = rowTuple.index
                    
                    // Only continue if the item says it has changed (default true)
                    guard item.changedSince(item: diffs[section].before[row]) else {
                        return nil
                    }
                    
                    // If the cell implements any of the protocols or classes, update it
                    let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: section))
                    if let cell = cell as? KUTableViewDiffCell<T> {
                        return cell.updateUI(animated: self.rowAnimation != .none, with: item).futureAny
                    } else if let cell = cell as? KUUpdatableView {
                        return cell.updateUI(animated: self.rowAnimation != .none).futureAny
                    } else {
                        return nil
                    }
                })
            })
            
            // Wait for it all to be done
            FutureBatch(futures).future.onSuccess(block: { (_) in
                self.activeUpdatePromise!.completeWithSuccess(Void())
            }).onFail(block: { (error) in
                self.activeUpdatePromise?.completeWithFail(error)
            })
        }
        
        // When the active update is done, start the waiting update (if any)
        activeUpdatePromise?.future.onComplete { (_) in
            self.activeUpdatePromise = nil
            
            // If an update is wating...
            if let data = self.waitingData, let promise = self.waitingUpdatePromise {
                // Clean out the stored values
                self.waitingUpdatePromise = nil
                self.waitingData = nil
                
                // And perform the update
                promise.completeUsingFuture(self.update(with: data))
            }
        }
        
        return activeUpdatePromise!.future.mainThreadFuture
    }
    
    // MARK: - UITableViewDataSource
    
    private func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return delegate.tableViewDiffController(tableView, cellForItem: data[indexPath.section][indexPath.row])
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return delegate.tableView(tableView, titleForHeaderInSection: section)
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return delegate.tableView(tableView, titleForFooterInSection: section)
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return delegate.tableView(tableView, canEditRowAt: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return delegate.tableView(tableView, canMoveRowAt: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        delegate.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if (delegate.tableView(tableView, canMoveRowAt: sourceIndexPath)) {
            let item = self.data[sourceIndexPath.section].remove(at: sourceIndexPath.row)
            self.data[destinationIndexPath.section].insert(item, at: destinationIndexPath.row)
        }
    }
}

public protocol TableViewDiffControllerData: Hashable {
    
}

extension TableViewDiffControllerData {
    func changedSince(item: Self) -> Bool {
        return true
    }
}

public protocol TableViewDiffControllerDelegate {
    func tableViewDiffController(_ tableView: UITableView, cellForItem item: Any) -> KUTableViewDiffCell<Any>
}

public extension TableViewDiffControllerDelegate {
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) { }
}
