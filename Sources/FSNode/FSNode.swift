//
//  FSNode.swift
//  tree
//
//  Created by Peter Matta on 10/31/18.
//

import Foundation

/// Default file manager instance.
fileprivate let fm = FileManager.default

/// Constants representing file manager file types.
fileprivate enum FileType: String {
  /// Represents `"NSFileTypeRegular"` string.
  case regular = "NSFileTypeRegular"
  /// Represents `"NSFileTypeDirectory"` string.
  case directory = "NSFileTypeDirectory"
  /// Represents `"NSFileTypeSymbolicLink"` string.
  case symbolLink = "NSFileTypeSymbolicLink"
}

public enum FSNodeError: Error {
  case invalidFileType
}

/// A file system node with it's path, name and contents.
public indirect enum FSNode {
  /// A regular file.
  case file(String, String)
  
  /// A symlink.
  case symbolLink(String, String)
  
  /// A directory with it's contents.
  case directory(String, String, [FSNode])
}

// MARK: - Construction

extension FSNode {
  /// Creates a file system structre form the given path.
  public static func from(
    path: String
  ) throws -> FSNode {
    let name = fm.displayName(atPath: path)
    let type = try fileType(atPath: path)
    
    switch type {
    case .regular: return .file(path, name)
    case .symbolLink: return .symbolLink(path, name)
    case .directory:
      let contents = try fm
        .contentsOfDirectory(atPath: path)
        .map { try FSNode.from(path: "\(path)/\($0)") }
      return .directory(path, name, contents)
    }
  }
}

// MARK: - Accessors

extension FSNode {
  /// Returns file path to the file node.
  public var path: String {
    switch self {
    case let .file(path, _),
         let .symbolLink(path, _),
         let .directory(path, _, _):
      return path
    }
  }
  
  /// Returns node's name.
  public var name: String {
    switch self {
    case let .file(_, name),
         let .symbolLink(_, name),
         let .directory(_, name, _):
      return name
    }
  }
  
  /// Returns contents of the node, if the node is directory, `nil` otherwise.
  public var contents: [FSNode]? {
    switch self {
    case let .directory(_, _, contents): return contents
    default: return nil
    }
  }
  
  /// Returns `true` if node is a directory, `false` otherwise.
  public var isDirectory: Bool {
    switch self {
    case .directory: return true
    default: return false
    }
  }
  
  /// Returns `true` if node is a file, `false` otherwise.
  public var isFile: Bool {
    switch self {
    case .file: return true
    default: return false
    }
  }
  
  /// Returns `true` if node is a symbolLink, `false` otherwise.
  public var isSymbolLink: Bool {
    switch self {
    case .symbolLink: return true
    default: return false
    }
  }
  
  /// Returns `true` if file or directory starts with a `'.'` character, `false`
  /// otherwise.
  public var isHidden: Bool {
    return name.starts(with: ".")
  }
}

// MARK: - Transformations

extension FSNode {
  /// Returns array of directory names.
  public var directories: [String] {
    switch self {
    case .file, .symbolLink: return []
    case let .directory(_, name, contents):
      return [name] + contents.flatMap { $0.directories }
    }
  }
  
  /// Returns an array of file names existing in the FS tree.
  public var files: [String] {
    switch self {
    case .symbolLink: return []
    case let .file(_, name): return [name]
    case let .directory(_, _, contents):
      return contents.flatMap { $0.files }
    }
  }
}

extension FSNode {
  /// Drops nodes which does not return `true` upon usage of the `predicate`.
  public func drop(
    where predicate: (FSNode) throws -> Bool
  ) rethrows -> FSNode? {
    if try predicate(self) { return nil }
    switch self {
    case .file(_), .symbolLink(_): return self
    case let .directory(path, name, contents):
      return .directory(
        path,
        name,
        try contents
          .map { try $0.drop(where: predicate) }
          .filter { $0 != nil }
          .map { $0! })
    }
  }
}

extension FSNode: Equatable {
  public static func == (lhs: FSNode, rhs: FSNode) -> Bool {
    switch (lhs, rhs) {
    case (let .file(lhsName), let .file(rhsName)),
         (let .symbolLink(lhsName), let .symbolLink(rhsName)):
      return lhsName == rhsName
    case (let .directory(lhsPath, lhsName, lhsContent),
          let .directory(rhsPath, rhsName, rhsContent)):
      return lhsPath == rhsPath
        && lhsName == rhsName && lhsContent == rhsContent
    default:
      return false
    }
  }
}

// MARK: - Utility methods

fileprivate extension FSNode {
  /// Returns a type of file at the given path
  static func fileType(atPath path: String) throws -> FileType {
    let attr = try fm.attributesOfItem(atPath: path)
    let dict = NSDictionary(dictionary: attr)
    guard let type = dict.fileType() else { throw FSNodeError.invalidFileType }
    guard let fileType = FileType(rawValue: type) else {
      throw FSNodeError.invalidFileType
    }
    return fileType
  }
}
