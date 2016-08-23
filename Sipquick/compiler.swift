import Foundation

func compile(sourceFile: String, outputFile: String?) -> Void {
    let output = outputFile ?? sourceFile + ".exe"
    
    guard let sexp = schemeParser.parse(try! String(contentsOfFile: sourceFile))?.result else {fatalError("failed to parse \(sourceFile)")}
    let toplevelExpressions = sexp.map(Expression.init)
    
    let rb = (["#!/usr/bin/env ruby"] + toplevelExpressions.map { $0.asRuby() } + ["\n"]).joined(separator: "\n")
    
    try! rb.write(toFile: output, atomically: false, encoding: String.Encoding.utf8)
    try! FileManager().setAttributes([.posixPermissions : 0o744], ofItemAtPath: output)
}
