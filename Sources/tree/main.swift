//
//  main.swift
//  tree
//
//  Created by Peter Matta on 10/31/18.
//

import Foundation
import FSNode
import Utility

// The first argument is always the executable, drop it
let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

let parser = ArgumentParser(
  usage: "<options>",
  overview: "List content of directories in tree-like format.")

let printHidden = parser.add(option: "--all", shortName: "-a", kind: Bool.self, usage: "List all files")
let justDirectories = parser.add(option: "--directories", shortName: "-d", kind: Bool.self, usage: "List only directories")
let parsedArguments = try parser.parse(arguments)

var dir = try! FSNode.from(path: FileManager.default.currentDirectoryPath)
if (parsedArguments.get(justDirectories) ?? false) {
  guard let aDir = dir.drop(where: { !$0.isDirectory }) else { exit(0) }
  dir = aDir
}
if !(parsedArguments.get(printHidden) ?? false) {
  guard let aDir = dir.drop(where: { $0.isHidden }) else { exit(0) }
  dir = aDir
}

print(dir)
print("\(dir.directories.count) directories\t\(dir.files.count) files")
