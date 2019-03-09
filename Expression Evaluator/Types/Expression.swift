//
//  Expression.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-28.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation


//////////////////////
//MARK: - Expression Declaration
public enum Expression {
    
    indirect case add(Expression, Expression)
    indirect case subtract(Expression, Expression)
    indirect case multiply(Expression, Expression)
    indirect case divide(Expression, Expression)
    indirect case power(Expression, Expression)
    indirect case log(Expression, Expression)
    indirect case root(Expression, Expression)
    case n(Int)
    case x
    
    
    // Static constants
    public static let zero = Expression.n(0)
    public static let y = x
    public static let variable = x

    // Initializer
    public init (_ string: String, simplify: Bool = true) {

        let formattedExpression = Expression.formatExpression(string)
        self = Expression.createExpression(from: formattedExpression)
        if simplify {
            self.simplify()
        }
    }
    
}


//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  Expression formatting, parsing, and creation

public extension Expression {
    
    private static func createExpression<T: StringProtocol>(from str: T) -> Expression {
        guard !str.isEmpty else { fatalError() }
        
        var parentheticLevel = 0
        var angledBracketLevel = 0
        var expressionArr = [Either<Expression, Operator>]()
        var currentTermIndex = str.startIndex
        
        for (i, c) in zip(str.indices, str) {
            switch (parentheticLevel, angledBracketLevel, c) {
            case (_, _, "<"):
                angledBracketLevel += 1
                
            case (_, _, ">"):
                angledBracketLevel -= 1
                
            case (_, _, "("):
                parentheticLevel += 1
                
            case (_, _, ")"):
                parentheticLevel -= 1
                
            case (0, 0, " "):
                let term = identifyTerm(from: str[currentTermIndex..<i])
                expressionArr.append(term)
                currentTermIndex = str.index(after: i)
                continue
                
            default: break
            }
        }
        
        // Add lest term to expression array
        let term = identifyTerm(from: str[currentTermIndex..<str.endIndex])
        expressionArr.append(term)
        
        // Combine terms with operators
        let operatorGroups = Operator.groupedByPrecedence
        
        for (operators, associativity) in operatorGroups {
            guard expressionArr.count > 1 else {
                guard case let .left(expression) = expressionArr.first! else {
                    fatalError("Error creating equation")
                }
                return expression
            }
            reduceExpressionArray(&expressionArr, with: operators, associativity: associativity)
        }
        
        guard expressionArr.count == 1, case let .left(finalExpression) = expressionArr[0] else {
            fatalError("Error creating equation")
        }
        
        return finalExpression
    }
    private static func identifyTerm<T: StringProtocol>(from term: T) -> Either<Expression, Operator> {

        let term = String(term)
        
        switch term {
        // Operator
        case let s where Operator.allOperators.contains(s):
            guard let op = Operator(s) else {
                fatalError("Invalid format for expression")
            }
            
            return .right(op)
            
        // Integer
        case let s where s.allSatisfy({ "0123456789".contains($0) }):
            guard let n = Int(s) else {
                fatalError("Invalid format for expression")
            }
            return .left(.n(n))
            
        // Variable
        case let s where ["x", "X"].contains(s):
            return .left(.x)
            
        // nth root
        case let s where s.hasPrefix("root"):
            let rootRegex = try! NSRegularExpression(pattern: "^root(?:([\\+-]?[2-9]\\d*)|\\<(.+)\\>)\\((.+)\\)$")
            
            guard let match = rootRegex.firstMatch(in: term, range: term.nsRange) else {
                fatalError("Invalid format for expression")
            }
            let captureGroups = match.captureGroups(in: term)
            
            let n = captureGroups[0]
            let parentheticContents = captureGroups[1]
            
            return .left(.root(createExpression(from: n), createExpression(from: parentheticContents)))
            
        // Square root
        case let s where s.hasPrefix("sqrt"):
            let sqrtRegex = try! NSRegularExpression(pattern: "^sqrt\\((.+)\\)$")
            guard let match = sqrtRegex.firstMatch(in: term, range: NSRange(term.startIndex..., in: term)) else {
                fatalError("Invalid format for expression")
            }
            let captureGroups = match.captureGroups(in: term)
            
            let parentheticContents = captureGroups[0]
            return .left(.root(.n(2), createExpression(from: parentheticContents)))
            
        // Cube root
        case let s where s.hasPrefix("cbrt"):
            let cbrtRegex = try! NSRegularExpression(pattern: "^cbrt\\((.+)\\)$")
            guard let match = cbrtRegex.firstMatch(in: term, range: term.nsRange) else {
                fatalError("Invalid format for expression")
            }
            let captureGroups = match.captureGroups(in: term)
            
            let parentheticContents = captureGroups[0]
            return .left(.root(.n(3), createExpression(from: parentheticContents)))
            
        // Logarithm
        case let s where s.hasPrefix("log"):
            
            let rootRegex = try! NSRegularExpression(pattern: "^log(?:(0*[2-9]\\d*)|\\<(.+)\\>)?\\((.+)\\)$")
            
            guard let match = rootRegex.firstMatch(in: term, range: term.nsRange) else {
                fatalError("Invalid format for expression")
            }
            let captureGroups = match.captureGroups(in: term)
            
            let base = captureGroups.count == 2 ? captureGroups[0] : "10"
            let parentheticContents = captureGroups.last!
            
            return .left(.log(createExpression(from: base), createExpression(from: parentheticContents)))
            
        // Parentheses
        case let s where s.hasPrefix("(") && s.hasSuffix(")"):
            return .left(createExpression(from: s[s.index(after: s.startIndex)..<s.index(before: s.endIndex)]))
            
        // Invalid term
        default:
            break
        }
        
        fatalError("Invalid format for expression")
    }
    private static func reduceExpressionArray(_ arr: inout [Either<Expression, Operator>],
                                              with operations: [Operator],
                                              associativity: Operator.Associativity) {
        
        guard !operations.isEmpty else { return }
        
        let operators: [(index: Int, `operator`: Operator)] = Array(arr.lazy
            .filter {
                if case .right(_) = $0 { return true }
                else { return false }
            }
            .enumerated()
            .map {
                guard case let .right(op) = $0.element else { fatalError() }
                return (index: $0.offset * 2 + 1, operator: op)
            }
        )
        
        if associativity == .left {
            var combinationOffset = 0
            
            for (index, `operator`) in operators where operations.contains(`operator`) {
                guard case let .left(a) = arr[index - 1 - combinationOffset],
                    case let .left(b) = arr[index + 1 - combinationOffset] else {
                        fatalError("Error creating expression")
                }
                
                
                let replacementOperation = Expression.performOperation(between: a, and: b, with: `operator`)
                
                arr[(index - 1 - combinationOffset)...(index + 1 - combinationOffset)] = [.left(replacementOperation)]
                combinationOffset += 2
            }
        } else if associativity == .right {
            for (index, `operator`) in operators.reversed() where operations.contains(`operator`) {
                guard case let .left(a) = arr[index - 1],
                    case let .left(b) = arr[index + 1] else {
                        fatalError("Error creating expression")
                }
                
                let replacementOperation = Expression.performOperation(between: a, and: b, with: `operator`)
                
                arr[(index - 1)...(index + 1)] = [.left(replacementOperation)]
            }
        }
    }
    private static func performOperation(between a: Expression, and b: Expression, with operation: Operator) -> Expression {
        switch operation {
        case .addition: return .add(a, b)
        case .subtraction: return .subtract(a, b)
        case .multiplication: return .multiply(a, b)
        case .division: return .divide(a, b)
        case .exponentiation: return .power(a, b)
        }
    }
    private static func formatExpression<T: StringProtocol>(_ string: T) -> String {
        
        let exactNumberRegex = "[-\\+]?\\d+"
        //let operators = Operator.allOperatorsString
        let functions = ["x", "sqrt", "cbrt", "root", "log"]
        let anyOperator = "(?:" + Operator.allOperators.map { $0.rEsc() }.joined(separator: "|") + ")"
        let anyFunction = "(?:" + functions.map { $0.rEsc() }.joined(separator: "|") + ")"
        
        var str = String(string).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace other braces with parentheses
        do {
            let braceDict: [Character: String] = ["{" : "(", "[" : "(", "]" : ")", "}" : ")"]
            str = str.reduce("") { $0 + (braceDict[$1] ?? "\($1)") }
        }
        
        // Replace other exponentiation operator with hat operator
        do {
            str = str.replacingOccurrences(of: "**", with: "^")
        }
        
        // Replace default log with log<10>
        do {
            str = str.replacingOccurrences(of: "log(", with: "log<10>(")
        }
        
        // Space binary operators
        do {
            str = str.replacingOccurrences(of: rOr(exactNumberRegex, "\\)", "(?:x|X)") + anyOperator.rGroup() + rOr(exactNumberRegex, "(?:\\(|" + anyFunction + "|x|X)", group: .positiveLookbehind), with: "$1 $2 ", options: .regularExpression)
            
            
            str = str.replacingOccurrences(of: "(?<=[^\\s\\d])" + anyOperator.rGroup() + "(?=[^\\s\\d])", with: "$1 $2 $3", options: .regularExpression)
            
        }
        
        // Add necessary brackets for adjactent multiplication
//        do {
//            // log & root
//            do {
//                let matches = str.regex.matches(pattern: "(\(exactNumberRegex)(?:x|X)?|x|X)(?=log|root)")
//                var braceIndices = [(character: Character, index: String.Index)]()
//                for match in matches.reversed() {
//
//                    var angleCount = 0
//                    let angleString = str[match.endIndex...].drop { $0 != "<"}
//                    var index = match.startIndex
//                    braceIndices.append((character: "(", index: match.startIndex))
//                    for (c, i) in zip(angleString, angleString.indices) {
//                        switch c {
//                        case "<": angleCount += 1
//                        case ">": angleCount -= 1
//                        default: break
//                        }
//                        if angleCount == 0 { index = i; break }
//                    }
//                    guard angleCount == 0, str[str.index(after: index)] == "(" else { fatalError("Invalid format") }
//
//                    var braceCount = 0
//                    let braceString = str[str.index(after: index)...]
//                    var closingIndex = index
//                    for (c, i) in zip(braceString, braceString.indices) {
//                        switch c {
//                        case "(": braceCount += 1
//                        case ")": braceCount -= 1
//                        default: continue
//                        }
//                        if braceCount == 0 { closingIndex = i; break }
//                    }
//                    
//                    braceIndices.append((character: ")", index: str.index(after: closingIndex)))
//
//                }
//                for brace in braceIndices.sorted(by: { $0.index > $1.index }) {
//                    str.insert(brace.character, at: brace.index)
//                }
//            }
//            // sqrt and cbrt
//            do {
//                let matches = str.regex.matches(pattern: "(\(exactNumberRegex)(?:x|X)?|x|X)(?=sqrt|cbrt)")
//                var braceIndices = [(character: Character, index: String.Index)]()
//                for match in matches.reversed() {
//                    braceIndices.append((character: "(", index: match.startIndex))
//                    var braceCount = 0
//                    let braceString = str[match.startIndex...].drop { $0 != "(" }
//                    var closingIndex = match.startIndex
//                    for (c, i) in zip(braceString, braceString.indices) {
//                        switch c {
//                        case "(": braceCount += 1
//                        case ")": braceCount -= 1
//                        default: continue
//                        }
//                        if braceCount == 0 { closingIndex = i; break }
//                    }
//
//                    braceIndices.append((character: ")", index: str.index(after: closingIndex)))
//
//                }
//                for brace in braceIndices.sorted(by: { $0.index > $1.index }) {
//                    str.insert(brace.character, at: brace.index)
//                }
//            }
//            // 3x
//            do {
//                str = str.replacingOccurrences(of: "(\(exactNumberRegex))(x|X)(?!root|log|sqrt|cbrt)", with: "($1 * $2)", options: .regularExpression)
//            }
//        }
        
        
        
        
        // Replace adjacent variable mutiplication with star operator
        do {
            str = str.regex.replacing(pattern: "(?<=[^\\<\\+\\s\\(])(x|X)", with: " * x")
            str = str.regex.replacing(pattern: "(x|X)(?=[^\\s\\>\\)])", with: "x * ")
        }
        
        // Replace parenthetic multiplication with star operator
        do {
            let parentheticMultiplicationPattern = rOr("(?<!log|root)(\(exactNumberRegex))\\s*(?=\\(|\(anyFunction)", "(\\))\\s*(?=\(exactNumberRegex))", "(\\))\\s*(?=\\(|\(anyFunction)", group: .none)
            
            str = str.replacingOccurrences(of: parentheticMultiplicationPattern, with: "$1$2$3 * ", options: .regularExpression)
            
            str = str.replacingOccurrences(of: ")(", with: ") * (")
        }
        // Replace adjacent multiplication with star operator
        do {
            let adjacentMultiplicationPattern = exactNumberRegex.rGroup() + "(?=\(anyFunction))"
            
            str = str.replacingOccurrences(of: adjacentMultiplicationPattern, with: "$1 * ", options: .regularExpression)
            
        }
        
        // Fix prefix negative operator
        do {
            if let firstCharacter = str.first, firstCharacter == "-" {
                str.replaceSubrange(str.startIndex...str.startIndex, with: "0 - ")
            }
            str = str.replacingOccurrences(of: "-\\(", with: "0 - (", options: .regularExpression)
        }
        
        // Remove prefix positive operator
        do {
            
            if let firstCharacter = str.first, firstCharacter == "+" {
                str.removeFirst()
            }
            
            str = str.replacingOccurrences(of: "(?<=[\\s\\(])\\+(?=[^\\)\\s])", with: "", options: .regularExpression)
        }
        
        str = str.replacingOccurrences(of: "\\([\\s\\)\\(]*\\)", with: "")
        
        return str
        
    }
    
}


