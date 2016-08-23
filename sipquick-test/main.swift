import Darwin
import Foundation.NSFileManager
let sipquick_path = String(CommandLine.arguments[0].characters.dropLast(5))

let specDirectory = "/Users/segiddins/Desktop/Sipquick/sipquick-spec/"
let specFiles = try! FileManager().contentsOfDirectory(atPath: specDirectory).filter { $0.hasSuffix(".spq") }.map { specDirectory + $0 }

let tests = specFiles.map(Test.init)
let failures = tests.map { $0.run() }.filter { $0.0 == false }
if failures.isEmpty { exit(EXIT_SUCCESS) }
failures.map { $0.1 }.forEach { print($0) }
exit(EXIT_FAILURE)
