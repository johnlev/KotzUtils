/**
 A struct that describes how an array has changed between two states.
 
 Used by the KUTableViewDiffController to describe how to change the table view between two data states.
 */
struct KUDifference<T:Hashable> {
    /// The data before the change
    public let before: [T]
    /// The data after the change
    public let after: [T]
    
    /**
     Create a difference object with the before and after states
     
     - parameter before: The data before the change
     - parameter after: The data after the change
     */
    init(before: [T], after: [T]) {
        self.before = before
        self.after = after
    }
    
    public lazy var beforeSet: Set<T> = {
        return Set(before)
    }()
    public lazy var afterSet: Set<T> = {
        return Set(after)
    }()
    
    public lazy var allObjects: Set<T> = {
        return beforeSet.union(afterSet)
    }()
    public lazy var removedObjects: Set<T> = {
        return beforeSet.subtracting(afterSet)
    }()
    public lazy var retainedObjects: Set<T> = {
        return beforeSet.intersection(afterSet)
    }()
    public lazy var insertedObjects: Set<T> = {
        return afterSet.subtracting(beforeSet)
    }()
    
    /// The objects that were inserted
    public lazy var inserted: [(object: T, to: Int)] = {
        return insertedObjects.map({ (object: T) -> (object: T, to: Int) in
            return (object, after.firstIndex(of: object)!)
        })
    }()
    
    /// The objects that were removed
    public lazy var removed: [(object: T, from: Int)] = {
        return removedObjects.map({ (object: T) -> (object: T, from: Int) in
            return (object, before.firstIndex(of: object)!)
        })
    }()
    
    /// Before array after removals and additions
    private lazy var informedBefore: [T] = {
        var informedBefore = Array(before)
        inserted.forEach({ (tuple) in
            informedBefore.insert(tuple.object, at: tuple.to)
        })
        removed.forEach({ (tuple) in
            informedBefore.remove(at: tuple.from)
        })
        return informedBefore
    }()
    
    /// After array without the removals and additions
    private lazy var uninformedAfter: [T] = {
        var uninformedAfter = Array(after)
        inserted.forEach({ (tuple) in
            uninformedAfter.remove(at: tuple.to)
        })
        removed.forEach({ (tuple) in
            uninformedAfter.insert(tuple.object, at: tuple.from)
        })
        return informedBefore
    }()
    
    /// The objects that moved after additions and removals with original indicies
    public lazy var moved: [(object: T, start: Int, end: Int)] = {
        return retainedObjects.compactMap({ (object) -> (T, Int, Int)? in
            let informedIndexBefore = informedBefore.firstIndex(of: object)!
            let indexBefore = before.firstIndex(of: object)!
            let indexAfter = after.firstIndex(of: object)!
            return informedIndexBefore != indexAfter ? (object, indexBefore, indexAfter) : nil
        })
    }()
    
    public lazy var unmoved: [(object: T, index: Int)] = {
        var set = retainedObjects
        moved.forEach({ (tuple) in
            if set.contains(tuple.object) {set.remove(tuple.object)}
        })
        return set.map({ (data) -> (T, Int) in
            return (data, self.after.firstIndex(of: data)!)
        })
    }()
    
    /// The objects that have moved assuming that the additions and removals haven't happen yet
    public lazy var uninformedMoved: [(object: T, start: Int, end: Int)] = {
        return retainedObjects.compactMap({ (object) -> (T, Int, Int)? in
            let indexBefore = before.firstIndex(of: object)!
            let uninformedIndexAfter = uninformedAfter.firstIndex(of: object)!
            return indexBefore != uninformedIndexAfter ? (object, indexBefore, uninformedIndexAfter) : nil
        })
    }()
    
    /// The objects that have moved even after additions and removals
    public lazy var informedMoved: [(object: T, start: Int, end: Int)] = {
        return retainedObjects.compactMap({ (object) -> (T, Int, Int)? in
            let informedIndexBefore = informedBefore.firstIndex(of: object)!
            let indexAfter = after.firstIndex(of: object)!
            return informedIndexBefore != indexAfter ? (object, informedIndexBefore, indexAfter) : nil
        })
    }()
    
    /// Assume no additions or removals, these are the objects which have changed position
    public lazy var naiveMoved: [(object: T, start: Int, end: Int)] = {
        return retainedObjects.compactMap({ (object) -> (T, Int, Int)? in
            let indexBefore = before.firstIndex(of: object)!
            let indexAfter = after.firstIndex(of: object)!
            return indexBefore != indexAfter ? (object, indexBefore, indexAfter) : nil
        })
    }()
}
