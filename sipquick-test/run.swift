import Foundation.NSTask

func run(path: String, arguments: [String]) -> (out: String, status: Int) {
    let task = Process()
    task.launchPath = path
    task.arguments = arguments
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .ascii)!
    return (output, Int(task.terminationStatus))
}
