var args = CommandLine.arguments
args.removeFirst()

guard let fileToCompile = args.first else { fatalError("no file to compile") }
args.removeFirst()
compile(sourceFile: fileToCompile, outputFile: args.first)
