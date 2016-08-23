extension Expression {
    func parenthesize(_ s: String) -> String { return "(\(s))" }

    var isOperatorCall: Bool {
        switch kind {
        case .call:
            guard let funcName = args.first else { return false }
            switch funcName {
            case "+", "-", "*", "%", "/", "||", "&&", "&", "|", "==", ">", "<", ">=", "<=", "[]", "..", "!=":
                return true
            default:
                return false
            }
        default:
            return false
        }
    }

    func asRuby() -> String {
        let indent: (String) -> String = { string in
            string.components(separatedBy: "\n").joined(separator: "\n  ")
        }
        switch kind {
        case .bare:
            return args.joined(separator: " ")
        case .call:
            if isOperatorCall {
                let op = args.first!
                let rec = children.first!
                let opArgs = children.dropFirst()

                return parenthesize(rec.asRuby() + ".\(op)" + parenthesize(opArgs.map { $0.asRuby() }.joined(separator: ", ")))
            }
            else {
                return args.joined(separator: " ") + parenthesize( children.map { $0.asRuby() }.joined(separator: ", "))
            }
        case .functionDefinition:
            let name = args.first!
            let argNames = args.dropFirst()
            return "def \(name)(\(argNames.joined(separator: ", ")))\n" + children.map { "  " + indent($0.asRuby()) }.joined(separator: "\n") + "\nend"
        case .empty:
            return ""
        case .variableDeclaration:
            let varName = args.joined(separator: " ")
            return "\(varName) = (\(children.map {$0.asRuby()}.joined(separator: ", ")))"
        case .conditional:
            guard children.count == 3 else {
                fatalError("a conditional must have exactly three arguments")
            }
            let conditional = children[0]
            let positive = children[1]
            let negative = children[2]
            return [
                "if \(conditional.asRuby())",
                "  " + indent(positive.asRuby()),
                "else",
                "  " + indent(negative.asRuby()),
                "end"
            ].joined(separator: "\n")
        }
    }
}
