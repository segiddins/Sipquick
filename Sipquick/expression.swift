struct Expression {
    enum ExpressionKind {
        case bare
        case call
        case functionDefinition
        case variableDeclaration
        case empty
        case conditional
    }
    let kind: ExpressionKind
    let children: [Expression]
    let args: [String]
    
    static func filterEmpty(children: [Expression]) -> [Expression] {
        return children.filter { $0.kind != .empty }
    }

    init(sexp: Sexp) {
        switch sexp {
        case let .single(arg):
            self.kind = .bare
            self.args = [arg]
            self.children = []
        case .none:
            self.kind = .empty
            self.children = []
            self.args = []
        case let .list(args):
            switch args.first {
            case nil, .some(.none):
                fatalError(".none as first element in nested expression")
            case .some(.list):
                self.kind = .call
                self.args = []
                self.children = Expression.filterEmpty(children: args.dropFirst().map(Expression.init))
            case let .some(.single(body)):
                switch body {
                case "def":
                    self.args = Array(args.dropFirst().dropLast().map {$0.description})
                    self.kind = .functionDefinition
                    self.children = Expression.filterEmpty(children: [Expression(sexp: args.last!)])
                case "var":
                    self.args = [args.dropFirst().first!.description]
                    self.children = Expression.filterEmpty(children: [Expression(sexp: args.last!)])
                    self.kind = .variableDeclaration
                case "condition":
                    self.kind = .conditional
                    self.children = args.dropFirst().map(Expression.init)
                    self.args = []
                default:
                    self.kind = .call
                    self.args = [body]
                    self.children = Expression.filterEmpty(children: args.dropFirst().map(Expression.init))
                }
            }
        }
    }
}