//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  Computed properties

public extension Expression {

    public var isNumber: Bool {
        if case .n = self {
            return true
        }
        return false
    }
    public var isVariable: Bool {
        if case .x = self {
            return true
        }
        return false
    }
    public var isAddition: Bool {
        if case .add = self {
            return true
        }
        return false
    }
    public var isSubtraction: Bool {
        if case .divide = self {
            return true
        }
        return false
    }
    public var isDivision: Bool {
        if case .divide = self {
            return true
        }
        return false
    }
    public var isMultiplication: Bool {
        if case .multiply = self {
            return true
        }
        return false
    }
    public var isPower: Bool {
        if case .power = self {
            return true
        }
        return false
    }
    public var isRoot: Bool {
        if case .root = self {
            return true
        }
        return false
    }
    public var isLog: Bool {
        if case .log = self {
            return true
        }
        return false
    }
    public var isNegative: Bool {
        if case let .n(a) = self, a < 0 {
            return true
        } else if case .subtract(0, _) = self {
            return true
        }
        return false
    }
    public var operands: (Expression, Expression)? {
        switch self {
        case let .add(a, b),
             let .subtract(a, b),
             let .multiply(a, b),
             let .divide(a, b),
             let .power(a, b),
             let .log(a, b),
             let .root(a, b):
            return (a, b)
        case .n, .x:
            return nil
        }
    }
}


