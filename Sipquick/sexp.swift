    enum Sexp: CustomStringConvertible {
        case single(String)
        case none
        indirect case list([Sexp])
        var description: String {
            switch self {
            case let .single(s):
                return "\(s)"
            case let .list(children):
                return "(\(children.map { $0.description }.joined(separator: " ")))"
            case .none:
                return "()"
            }
        }
    }
