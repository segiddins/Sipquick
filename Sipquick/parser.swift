let schemeParser: Parser<String, [Sexp]> = {
    func string() -> Parser<String, Sexp> {
        let quote: UnicodeScalar = "\""
        return ignoreSpaces(unichar(quote).then(anyExcept([quote]).many().fmap { $0.map {$0.description}.joined() }).then(unichar(quote))).fmap { .single("\"\($0.0.1)\"") }
    }

    func token() -> Parser<String, Sexp> {
        let token: Parser<String, Sexp> = anyExcept([" ", "(", ")"]).many().fmap { return .single($0.map { String($0) }.joined()) }
        return string().or(ignoreSpaces(token))
    }

    func sexp() -> Parser<String, Sexp> {
        let sexpParser: Parser<String, Sexp> = token().or(lazy { ignoreSpaces(sexp()) }).many().fmap { .list($0) }
        let emptyParser: Parser<String, Sexp> = ignoreSpaces(empty()).fmap { .none }
        return parens(sexpParser.or(emptyParser))
    }

    func dropEndingMetadata() -> Parser<String, Void> {
        return unichar("\n").maybe().then(
            unichar("/").then(unichar("/")).then(unichar("/")).then(unichar("/")).then(unichar("/"))
        ).fmap { a, b in return }
    }
    
    func singleLineComment() -> Parser<String, Void> {
        return unichar(";").then(anyExcept(["\n"]).maybeMany()).then(unichar("\n").maybe()).fmap { _,_ in return }
    }
    
    return ignoreSecond(sexp().then(unichar("\n").maybe()).maybeMany().fmap { $0.map { $0.0 } }.then(dropEndingMetadata().or(empty().andThatsAll())))
}()