//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  Pattern matching with integers

public extension Expression {
    public static func ~= (lhs: Int, rhs: Expression) -> Bool {
        if case let .n(x) = rhs, x == lhs {
            return true
        }
        return false
    }
}


//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  Expression simplification


public extension Expression {
    public mutating func simplify() {
        switch self {
        // Variable
        case .x, .n:
            return
            
        // Addition
        case var .add(lhs, rhs):
            
            lhs.simplify()
            rhs.simplify()
            
            self = lhs + rhs
            
            switch (lhs, rhs) {
                
            // 0 + x = x
            case let (x, 0),
                 let (0, x):
                self = x
                
            // x + (-x) = 0
            case let (.n(x), .n(y)) where x == -y:
                self = .zero
                
            // x + (0 - x) = 0
            case let (x, .subtract(0, y)) where x == y,
                 let (.subtract(0, y), x) where x == y:
                self = .zero
                
            // x + (y - x) = y
            case let (x1, .subtract(y, x2)) where x1 == x2,
                 let (.subtract(y, x1), x2) where x1 == x2:
                self = y
                
                
            // a(x) + b(x) = (a + b)(x)
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                self = (a + b) * x1
                simplify()
                
            // x + ax = (a + 1)(x)
            case let (x1, .multiply(a, x2)) where x1 == x2,
                 let (x1, .multiply(x2, a)) where x1 == x2,
                 let (.multiply(a, x1), x2) where x1 == x2,
                 let (.multiply(x1, a), x2) where x1 == x2:
                if case let .n(value) = a {
                    self = (.n(value + 1) * x1)
                    simplify()
                    return
                }
                self = (a + 1) * x1
                simplify()
                
            // (a / x) + (b / x) = (a + b) / x
            case let (.divide(a, x1), .divide(b, x2)) where x1 == x2:
                self = (a + b) / x1
                simplify()
                
            // (a / x) + (b / xy) = (ay + b) / xy
            case let (.divide(a, x1), .divide(b, .multiply(y, x2))) where x1 == x2,
                 let (.divide(a, x1), .divide(b, .multiply(x2, y))) where x1 == x2,
                 let (.divide(b, .multiply(y, x1)), .divide(a, x2)) where x1 == x2,
                 let (.divide(b, .multiply(x1, y)), .divide(a, x2)) where x1 == x2:
                self = (a * y + b) / (x1 * y)
                simplify()
                
            // Add fractions with lcm
            case let (.divide(a, .n(x)), .divide(b, .n(y))):
                let d = lcm(x, y)
                self = (a * .n(d / x) + b * .n(d / y)) / .n(d)
                simplify()
                
            // a + (b / x) = (ax + b) / x
            case let (a, .divide(b, x)),
                 let (.divide(b, x), a):
                self = (a * x + b) / x
                simplify()
                
            // log<x>(a) + log<x>(b) = log<x>(ab)
            case let (.log(x, a), .log(y, b)) where x == y:
                self = .log(x, a * b)
                simplify()
                
            // a + b
            case let (.n(a), .n(b)):
                self = .n(a + b)
                
                
            // No simplification
            default:
                return
            }
            
        // Subtraction
        case var .subtract(lhs, rhs):
            
            lhs.simplify()
            rhs.simplify()
            
            self = lhs - rhs
            
            switch (lhs, rhs) {
                
            // x - 0 = x
            case let (x, 0):
                self = x
                
            // x - x = 0
            case let (x, y) where x == y:
                self = .zero
                
            // 0 - x = -x
            case let (0, .n(y)):
                self = .n(-y)
                
            // x - (x + y) = -y
            // (x - y) - x = -y
            case let (x1, .add(x2, y))      where x1 == x2,
                 let (x1, .add(y, x2))      where x1 == x2,
                 let (.subtract(x1, y), x2) where x1 == x2:
                self = -y
                
            // (x + y) - x = y
            // x - (x - y) = y
            case let (.add(x1, y), x2)      where x1 == x2,
                 let (.add(y, x1), x2)      where x1 == x2,
                 let (x1, .subtract(x2, y)) where x1 == x2:
                self = y
                
            // a(x) - b(x) = (a - b)(x)
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                self = (a - b) * x1
                simplify()
                
            // x - ax = (a + 1)(x)
            case let (x1, .multiply(a, x2)) where x1 == x2,
                 let (x1, .multiply(x2, a)) where x1 == x2:
                if case let .n(value) = a {
                    self = .n(value + 1) * x1
                    simplify()
                    return
                }
                self = (a + 1) * x1
                simplify()
                
            // ax - x = (a - 1)(x)
            case let (.multiply(a, x1), x2) where x1 == x2,
                 let (.multiply(x1, a), x2) where x1 == x2:
                if case let .n(value) = a {
                    self = .n(value - 1) * x1
                    simplify()
                    return
                }
                self = (a - 1) * x1
                simplify()
                
            // (a / x) - (b / x) = (a - b) / x
            case let (.divide(a, x1), .divide(b, x2)) where x1 == x2:
                self = (a - b) / x1
                simplify()
                
            // (a / x) - (b / xy) = (ay - b) / xy
            case let (.divide(a, x1), .divide(b, .multiply(y, x2))) where x1 == x2,
                 let (.divide(a, x1), .divide(b, .multiply(x2, y))) where x1 == x2:
                self = (a * y - b) / (x1 * y)
                simplify()
                
            // (a / xy) - (b / x) = (a - by) / xy
            case let (.divide(a, .multiply(y, x1)), .divide(b, x2)) where x1 == x2,
                 let (.divide(a, .multiply(x1, y)), .divide(b, x2)) where x1 == x2:
                self = (a - b * y) / (x1 * y)
                simplify()
                
            // Subtract fractions with lcm
            case let (.divide(a, .n(x)), .divide(b, .n(y))):
                let d = lcm(x, y)
                self = (a * .n(d / x) - b * .n(d / y)) / .n(d)
                simplify()
                
            // Subtract fractions with common denominator multiplicand and lcm
            case let (.divide(a, .multiply(g1, .n(b))), .divide(x, .multiply(g2, .n(y)))) where g1 == g2,
                 let (.divide(a, .multiply(g1, .n(b))), .divide(x, .multiply(.n(y), g2))) where g1 == g2,
                 let (.divide(a, .multiply(.n(b), g1)), .divide(x, .multiply(g2, .n(y)))) where g1 == g2,
                 let (.divide(a, .multiply(.n(b), g1)), .divide(x, .multiply(.n(y), g2))) where g1 == g2:
                let lcmBY = lcm(b, y)
                self = ((a * .n(lcmBY / b) - (x * .n(lcmBY / y))) / (.n(lcmBY) * g1))
                simplify()
                
            // log<x>(a) - log<x>(b) = log<x>(a / b)
            case let (.log(x, a), .log(y, b)) where x == y:
                self = .log(x, a / b)
                simplify()
                
            // a - b
            case let (.n(a), .n(b)):
                self = .n(a - b)
                
            // no simplification
            default:
                return
            }
            
        // Multiplication
        case var .multiply(lhs, rhs):
            
            lhs.simplify()
            rhs.simplify()
            
            self = lhs * rhs
            
            switch (lhs, rhs) {
                
            // 0x = 0
            case (0, _), (_, 0):
                self = .zero
                
            // 1x = x
            case let (x, 1), let (1, x):
                self = x
                
            // -1x = -x
            case let (x, -1), let (-1, x):
                self = -x
                
            // x * x = x ^ 2
            case let (x, y) where x == y:
                self = x ^ 2
                simplify()
                
                
            // a * (b * x) = ab * x
            case let (.n(a), .multiply(.n(b), x)),
                 let (.n(a), .multiply(x, .n(b))),
                 let (.multiply(.n(a), x), .n(b)),
                 let (.multiply(x, .n(a)), .n(b)):
                self = .n(a * b) * x
                
            // b * (a / b) = a
            case let (b1, .divide(a, b2)) where b1 == b2,
                 let (.divide(a, b1), b2) where b1 == b2:
                self = a
                
            // x * (a / b) = ((x / GCD(x, b)) * a) / (b / GCD(x, b))
            case let (.n(x), .divide(a, .n(b))),
                 let (.divide(a, .n(b)), .n(x)):
                let gcdBX = gcd(b, x)
                self = (.n(x / gcdBX) * a) / .n(b / gcdBX)
                simplify()
                
            // x * x ^ y = x ^ (y + 1)
            case let (x1, .power(x2, y)) where x1 == x2,
                 let (.power(x1, y), x2) where x1 == x2:
                if case let .n(value) = y {
                    self = x1 ^ .n(value + 1)
                    simplify()
                    return
                }
                self = x1 ^ (1 + y)
                simplify()
                
//            // TODO: Record addition
//            // a * (log<x>(y) / b) = (a / b) * log<x>(y)
//            case let (a, .divide(.log(x, y), b)),
//                 let (.divide(.log(x, y), b), a):
//                self = (a / b) * .log(x, y)
//                simplify()
                
            // (1 / y) * x = x / y
            case let (.divide(1, den), num),
                 let (num, .divide(1, den)):
                self = (num /  den)
                simplify()
                
            // (-1 / y) * x = x / y
            case let (.divide(-1, den), num),
                 let (num, .divide(-1, den)):
                if case let .n(x) = num {
                    self = (.n(-x) / den)
                } else if case let .n(y) = den {
                    self =  (num / .n(-y))
                } else {
                    self = ((.zero - num) / den)
                }
                simplify()
                
            // (x / y) * (y / x) = 1
            case let (.divide(x1, y1), .divide(y2, x2)) where x1 == x2 && y1 == y2:
                self = .n(1)
                
            // Cross reduction
            case let (.divide(.n(a), .n(b)), .divide(.n(x), .n(y))):
                let commonAY = gcd(a, y)
                let commonBX = gcd(b, x)
                self = .n((a / commonAY) * (x / commonBX)) / .n((y / commonAY) * (b / commonBX))
                simplify()
                
            // Cross reduction
            case let (.divide(.n(a), b), .divide(x, .n(y))):
                let commonAY = gcd(a, y)
                self = ((.n(a / commonAY) * x) / (.n(y / commonAY) * b))
                simplify()
                
            // Cross reduction
            case let (.divide(a, .n(b)), .divide(.n(x), y)):
                let commonBX = gcd(b, x)
                self = (a * .n(x / commonBX)) / (y * .n(b / commonBX))
                simplify()
                
            // a * (x / y) = ax / y
            case let (a, .divide(x, y)),
                 let (.divide(x, y), a):
                self = (a * x) / y
                simplify()
                
            // x^a * x^b = x^(a + b)
            case let (.power(x1, a), .power(x2, b)) where x1 == x2:
                self = x1 ^ (a + b)
                simplify()
                
            // x^a * px^b = px^(a + b)
            case let (.power(x1, a), .multiply(p, .power(x2, b))) where x1 == x2,
                 let (.power(x1, a), .multiply(.power(x2, b), p)) where x1 == x2,
                 let (.multiply(p, .power(x1, a)), .power(x2, b)) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .power(x2, b)) where x1 == x2:
                self = p * (x1 ^ (a + b))
                simplify()
                
            // px^a * qx^b = pqx^(a + b)
            case let (.multiply(p, .power(x1, a)), .multiply(q, .power(x2, b))) where x1 == x2,
                 let (.multiply(p, .power(x1, a)), .multiply(.power(x2, b), q)) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .multiply(q, .power(x2, b))) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .multiply(.power(x2, b), q)) where x1 == x2:
                self = p * q * (x1 ^ (a + b))
                simplify()
                
