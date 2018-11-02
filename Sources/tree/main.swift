//
//  main.swift
//  tree
//
//  Created by Peter Matta on 10/31/18.
//

import Foundation
import FSNode
import Utility

extension FSNode {
  public func drop(whereMaxDepth depth: Int) -> FSNode? {
    guard depth > 0 else { return nil }
    guard let contents = self.contents else { return self }
    let dropped = contents
      .map { $0.drop(whereMaxDepth: depth - 1) }
      .filter { $0 != nil }
      .map { $0! }
    return .directory(path, name, dropped)
  }
  
  public func dropEmpty() -> FSNode? {
    switch self {
    case .file, .symbolLink: return self
    case let .directory(path, name, contents):
      let dropped = contents
        .map { $0.dropEmpty() }
        .filter { $0 != nil }
        .map { $0! }
      return dropped.count > 0 ? .directory(path, name, dropped) : nil
    }
  }
}

// The first argument is always the executable, drop it
let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

let parser = ArgumentParser(
  usage: "[options]",
  overview: "List content of directories in tree-like format.")

let printHidden = parser.add(option: "--all", shortName: "-a", kind: Bool.self, usage: "List all files")
let justDirectories = parser.add(option: "--directories", shortName: "-d", kind: Bool.self, usage: "List only directories")
let matchPattern = parser.add(option: "--match", shortName: "-m", kind: String.self, usage: "Include only matching files")
let excludePattern = parser.add(option: "--exclude", shortName: "-e", kind: String.self, usage: "Exlude files matching pattern")
let maxDepth = parser.add(option: "--depth", shortName: "-D", kind: Int.self, usage: "Max depth to print")
let noEmptyDirs = parser.add(option: "--no-empty", shortName: "-E", kind: Bool.self, usage: "Exclude all empty directories")
let fullPaths = parser.add(option: "--full-paths", shortName: "-P", kind: Bool.self, usage: "Print full paths")
let parsedArguments = try parser.parse(arguments)

var dir = try! FSNode.from(path: FileManager.default.currentDirectoryPath)

if let depth = parsedArguments.get(maxDepth) {
  guard let aDir = dir.drop(whereMaxDepth: depth) else { exit(0) }
  dir = aDir
}
if (parsedArguments.get(justDirectories) ?? false) {
  guard let aDir = dir.drop(where: { !$0.isDirectory }) else { exit(0) }
  dir = aDir
}
if !(parsedArguments.get(printHidden) ?? false) {
  guard let aDir = dir.drop(where: { $0.isHidden }) else { exit(0) }
  dir = aDir
}
if let pattern = parsedArguments.get(matchPattern) {
  guard let aDir = dir.drop(where: {
    !$0.isDirectory
      && $0.name.range(of: pattern, options: .regularExpression) == nil
  }) else { exit(0) }
  dir = aDir
}
if let pattern = parsedArguments.get(excludePattern) {
  guard let aDir = dir.drop(where: {
    !$0.isDirectory
        && $0.name.range(of: pattern, options: .regularExpression) != nil
  }) else { exit(0) }
  dir = aDir
}
if (parsedArguments.get(noEmptyDirs) ?? false) {
  guard let aDir = dir.dropEmpty() else { exit(0) }
  dir = aDir
}

print(prettyString(dir, printFullPath: parsedArguments.get(fullPaths) ?? false))
print("\(dir.directories.count) directories\t\(dir.files.count) files")
