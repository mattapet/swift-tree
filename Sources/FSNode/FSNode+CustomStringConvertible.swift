//
//  FSNode+CustomStringConvertible.swift
//  tree
//
//  Created by Peter Matta on 11/1/18.
//

import Foundation

/// Formats the the FS structure as into a tree.
public func prettyString(_ node: FSNode) -> String {
  return _prettyString(node, printFullPath: false, "", true)
}

/// Formats the the FS structure as into a tree.
public func prettyString(_ node: FSNode, printFullPath: Bool) -> String {
  return _prettyString(node, printFullPath: false, "", true)
}

/// Formats the the FS structure as into a tree.
fileprivate func _prettyString(
  _ node: FSNode,
  printFullPath fullPath: Bool = false,
  _ indent: String,
  _ isLast: Bool
) -> String {
  let name = fullPath ? "\(node.path)/\(node.name)" : node.name
  let curr = "\(indent)\(isLast ? "\\-- " : "+-- ")\(name)\n"
  guard let contents = node.contents else { return curr }
  return curr + contents.enumerated()
    .map { (idx, content) in
      let indent = "\(indent)\(isLast ? "    " : "|   ")"
      let isLast = idx == contents.count - 1
      return _prettyString(content, printFullPath: fullPath, indent, isLast)
    }
    .joined(separator: "")
}

extension FSNode: CustomStringConvertible {
  /// Formats the the FS structure as into a tree.
  public var description: String {
    return prettyString(self)
  }
}