            // Combining powers
            case let (.n(a), .power(.n(b), c)),
                 let (.power(.n(b), c), .n(a)):

                guard let power = a.asPower(), power.base == b else {
                    return
                }
                self = .n(b) ^ (.n(power.exponent) + c)
                simplify()
                
            
                
            // log<x>(a) * log<a>(y) = log<x>(y)
            case let (.log(x, a), .log(b, y)) where a == b:
                self = .log(x, y)
                simplify()
                
            // a * b
            case let (.n(a), .n(b)):
                self = .n(a * b)
                
            // No simplification
            default:
                return
            }
            
        // Division
        case var .divide(lhs, rhs):
            
            lhs.simplify()
            rhs.simplify()
            
            switch (lhs, rhs) {
            // x / 0 = NaN
            case (_, 0):
                fatalError("Division by zero")
                
            // 0 / x = 0
            case (0, _):
                self = .zero
                
            // x / 1 = x
            case let (x, 1):
                self = x
                
            // x / -1 = -x
            case let (x, -1):
                self = -x
                
            // x / x = 1
            case let (x, y) where x == y:
                self = .n(1)
                
            // (x * y) / x = y
            case let (.multiply(x1, y), x2) where x1 == x2,
                 let (.multiply(y, x1), x2) where x1 == x2:
                self = y
                
            // x / (x / y) = y
            case let (x1, .divide(x2, y)) where x1 == x2:
                self = y
                
            // (a / b) / c = a / bc
            case let (.divide(a, b), c):
                self = a / (b * c)
                simplify()
                
            // a / (x / y) = a * (y / x)
            case let (a, .divide(x, y)):
                self = a * (y / x)
                simplify()
                
            // ax / bx = a / b
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                self = a / b
                simplify()
                
            // x / (x * y) = 1 / y
            case let (x1, .multiply(x2, y)) where x1 == x2,
                 let (x1, .multiply(y, x2)) where x1 == x2:
                self = 1 / y
                
            // (ax + bx) / x = a + b
            case let (.add(.multiply(a, x1), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3:
                self = a + b
                simplify()
                
            // (ax + bx) / cx = (a + b) / c
            case let (.add(.multiply(a, x1), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3:
                self = (a + b) / c
                simplify()
                
            // (ax - bx) / x = a - b
            case let (.subtract(.multiply(a, x1), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3:
                self = a - b
                simplify()
                
            // (ax - bx) / cx = (a - b) / c
            case let (.subtract(.multiply(a, x1), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3:
                self = (a - b) / c
                simplify()
    
            // x^y / x = x ^ (y - 1)
            case let (.power(x1, y), x2) where x1 == x2:
                self = x1 ^ (y - 1)
                simplify()
                
            // x / x^y = x ^ (1 - y)
            case let (x1, .power(x2, y)) where x1 == x2:
                self = x1 ^ (1 - y)
                simplify()
                
            // x^a / x^b = x^(a - b)
            case let (.power(x1, a), .power(x2, b)) where x1 == x2:
                self = x1 ^ (a - b)
                simplify()
                
            // ax^y / x = ax^(y - 1)
            case let (.multiply(a, .power(x1, y)), x2) where x1 == x2,
                 let (.multiply(.power(x1, y), a), x2) where x1 == x2:
                self = a * x1 ^ (y - 1)
                simplify()
                
            // x^y / ax = (1 / a) * x^(y - 1)
            case let (.power(x1, y), .multiply(a, x2)) where x1 == x2,
                 let (.power(x1, y), .multiply(x2, a)) where x1 == x2:
                self = (1 / a) * x1 ^ (y - 1)
                simplify()
                
            // ax^y / bx = (a / b) * x^(y - 1)
            case let (.multiply(a, .power(x1, y)), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, .power(x1, y)), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(.power(x1, y), a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(.power(x1, y), a), .multiply(x2, b)) where x1 == x2:
                self = (a / b) * x1 ^ (y - 1)
                simplify()
                
            // ax / x^y = ax^(1 - 1)
            case let (x1, .multiply(a, .power(x2, y))) where x1 == x2,
                 let (x1, .multiply(.power(x2, y), a)) where x1 == x2:
                self = a * x1 ^ (1 - y)
                simplify()
                
            // x / ax^y = (1 / a) * x^(1 - y)
            case let (.multiply(a, x1), .power(x2, y)) where x1 == x2,
                 let (.multiply(x1, a), .power(x2, y)) where x1 == x2:
                self = (1 / a) * x1 ^ (1 - y)
                simplify()
                
            // ax / bx^y = (a / b) * x^(1 - y)
            case let (.multiply(a, x1), .multiply(b, .power(x2, y))) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, .power(x2, y))) where x1 == x2,
                 let (.multiply(a, x1), .multiply(.power(x2, y), b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(.power(x2, y), b)) where x1 == x2:
                self = (a / b) * x1 ^ (1 - y)
                simplify()
                
                
            // ax^g / x^h = ax^(g - h)
            case let (.power(x1, g), .multiply(a, .power(x2, h))) where x1 == x2,
                 let (.power(x1, g), .multiply(.power(x2, h), a)) where x1 == x2:
                self = a * x1 ^ (g - h)
                simplify()
                
            // x^g / ax^h = (1 / a) * x^(g - h)
            case let (.multiply(a, .power(x1, g)), .power(x2, h)) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .power(x2, h)) where x1 == x2:
                self = (1 / a) * x1 ^ (g - h)
                simplify()
                
            // ax^g / bx^h = (a / b) * x^(g - h)
            case let (.multiply(a, .power(x1, g)), .multiply(b, .power(x2, h))) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .multiply(b, .power(x2, h))) where x1 == x2,
                 let (.multiply(a, .power(x1, g)), .multiply(.power(x2, h), b)) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .multiply(.power(x2, h), b)) where x1 == x2:
                self = (a / b) * x1 ^ (g - h)
                simplify()
                
            // Combining powers
            case let (.n(a), .power(.n(b), c)):
                guard let power = a.asPower(), power.base == b else {
                    return
                }
                self = .n(b) ^ (.n(power.exponent) - c)
                simplify()
                
            // Combining powers
            case let (.power(.n(b), c), .n(a)):
                guard let power = a.asPower(), power.base == b else {
                    return
                }
                self = .n(b) ^ (c - .n(power.exponent))
                simplify()
                
            // 10 / 2 = 5
            case let (.n(x), .n(y)) where x % y == 0:
                self = .n(x / y)
                
            // 10 / 5 = 1 / 2
            case let (.n(x), .n(y)):
                let a = gcd(x, y)
                let newX = x / a
                let newY = y / a
                
                if let powerY = newY.asPower() {
                    if newX == 1 {
                        self = .n(powerY.base) ^ .n(-powerY.exponent)
                        return
                    }
                    let baseX = pow(Double(newX), 1.0 / Double(powerY.exponent))
                    
                    if baseX == floor(baseX) {
                        self = (.n(Int(baseX)) / .n(powerY.base)) ^ .n(powerY.exponent)
                        return
                    }
                }
                self = .n(x / a) / .n(y / a)
                
            // log<x>(a) / log<x>(b) = log<b>(a)
            case let (.log(x, a), .log(y, b)) where x == y:
                self = .log(b, a)
                simplify()
                
            // xlog<y>(a) / log<y>(b) = xlog<b>(a)
            case let (.multiply(x, .log(y1, a)), .log(y2, b)) where y1 == y2:
                self = x * .log(b, a)
                simplify()
                
            // log<y>(a) / xlog<y>(b) = (1 / x)log<b>(a)
            case let (.log(y1, a), .multiply(x, .log(y2, b))) where y1 == y2:
                self = (.n(1) / x) * .log(b, a)
                simplify()
                
            // xlog<y>(a) / zlog<y>(b) = (x/z)log<b>(a)
            case let (.multiply(x1, .log(y1, a)), .multiply(x2, .log(y2, b))) where y1 == y2:
                self = (x1 / x2) * .log(b, a)
                simplify()
                
//            // (a * log<x>(y)) / b = (a / b) * log<x>(y)
//            case let (.multiply(a, .log(x, y)), b),
//                 let (.multiply(.log(x, y), a), b):
//                self = (a / b) * .log(x, y)
//                simplify()
                
            // x / log<a>(b) = xlog<b>(a)
            case let (x, .log(a, b)):
                self = x * .log(b, a)
                simplify()
                
            // No simplification
            default:
                return
            }
            
        // Exponentiation
        case var .power(lhs, rhs):
            
            lhs.simplify()
            rhs.simplify()
            
            self = lhs ^ rhs
            
            switch (lhs, rhs) {
                
            // 0 ^ 0
            case (0, 0):
                fatalError("0⁰ is not a number.")
                
            // x ^ 0 = 1
            case (_, 0):
                self = .n(1)
                
            // 0 ^ x = 0
            case (0, _):
                self = .zero
                
            // x ^ 1 = x
            case let (x, 1):
                self = x
                
            // (x / y) ^ -e = (y / x) ^ e
            case let (.divide(x, y), .n(e)) where e < 0:
                self = (y / x) ^ .n(-e)
                simplify()
                
            // Not sure if this is a good simplification
            // a ^ -b = 1 / (a ^ b)
            case let (a, b) where b.isNegative:
                self = 1 / (a ^ -b)
                simplify()
                
            // ˣ√(y) ^ x = y
            case let (.root(x1, y), x2) where x1 == x2:
                self = y
                
            // x ^ logᵪy = y
            case let (x1, .log(x2, y)) where x1 == x2:
                self = y
                
            // x ^ alogᵪy = y ^ a
            case let (x1, .multiply(a, .log(x2, y))) where x1 == x2,
                 let (x1, .multiply(.log(x2, y), a)) where x1 == x2:
                self = y ^ a
                
            
                
            // (a ^ b) ^ c = a ^ bc
            case let (.power(a, b), c):
                self = a ^ (b * c)
                simplify()
                
            // Reduce power to lowest base
            case let (.n(x), y):
                if let perfectPower = x.asPower() {
                    self = .n(perfectPower.base) ^ (.n(perfectPower.exponent) * y)
                    simplify()
                    //self = (.n(perfectPower.base) ^ (.n(perfectPower.exponent) * y)._simplified())
                }
                return
                
            // No simplification
            default:
                return
                
            }
            
        // Logarithms
        case var .log(lhs, rhs):
           
            lhs.simplify()
            rhs.simplify()
            
            self = .log(lhs, rhs)
            
            switch (lhs, rhs) {
                
            // log<...1> = NaN
            case let (.n(x), _) where x < 2:
                fatalError("Cannot find the value of a log with an integral base less than 2")
                
            // logᵪ(x) = 1
            case let (x, y) where x == y:
                self = .n(1)
                
            // log<ˣ√y>(y) = x
            // log<1 / ˣ√y>(1 / y) = x
            case let (.root(x, y1), y2) where y1 == y2,
                 let (.divide(1, .root(x, y1)), .divide(1, y2)) where y1 == y2:
                self = x
                
            // log<1 / ˣ√y>(y) = -x
            // log<ˣ√y>(1 / y) = -x
            case let (.divide(1, .root(x, y1)), y2) where y1 == y2,
                 let (.root(x, y1), .divide(1, y2)) where y1 == y2:
                self = -x
                
            // log<1/a>(1/b) = log<a>(b)
            case let (.divide(.n(1), a), .divide(.n(1), b)):
                self = .log(a, b)
                simplify()
                
            // log<1/a>(b) = -log<a>(b)
            // log<a>(1/b) = -log<a>(b)
            case let (.divide(.n(1), a), b),
                 let (a, .divide(.n(1), b)):
                self = -(.log(a, b))
                simplify()
                
            // log<a^x>(b^x) = lob<a>(b)
            case let (.power(a, x1), .power(b, x2)) where x1 == x2:
                self = .log(a, b)
                simplify()
                
            // log<a^y>(b^x) = (x / y) * lob<a>(b)
            case let (.power(a, x1), .power(b, x2)):
                self = (x2 / x1) * .log(a, b)
                simplify()
                
                // log<b>(x^y) = ylog<b>(x)
            // log<root<y>(b)>(x) = ylog<b>(x)
            case let (b, .power(x, y)),
                 let (.root(y, b), x):
                self = y * .log(b, x)
                simplify()
                
            // log<b^y>(x) = (1/y) * log<b>(x)
            case let (.power(y, b), x):
                self = (1 / y) * .log(b, x)
                simplify()
                
            // log<x>(xy) = 1 + log<x>(y)
            case let (x1, .multiply(x2, y)) where x1 == x2,
                 let (x1, .multiply(y, x2)) where x1 == x2:
                self = 1 + .log(x1, y)
                simplify()
                
            // log<x>(x / y) = 1 - log<x>(y)
            case let (x1, .divide(x2, y)) where x1 == x2:
                self = 1 - .log(x1, y)
                simplify()
                
            // log<x>(x / y) = log<x>(y) - 1
            case let (x1, .divide(x2, y)) where x1 == x2:
                self = .log(x1, y) - 1
                simplify()
                
            // log₂₇(4) = ⅔log₃(2)
            case let (.n(x), .n(y)):
                let powerX = x.asPower()
                let powerY = y.asPower()
                switch (powerX, powerY) {
                case let (px?, py?):
                    if px.exponent == py.exponent {
                        self = .log(.n(px.base), .n(py.base))
                        return
                    }
                    let a = gcd(px.exponent, py.exponent)
                    
                    if a == px.exponent {
                        self = .n(py.exponent / a) * .log(.n(px.base), .n(py.base))
                        return
                    }
                    self = (.n(py.exponent / a) / .n(px.exponent / a)) * .log(.n(px.base), .n(py.base))
                    
                case let (px?, _):
                    self = (1 / .n(px.exponent)) * .log(.n(px.base), .n(y))
                    
                case let (_, py?):
                    self = .n(py.exponent) * .log(.n(x), .n(py.base))
                    
                default:
                    return
                }
            // log<4>(x) = ½log₂(x)
            case let (.n(x), y):
                guard let perfectPower = x.asPower() else { return }
                self = (1 / .n(perfectPower.exponent)) * .log(.n(perfectPower.base), y)
                if !y.isVariable {
                    simplify()
                }
                
                
            // logᵪ(4) = 2logᵪ(2)
            case let (x, .n(y)):
                guard let perfectPower = y.asPower() else { return }
                self = .n(perfectPower.exponent) * .log(x, .n(perfectPower.base))
                if !x.isVariable {
                    simplify()
                }
                
                
                
            // No simplification
            default:
                return
                
            }
            
        // Root
        case var .root(lhs, rhs):
        
            lhs.simplify()
            rhs.simplify()
            
            self = .root(lhs, rhs)
            
            switch (lhs, rhs) {
            // log<...0> = NaN
            case let (.n(x), _) where x <= 0:
                fatalError("Cannot find the value of the nth root where n is less than 2")
                
            // ¹√x = x
            case let (1, x):
                self = x
                
            // √25 = 5
            case let (.n(x), .n(y)):
                let baseY = pow(Double(y), 1.0 / Double(x))
                if baseY == floor(baseY) {
                    self = .n(Int(baseY))
                }
                
            // √(5^2) = 5
            case let (x1, .power(y, x2)) where x1 == x2:
                self = y
                
                
            // No simplification
            default:
                return
                
            }
        }
    }
    
    public func simplified() -> Expression {
        var simplifiedExpression = self
        simplifiedExpression.simplify()
        return simplifiedExpression
    }
}



//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  Expression evaluation

public extension Expression {
    
    public func evaluate(withX x: Double? = nil) -> Double {
        
        switch self {
        case let .add(a, b): return a.evaluate(withX: x) + b.evaluate(withX: x)
        case let .subtract(a, b): return a.evaluate(withX: x) - b.evaluate(withX: x)
        case let .multiply(a, b): return a.evaluate(withX: x) * b.evaluate(withX: x)
        case let .divide(a, b): return a.evaluate(withX: x) / b.evaluate(withX: x)
        case let .power(a, b): return pow(a.evaluate(withX: x), b.evaluate(withX: x))
        case let .log(a, b): return log10(b.evaluate(withX: x)) / log10(a.evaluate(withX: x))
        case let .root(a, b):
            let r = a.evaluate(withX: x)
            if r == 2 {
                return sqrt(b.evaluate(withX: x))
            } else if r == 3 {
                return cbrt(b.evaluate(withX: x))
            }
            return pow(b.evaluate(withX: x), 1.0 / a.evaluate(withX: x))
        case let .n(a): return Double(a)
        case .x:
            guard let xValue = x else { fatalError("Requires x value to be solved") }
            return xValue
        }
    }
    
}


//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  Other methods

public extension Expression {

    public func contains(where predicate: (Expression) -> Bool) -> Bool {
        guard !predicate(self) else { return true }
        
        switch self {
        case let .add(a, b),
             let .subtract(a, b),
             let .multiply(a, b),
             let .divide(a, b),
             let .power(a, b),
             let .log(a, b),
             let .root(a, b):
            if predicate(a) || predicate(b) {
                return true
            } else {
                return a.contains(where: predicate) || b.contains(where: predicate)
            }
            
        // .n(_), .x both can't contain any other values
        default: return false
            
        }
    }
    public func contains(_ expression: Expression) -> Bool {
        guard self != expression else { return true }
        
        switch self {
        case let .add(a, b),
             let .subtract(a, b),
             let .multiply(a, b),
             let .divide(a, b),
             let .power(a, b),
             let .log(a, b),
             let .root(a, b):
            if a == expression || b == expression {
                return true
            } else {
                return a.contains(expression) || b.contains(expression)
            }
            
        // .n(_), .x both can't contain any other values
        default: return false
        }
    }
    public func containsVariable() -> Bool {
        switch self {
        case .x:
            return true
        case let .add(a, b),
             let .subtract(a, b),
             let .multiply(a, b),
             let .divide(a, b),
             let .power(a, b),
             let .log(a, b),
             let .root(a, b):
            return a.containsVariable() || b.containsVariable()
        default:
            return false
        }
        
    }
 
}


//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  Operators

public extension Expression {
    
    // Binary arithmetic operators
    public static func + (lhs: Expression, rhs: Expression) -> Expression {
        return Expression.add(lhs, rhs)
    }
    public static func - (lhs: Expression, rhs: Expression) -> Expression {
        return Expression.subtract(lhs, rhs)
    }
    public static func * (lhs: Expression, rhs: Expression) -> Expression {
        return Expression.multiply(lhs, rhs)
    }
    public static func / (lhs: Expression, rhs: Expression) -> Expression {
        return Expression.divide(lhs, rhs)
    }
    public static func ^ (lhs: Expression, rhs: Expression) -> Expression {
        return Expression.power(lhs, rhs)
    }
    
    // Compound assignment operators
    public static func += (lhs: inout Expression, rhs: Expression) {
        lhs = Expression.add(lhs, rhs)
    }
    public static func -= (lhs: inout Expression, rhs: Expression) {
        lhs = Expression.subtract(lhs, rhs)
    }
    public static func *= (lhs: inout Expression, rhs: Expression) {
        lhs = Expression.multiply(lhs, rhs)
    }
    public static func /= (lhs: inout Expression, rhs: Expression) {
        lhs = Expression.divide(lhs, rhs)
    }
    public static func ^= (lhs: inout Expression, rhs: Expression) {
        lhs = Expression.power(lhs, rhs)
    }
    
    // Prefix negative operator
    public static prefix func -(expression: Expression) -> Expression {
        if case let .n(x) = expression {
            return .n(-x)
        }
        return .subtract(.zero, expression)
    }
    
}


//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  ExpressibleByIntegerLiteral Conformance

extension Expression: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    
    public init(integerLiteral value: Expression.IntegerLiteralType) {
        self = .n(value)
    }
}


