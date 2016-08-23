enum Either<Left, Right> {
    case left(Left)
    case right(Right)
}

extension String {
    var uncons: (UnicodeScalar, String)? {
        guard let head = unicodeScalars.first else { return nil }
        return (head, String(unicodeScalars.dropFirst()))
    }
    
}

struct Parser<In, Out> {
    let parse: (In) -> (remainder: In, result: Out)?
    
    func bind<B>(f: @escaping (Out) -> Parser<In, B>) -> Parser<In, B> {
        return Parser<In, B> { input in
            if let match = self.parse(input) {
                return f(match.result).parse(match.remainder)
            }
            return nil
        }
    }
    
    func fmap<B>(f: @escaping (Out) -> B) -> Parser<In, B> {
        return bind { const(f($0)) }
    }
    
    func or<B>(_ parser: Parser<In, B>) -> Parser<In, Either<Out, B>> {
        return Parser<In, Either<Out, B>> { input in
            if let match = self.parse(input) { return (match.remainder, .left(match.result)) }
            return parser.parse(input).map { ($0.0, .right($0.1)) }
        }
    }
    
    func or(_ parser: Parser<In, Out>) -> Parser<In, Out> {
        return Parser<In, Out> { input in
            if let match = self.parse(input) { return match }
            return parser.parse(input)
        }
    }
    
    func then<B>(_ parser: Parser<In, B>) -> Parser<In, (Out, B)> {
        return Parser<In, (Out, B)> { input in
            return self.parse(input).flatMap { (remainder, result) in
                return parser.parse(remainder).map { ($0.0, (result, $0.1)) }
            }
        }
    }
    
    func many() -> Parser<In, [Out]> {
        return Parser<In, [Out]> { input in
            var input = input
            var result = [Out]()
            while let match = self.parse(input) {
                input = match.remainder
                result.append(match.result)
            }
            if result.isEmpty { return nil }
            return (input, result)
        }
    }
    
    func maybeMany() -> Parser<In, [Out]> {
        return Parser<In, [Out]> { input in
            var input = input
            var result = [Out]()
            while let match = self.parse(input) {
                input = match.remainder
                result.append(match.result)
            }
            return (input, result)
        }
    }
    
    func maybe() -> Parser<In, Out?> {
        return Parser<In, Out?> { input in
            if let match = self.parse(input) { return (match.remainder, match.result) }
            return (input, nil)
        }
    }
}

protocol Emptyable {
    var isEmpty: Bool { get }
    static var empty: Self { get }
}
extension String: Emptyable {
    static var empty: String { return String() }
}

extension Parser where In: Emptyable {
    func andThatsAll() -> Parser<In, Out> {
        return  then(Parser<In, ()> { input in
            if input.isEmpty { return (input, ()) }
            return nil
        }).fmap { (match: Out, _) in
            return match
        }
    }
}

func ignoreFirst<In, Out1, Out2>(_ parser: Parser<In, (Out1, Out2)>) -> Parser<In, Out2> {
    return parser.fmap { $0.1 }
}

func ignoreSecond<In, Out1, Out2>(_ parser: Parser<In, (Out1, Out2)>) -> Parser<In, Out1> {
    return parser.fmap { $0.0 }
}

func empty<In>() -> Parser<In, ()> {
    return Parser { ($0, ()) }
}

func unichar(_ char: UnicodeScalar) -> Parser<String, UnicodeScalar> {
    return Parser { input in
        if input.unicodeScalars.first == char { return (String(input.unicodeScalars.dropFirst()), char) }
        return nil
    }
}

func const<In, Out>(_ x: Out) -> Parser<In, Out> {
    return Parser { ($0, x) }
}

func anyOf<S: Sequence>(_ options: S) -> Parser<String, UnicodeScalar> where S.Iterator.Element == UnicodeScalar {
    return Parser { input in
        guard let (head, tail) = input.uncons, options.contains(head) else { return nil }
        return (tail, head)
    }
}

func anyExcept<S: Sequence>(_ options: S) -> Parser<String, UnicodeScalar> where S.Iterator.Element == UnicodeScalar {
    return Parser { input in
        guard let (head, tail) = input.uncons, !options.contains(head) else { return nil }
        return (tail, head)
    }
}

extension UnicodeScalar: Strideable {
    public typealias Stride = Int
    public func advanced(by n: Stride) -> UnicodeScalar {
        return UnicodeScalar(value.advanced(by: n))!
    }
    
    public func distance(to other: UnicodeScalar) -> Stride {
        return value.distance(to: other.value)
    }
    
    func to(_ other: UnicodeScalar) -> CountableClosedRange<UnicodeScalar> {
        return CountableClosedRange(uncheckedBounds: (self, other))
    }
}

let digit = anyOf(("0" as UnicodeScalar).to("9"))
let integer: Parser<String, Int> = unichar("-").or(unichar("+")).maybe().then(digit.many()).fmap { (sign, digits) in
    var digits = digits
    if let sign = sign { digits.insert(sign, at: 0) }
    return Int(String.UnicodeScalarView(digits).description)!
}

let whitespace = anyOf([" ", "\n"])

func ignoreSpaces<Out>(_ parser: Parser<String, Out>) -> Parser<String, Out> {
    return whitespace.maybeMany().then(parser).then(whitespace.maybeMany()).fmap { return $0.0.1 }
}

func parens<Out>(_ parser: Parser<String, Out>) -> Parser<String, Out> {
    return unichar("(").then(parser).then(unichar(")")).fmap { return $0.0.1 }
}

func optionalParens<Out>(_ parser: Parser<String, Out>) -> Parser<String, Out> {
    return parens(parser).or(parser)
}

func lazy<In, Out>(_ f: @escaping () -> Parser<In, Out>) -> Parser<In, Out> {
    return Parser<In, Out> { input in
        return f().parse(input)
    }
}
