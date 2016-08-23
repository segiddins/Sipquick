import Foundation.NSString

struct Test {
    let script: String
    let name: String
    let expectedOutput: String
    let expectedExit: Int
    
    init(script: String) {
        self.script = script
        let contents = try! String.init(contentsOfFile: script)
        let metadata = contents.components(separatedBy: "/////\n")[1].components(separatedBy: "\n")
        self.name = metadata[0]
        self.expectedExit = Int(metadata[1])!
        self.expectedOutput = metadata.dropFirst(2).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func run() -> (Bool, String) {
        let (compileOutput, compileStatus) = sipquick_test
            .run(path: sipquick_path, arguments: [script, "/private/var/tmp/sipquick-test \(name).exe"])
        guard compileStatus == 0 else {
            return (false, "failed to compile \(name):\n\(compileOutput)")
        }
        let (output, status) = sipquick_test
            .run(path: "/private/var/tmp/sipquick-test \(name).exe", arguments: [])
        let success = output == expectedOutput && status == expectedExit
        let errorMessage = "failed \(name): got \(output.debugDescription) (\(status)), expected \(expectedOutput.debugDescription) (\(expectedExit))"
        return (success, errorMessage)
    }
}