//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  Equatable Conformance

extension Expression: Equatable {
    public static func == (lhs: Expression, rhs: Expression) -> Bool {
        switch (lhs, rhs) {
        case let (.add(a1, b1), .add(a2, b2)) where a1 == a2 && b1 == b2,
             let (.add(a1, b1), .add(b2, a2)) where a1 == a2 && b1 == b2,
             let (.add(b1, a1), .add(a2, b2)) where a1 == a2 && b1 == b2,
             let (.add(b1, a1), .add(b2, a2)) where a1 == a2 && b1 == b2: return true
        case let (.subtract(a1, b1), .subtract(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.multiply(a1, b1), .multiply(a2, b2)) where a1 == a2 && b1 == b2,
             let (.multiply(a1, b1), .multiply(b2, a2)) where a1 == a2 && b1 == b2,
             let (.multiply(b1, a1), .multiply(a2, b2)) where a1 == a2 && b1 == b2,
             let (.multiply(b1, a1), .multiply(b2, a2)) where a1 == a2 && b1 == b2: return true
        case let (.divide(a1, b1), .divide(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.power(a1, b1), .power(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.log(a1, b1), .log(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.root(a1, b1), .root(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.n(a), .n(b)): return a == b
        case (.x, .x): return true
        default: return false
        }
    }
}


//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  CustomStringConvertible Conformance

extension Expression: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return description
    }
    public var description: String {
        return _description.strippingOutermostBraces()
    }
    
    private var _description: String {
        switch self {
        case let .add(a, b):
            return "(" + a._description + " + " + b._description + ")"
        case let .subtract(.n(0), .root(a, b)) where a.isNumber || a.isVariable:
            return "-" + Expression.root(a, b)._description
        case let .subtract(.n(0), a):
            return "-" + a._description
        case let .subtract(a, b):
            return "(" + a._description + " - " + b._description + ")"
        case let .multiply(.n(a), b),
             let .multiply(b, .n(a)) where b.isLog || b.isRoot || b.isVariable:
            return "\(a)" + b._description
        case let .multiply(a, b):
            return "(" + a._description + " * " + b._description + ")"
        case let .divide(a, b):
            return "(" + a._description + " / " + b._description + ")"
        case let .power(a, b):
            return "(" + a._description + " ^ " + b._description + ")"
        case let .log(base, n):
            var nStr = n._description
            if case .n = n { nStr = "(\(nStr))" }
            if case let .n(a) = base {
                let subscriptDict: [Character: String] = ["0" : "₀", "1" : "₁", "2" : "₂", "3" : "₃", "4" : "₄", "5" : "₅", "6" : "₆", "7" : "₇", "8" : "₈", "9" : "₉", "-" : "₋"]
                return "log" + "\(a)".reduce(into: "") { $0 += subscriptDict[$1]! } + nStr
            }
            
            return "log<" + base._description + ">" + nStr
                        
        case let .root(n, root):
            var rootStr = root._description
            if case .n = root { rootStr = "(\(rootStr))" }
            if case .x = n {
                return "ˣ√" + rootStr
            }
            if case let .n(a) = n {
                switch a {
                case 2: return "√(" + root._description + ")"
//                case 3: return "∛(" + root._description + ")"
//                case 4: return "∜(" + root._description + ")"
                default:
                    let superscriptDict: [Character: String]  = ["0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",  "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "-": "⁻"]
                    return "\(a)".reduce(into: "") { $0 += superscriptDict[$1]! } + "͟√" + rootStr
                }
            }
            return "root<" + n._description + ">" + rootStr

        case let .n(a):
            return "\(a)"
            
        case .x:
            return "x"
        }
    }
    
    public var literalDescription: String {
        switch self {
        case let .add(a, b):
            return ".add(" + a.literalDescription + ", " + b.literalDescription + ")"
        case let .subtract(a, b):
            return ".subtract(" + a.literalDescription + ", " + b.literalDescription + ")"
        case let .multiply(a, b):
            return ".multiply(" + a.literalDescription + ", " + b.literalDescription + ")"
        case let .divide(a, b):
            return ".divide(" + a.literalDescription + ", " + b.literalDescription + ")"
        case let .power(a, b):
            return ".power(" + a.literalDescription + ", " + b.literalDescription + ")"
        case let .log(a, b):
            return ".log(" + a.literalDescription + ", " + b.literalDescription + ")"
        case let .root(a, b):
            return ".root(" + a.literalDescription + ", " + b.literalDescription + ")"
        case let .n(a):
            return ".n(\(a))"
        case .x:
            return ".x"
        }
    }
    public var latex: String {
        return _latex.strippingOutermostBraces()
    }
    private var _latex: String {
        switch self {
        case let .add(a, b):
            return "\\left(" + a._latex + " + " + b._latex + "\\right)"
        case let .subtract(0, n):
            return "-" + n._latex
        case let .subtract(a, b):
            return "\\left(" + a._latex + " - " + b._latex + "\\right)"
            
        case let .multiply(.n(a), b) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition,
             let .multiply(b, .n(a)) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition:
            if b.isNegative {
                return "\(-a)" + b._latex.dropFirst()
            }
            return "\(a)" + b._latex
        
        case let .multiply(.multiply(.n(a), .x), b) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition,
             let .multiply(.multiply(.x, .n(a)), b) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition,
             let .multiply(b, .multiply(.n(a), .x)) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition,
             let .multiply(b, .multiply(.x, .n(a))) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition:
            if b.isNegative {
                return "\(-a)x" + b._latex.dropFirst()
            }
            return "\(a)x" + b._latex
            
        case let .multiply(.x, n) where n.isPower || n.isRoot || n.isSubtraction || n.isAddition,
             let .multiply(n, .x) where n.isPower || n.isRoot || n.isSubtraction || n.isAddition:
            if n.isNegative {
                return "-x" + n._latex.dropFirst()
            }
            return "x" + n._latex
        case let .multiply(a, b):
            return "\\left(" + a._latex + " \\cdot " + b._latex + "\\right)"
        case let .divide(a, b):
            return "\\\\frac{" + a._latex.strippingOutermostBraces() + "}{" + b._latex.strippingOutermostBraces() + "}"
        case let .power(a, b):
            return a._latex + "^{" + b._latex.strippingOutermostBraces() + "}"
        case let .log(a, b):
            let strA = a.isDivision || a.isPower || a.isRoot ? "\\left(\(a._latex)\\right)" : a._latex
            let strB = b.isDivision || b.isPower || b.isRoot ? "\\left(\(b._latex)\\right)" : b._latex
            return "\\mathrm{log}_{" + strA + "}" + strB
        case let .root(a, b):
            return "\\sqrt[" + a._latex + "]{" + b._latex + "}"
        case let .n(a):
            return a < 0 ? "\\left(\(a)\\right)" : "\(a)"
        case .x:
            return "x"
        }
    }
    
}


//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  Exponentiation precedence and operator declaration

precedencegroup ExponentiationPrecedence {
    higherThan: MultiplicationPrecedence
    lowerThan: BitwiseShiftPrecedence
    associativity: right
}
infix operator ^: ExponentiationPrecedence


