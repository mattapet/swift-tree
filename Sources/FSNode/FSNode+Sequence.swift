//
//  FSNode+Sequence.swift
//  tree
//
//  Created by Peter Matta on 11/1/18.
//

import Foundation

public struct FSIterator: IteratorProtocol {
  public typealias Element = FSNode
  
  /// Current queue of values.
  var queue: [FSNode]
  
  /// Creates an iterator with the root.
  public init (root: FSNode) {
    self.queue = [root]
  }
  
  /// Returns next `FSNode`.
  public mutating func next() -> FSNode? {
    guard let top = queue.first else { return nil }
    queue = Array(queue.dropFirst(1))
    switch top {
    case let .directory(_, _, contents):
      queue.append(contentsOf: contents)
    default: break
    }
    return top
  }
}

extension FSNode: Sequence {
  public typealias Iterator = FSIterator
  
  public typealias Element = FSNode
  
  /// Returns `FSNode` iterator
  public func makeIterator() -> FSNode.Iterator {
    return FSIterator(root: self)
  }
}
