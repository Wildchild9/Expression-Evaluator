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
    
    // Static constants
    public static let zero = Expression.n(0)

    // Initializer
    public init (_ string: String, simplify: Bool = true) {

        let formattedExpression = Expression.formatExpression(string)
        self = Expression.createExpression(from: formattedExpression)
        if simplify {
            self = self.simplified()
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
        let functions = ["sqrt", "cbrt", "root", "log"]
        let anyOperator = "(?:" + Operator.allOperators.map { $0.rEsc() }.joined(separator: "|") + ")"
        let anyFunction = "(?:" + functions.map { $0.rEsc() }.joined(separator: "|") + ")"
        
        var str = String(string).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace other braces with parentheses
        do {
            let braceDict: [Character: String] = ["{" : "(", "[" : "(", "]" : ")", "}" : ")"]
            str = str.reduce("") { $0 + (braceDict[$1] ?? "\($1)") }
        }
        
        // Space binary operators
        do {
            str = str.replacingOccurrences(of: rOr(exactNumberRegex, "\\)") + anyOperator.rGroup() + rOr(exactNumberRegex, "(?:\\(|" + anyFunction + ")", group: .positiveLookbehind), with: "$1 $2 ", options: .regularExpression)
            
            
            str = str.replacingOccurrences(of: "(?<=[^\\s\\d])" + anyOperator.rGroup() + "(?=[^\\s\\d])", with: "$1 $2 $3", options: .regularExpression)
            
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
    
    public func simplified() -> Expression {
        return _simplified()
    }
    
    private func _simplified() -> Expression {
        
        switch self {
        // Number
        case .n:
            return self
            
        // Addition
        case let .add(lhs, rhs):
            
            let lhsSimplified = lhs._simplified()
            let rhsSimplified = rhs._simplified()
            
            switch (lhsSimplified, rhsSimplified) {
                
            // 0 + x = x
            case let (x, 0),
                 let (0, x):
                return x
                
            // x + (-x) = 0
            case let (.n(x), .n(y)) where x == -y:
                return .zero
                
            // x + (0 - x) = 0
            case let (x, .subtract(0, y)) where x == y,
                 let (.subtract(0, y), x) where x == y:
                return .zero
                
            // x + (y - x) = y
            case let (x1, .subtract(y, x2)) where x1 == x2,
                 let (.subtract(y, x1), x2) where x1 == x2:
                return y
                
                
            // a(x) + b(x) = (a + b)(x)
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                return Expression.multiply(.add(a, b), x1)._simplified()
                
            // x + ax = (a + 1)(x)
            case let (x1, .multiply(a, x2)) where x1 == x2,
                 let (x1, .multiply(x2, a)) where x1 == x2,
                 let (.multiply(a, x1), x2) where x1 == x2,
                 let (.multiply(x1, a), x2) where x1 == x2:
                if case let .n(value) = a {
                    return Expression.multiply(.n(value + 1), x1)._simplified()
                }
                return Expression.multiply(.add(a, .n(1)), x1)._simplified()
                
            // (a / x) + (b / x) = (a + b) / x
            case let (.divide(a, x1), .divide(b, x2)) where x1 == x2:
                return Expression.divide(.add(a, b), x1)._simplified()
                
            // (a / x) + (b / xy) = (ay + b) / x
            case let (.divide(a, x1), .divide(b, .multiply(y, x2))) where x1 == x2,
                 let (.divide(a, x1), .divide(b, .multiply(x2, y))) where x1 == x2,
                 let (.divide(b, .multiply(y, x1)), .divide(a, x2)) where x1 == x2,
                 let (.divide(b, .multiply(x1, y)), .divide(a, x2)) where x1 == x2:
                return Expression.divide(.add(.multiply(a, y), b), .multiply(x1, y))._simplified()
                
            // Add fractions with lcm
            case let (.divide(a, .n(x)), .divide(b, .n(y))):
                let d = lcm(x, y)
                return Expression.divide(.add(.multiply(a, .n(d / x)), .multiply(b, .n(d / y))), .n(d))._simplified()
                
            // a + (b / x) = (ax + b) / x
            case let (a, .divide(b, x)),
                 let (.divide(b, x), a):
                return Expression.divide(.add(.multiply(a, x), b), x)._simplified()
                
            // log<x>(a) + log<x>(b) = log<x>(ab)
            case let (.log(x, a), .log(y, b)) where x == y:
                return Expression.log(x, .multiply(a, b))._simplified()
                
            // a + b
            case let (.n(a), .n(b)):
                return .n(a + b)
                
            // no simplification
            case let (a, b):
                return .add(a, b)
            }
            
        // Subtraction
        case let .subtract(lhs, rhs):
            
            let lhsSimplified = lhs._simplified()
            let rhsSimplified = rhs._simplified()
            
            switch (lhsSimplified, rhsSimplified) {
                
            // x - 0 = x
            case let (x, 0):
                return x
                
            // x - x = 0
            case let (x, y) where x == y:
                return .n(0)
                
            // 0 - x = -x
            case let (0, .n(y)):
                return .n(-y)
                
            // x - (x + y) = -y
            // (x - y) - x = -y
            case let (x1, .add(x2, y))      where x1 == x2,
                 let (.subtract(x1, y), x2) where x1 == x2:
                if case let .n(value) = y { return .n(-value) }
                return .subtract(.n(0), y)
                
            // (x + y) - x = y
            // x - (x - y) = y
            case let (.add(x1, y), x2)      where x1 == x2,
                 let (x1, .subtract(x2, y)) where x1 == x2:
                return y
                
            // a(x) - b(x) = (a - b)(x)
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                return Expression.multiply(.subtract(a, b), x1)._simplified()
                
            // x - ax = (a + 1)(x)
            case let (x1, .multiply(a, x2)) where x1 == x2,
                 let (x1, .multiply(x2, a)) where x1 == x2:
                if case let .n(value) = a {
                    return Expression.multiply(.n(value + 1), x1)._simplified()
                }
                return Expression.multiply(.add(a, .n(1)), x1)._simplified()
                
            // ax - x = (a - 1)(x)
            case let (.multiply(a, x1), x2) where x1 == x2,
                 let (.multiply(x1, a), x2) where x1 == x2:
                if case let .n(value) = a {
                    return Expression.multiply(.n(value - 1), x1)._simplified()
                }
                return Expression.multiply(.subtract(a, .n(1)), x1)._simplified()
                
            // (a / x) - (b / x) = (a - b) / x
            case let (.divide(a, x1), .divide(b, x2)) where x1 == x2:
                return Expression.divide(.subtract(a, b), x1)._simplified()
                
            // (a / x) - (b / xy) = (ay - b) / x
            case let (.divide(a, x1), .divide(b, .multiply(y, x2))) where x1 == x2,
                 let (.divide(a, x1), .divide(b, .multiply(x2, y))) where x1 == x2:
                return Expression.divide(.subtract(.multiply(a, y), b), .multiply(x1, y))._simplified()
                
            // (a / xy) - (b / x) = (a - by) / x
            case let (.divide(a, .multiply(y, x1)), .divide(b, x2)) where x1 == x2,
                 let (.divide(a, .multiply(x1, y)), .divide(b, x2)) where x1 == x2:
                return Expression.divide(.subtract(a, .multiply(b, y)), .multiply(x1, y))._simplified()
                
            // Subtract fractions with lcm
            case let (.divide(a, .n(x)), .divide(b, .n(y))):
                let d = lcm(x, y)
                return Expression.divide(.subtract(.multiply(a, .n(d / x)), .multiply(b, .n(d / y))), .n(d))._simplified()
                
            // Subtract fractions with common denominator multiplicand and lcm
            case let (.divide(a, .multiply(g1, .n(b))), .divide(x, .multiply(g2, .n(y)))) where g1 == g2,
                 let (.divide(a, .multiply(g1, .n(b))), .divide(x, .multiply(.n(y), g2))) where g1 == g2,
                 let (.divide(a, .multiply(.n(b), g1)), .divide(x, .multiply(g2, .n(y)))) where g1 == g2,
                 let (.divide(a, .multiply(.n(b), g1)), .divide(x, .multiply(.n(y), g2))) where g1 == g2:
                let lcmBY = lcm(b, y)
                return ((a * .n(lcmBY / b) - (x * .n(lcmBY / y))) / (.n(lcmBY) * g1))._simplified()
                
            // log<x>(a) - log<x>(b) = log<x>(a / b)
            case let (.log(x, a), .log(y, b)) where x == y:
                return Expression.log(x, a / b)._simplified()
                
            // a - b
            case let (.n(a), .n(b)):
                return .n(a - b)
                
            // no simplification
            case let (a, b):
                return .subtract(a, b)
            }
            
        // Multiplication
        case let .multiply(lhs, rhs):
            
            let lhsSimplified = lhs._simplified()
            let rhsSimplified = rhs._simplified()
            
            switch (lhsSimplified, rhsSimplified) {
                
            // 0x = 0
            case (0, _), (_, 0):
                return .zero
                
            // 1x = x
            case let (x, 1), let (1, x):
                return x
                
            // -1x = -x
            case let (x, -1), let (-1, x):
                if case let .n(value) = x {
                    return .n(-value)
                }
                return 0 - x
                
            // x * x = x ^ 2
            case let (x, y) where x == y:
                return (x ^ 2)._simplified()
                
            // a * (b * x) = ab * x
            case let (.n(a), .multiply(.n(b), x)),
                 let (.n(a), .multiply(x, .n(b))),
                 let (.multiply(.n(a), x), .n(b)),
                 let (.multiply(x, .n(a)), .n(b)):
                return (.n(a * b) * x)
                
            // b * (a / b) = a
            case let (b1, .divide(a, b2)) where b1 == b2,
                 let (.divide(a, b1), b2) where b1 == b2:
                return a
                
            // x * (a / b) = ((x / GCD(x, b)) * a) / (b / GCD(x, b))
            case let (.n(x), .divide(a, .n(b))),
                 let (.divide(a, .n(b)), .n(x)):
                let gcdBX = lcm(b, x)
                return ((.n(x / gcdBX) * a) / .n(b / gcdBX))._simplified()
                
                
            // x * x ^ y = x ^ (y + 1)
            case let (x1, .power(x2, y)) where x1 == x2,
                 let (.power(x1, y), x2) where x1 == x2:
                if case let .n(value) = y {
                    return Expression.power(x1, .n(value + 1))._simplified()
                }
                return Expression.power(x1, .add(.n(1), y))._simplified()
                
            // (1 / y) * x = x / y
            case let (.divide(1, den), num),
                 let (num, .divide(1, den)):
                return (num /  den)._simplified()
                
            // (-1 / y) * x = x / y
            case let (.divide(-1, den), num),
                 let (num, .divide(-1, den)):
                if case let .n(x) = num {
                    return (.n(-x) / den)._simplified()
                } else if case let .n(y) = den {
                    return (num / .n(-y))._simplified()
                }
                return ((.zero - num) / den)._simplified()
                
            // (x / y) * (y / x) = 1
            case let (.divide(x1, y1), .divide(y2, x2)) where x1 == x2 && y1 == y2:
                return .n(1)
                
            // Cross reduction
            case let (.divide(.n(a), .n(b)), .divide(.n(x), .n(y))):
                let commonAY = gcd(a, y)
                let commonBX = gcd(b, x)
                return Expression.divide(.n((a / commonAY) * (x / commonBX)), .n((y / commonAY) * (b / commonBX)))._simplified()
                
            // Cross reduction
            case let (.divide(.n(a), b), .divide(x, .n(y))):
                let commonAY = gcd(a, y)
                return Expression.divide(.multiply(.n(a / commonAY), x), .multiply(.n(y / commonAY), b))._simplified()
                
            // Cross reduction
            case let (.divide(a, .n(b)), .divide(.n(x), y)):
                let commonBX = gcd(b, x)
                return Expression.divide(.multiply(a, .n(x / commonBX)), .multiply(y, .n(b / commonBX)))._simplified()
            
            // a * (x / y) = ax / y
            case let (a, .divide(x, y)),
                 let (.divide(x, y), a):
                return ((a * x) / y)._simplified()
                
            // x^a * x^b = x^(a + b)
            case let (.power(x1, a), .power(x2, b)) where x1 == x2:
                return Expression.power(x1, .add(a, b))._simplified()
                
            // x^a * px^b = px^(a + b)
            case let (.power(x1, a), .multiply(p, .power(x2, b))) where x1 == x2,
                 let (.power(x1, a), .multiply(.power(x2, b), p)) where x1 == x2,
                 let (.multiply(p, .power(x1, a)), .power(x2, b)) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .power(x2, b)) where x1 == x2:
                return (p * (x1 ^ (a + b)))._simplified()
           
            // px^a * qx^b = pqx^(a + b)
            case let (.multiply(p, .power(x1, a)), .multiply(q, .power(x2, b))) where x1 == x2,
                 let (.multiply(p, .power(x1, a)), .multiply(.power(x2, b), q)) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .multiply(q, .power(x2, b))) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .multiply(.power(x2, b), q)) where x1 == x2:
                return (p * q * (x1 ^ (a + b)))._simplified()
                
            // log<x>(a) * log<a>(y) = log<x>(y)
            case let (.log(x, a), .log(b, y)) where a == b:
                return Expression.log(x, y)._simplified()
                
            // a * b
            case let (.n(a), .n(b)):
                return .n(a * b)
                
            // no simplification
            case let (a, b):
                return .multiply(a, b)
            }
            
        // Division
        case let .divide(lhs, rhs):
            
            let lhsSimplified = lhs._simplified()
            let rhsSimplified = rhs._simplified()
            
            switch (lhsSimplified, rhsSimplified) {
            // x / 0 = NaN
            case (_, 0):
                fatalError("Division by zero")
                
            // 0 / x = 0
            case (0, _):
                return .zero
                
            // x / 1 = x
            case let (x, 1):
                return x
                
            // x / -1 = -x
            case let (x, -1):
                return -x
                
            // x / x = 1
            case let (x, y) where x == y:
                return .n(1)
                
            // (x * y) / x = y
            case let (.multiply(x1, y), x2) where x1 == x2,
                 let (.multiply(y, x1), x2) where x1 == x2:
                return y
                
            // x / (x / y) = y
            case let (x1, .divide(x2, y)) where x1 == x2:
                return y
                
            // (a / b) / c = a / bc
            case let (.divide(a, b), c):
                return (a / (b * c))._simplified()
                
            // a / (x / y) = a * (y / x)
            case let (a, .divide(x, y)):
                return Expression.multiply(a, .divide(y, x))._simplified()
                
            // ax / bx = a / b
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                return Expression.divide(a, b)._simplified()
                
            // x / (x * y) = 1 / y
            case let (x1, .multiply(x2, y)) where x1 == x2,
                 let (x1, .multiply(y, x2)) where x1 == x2:
                return .divide(.n(1), y)
                
            // (ax + bx) / x = a + b
            case let (.add(.multiply(a, x1), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3:
                return (a + b)._simplified()
                
            // (ax + bx) / cx = (a + b) / c
            case let (.add(.multiply(a, x1), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3:
                return ((a + b) / c)._simplified()

            // (ax - bx) / x = a - b
            case let (.subtract(.multiply(a, x1), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3:
                return (a - b)._simplified()
                
            // (ax - bx) / cx = (a - b) / c
            case let (.subtract(.multiply(a, x1), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3:
                return ((a - b) / c)._simplified()
                
            // x^y / x = x ^ (y - 1)
            case let (.power(x1, y), x2) where x1 == x2:
                return (x1 ^ (y - 1))._simplified()
                
            // x / x^y = x ^ (1 - y)
            case let (x1, .power(x2, y)) where x1 == x2:
                return (x1 ^ (1 - y))._simplified()
                
            // x^a / x^b = x^(a - b)
            case let (.power(x1, a), .power(x2, b)) where x1 == x2:
                return (x1 ^ (a - b))._simplified()
                
            // ax^y / x = ax^(y - 1)
            case let (.multiply(a, .power(x1, y)), x2) where x1 == x2,
                 let (.multiply(.power(x1, y), a), x2) where x1 == x2:
                return (a * x1 ^ (y - 1))._simplified()
                
            // x^y / ax = (1 / a) * x^(y - 1)
            case let (.power(x1, y), .multiply(a, x2)) where x1 == x2,
                 let (.power(x1, y), .multiply(x2, a)) where x1 == x2:
                return ((1 / a) * x1 ^ (y - 1))._simplified()
                
            // ax^y / bx = (a / b) * x^(y - 1)
            case let (.multiply(a, .power(x1, y)), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, .power(x1, y)), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(.power(x1, y), a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(.power(x1, y), a), .multiply(x2, b)) where x1 == x2:
                return ((a / b) * x1 ^ (y - 1))._simplified()
                
            // ax / x^y = ax^(1 - 1)
            case let (x1, .multiply(a, .power(x2, y))) where x1 == x2,
                 let (x1, .multiply(.power(x2, y), a)) where x1 == x2:
                return (a * x1 ^ (1 - y))._simplified()
                
            // x / ax^y = (1 / a) * x^(1 - y)
            case let (.multiply(a, x1), .power(x2, y)) where x1 == x2,
                 let (.multiply(x1, a), .power(x2, y)) where x1 == x2:
                return ((1 / a) * x1 ^ (1 - y))._simplified()
                
            // ax / bx^y = (a / b) * x^(1 - y)
            case let (.multiply(a, x1), .multiply(b, .power(x2, y))) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, .power(x2, y))) where x1 == x2,
                 let (.multiply(a, x1), .multiply(.power(x2, y), b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(.power(x2, y), b)) where x1 == x2:
                return ((a / b) * x1 ^ (1 - y))._simplified()
                
            // ax^g / x^h = ax^(g - h)
            case let (.power(x1, g), .multiply(a, .power(x2, h))) where x1 == x2,
                 let (.power(x1, g), .multiply(.power(x2, h), a)) where x1 == x2:
                return (a * x1 ^ (g - h))._simplified()
                
            // x^g / ax^h = (1 / a) * x^(g - h)
            case let (.multiply(a, .power(x1, g)), .power(x2, h)) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .power(x2, h)) where x1 == x2:
                return ((1 / a) * x1 ^ (g - h))._simplified()
                
            // ax^g / bx^h = (a / b) * x^(g - h)
            case let (.multiply(a, .power(x1, g)), .multiply(b, .power(x2, h))) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .multiply(b, .power(x2, h))) where x1 == x2,
                 let (.multiply(a, .power(x1, g)), .multiply(.power(x2, h), b)) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .multiply(.power(x2, h), b)) where x1 == x2:
                return ((a / b) * x1 ^ (g - h))._simplified()
               
            
                
            // 10 / 2 = 5
            case let (.n(x), .n(y)) where x % y == 0:
                return .n(x / y)
                
            // 10 / 5 = 1 / 2
            case let (.n(x), .n(y)):
                let a = gcd(x, y)
                let newX = x / a
                let newY = y / a
                
                if let powerY = newY.perfectPower() {
                    if newX == 1 {
                        return .power(.n(powerY.base), .n(-powerY.exponent))
                    }
                    let baseX = pow(Double(newX), 1.0 / Double(powerY.exponent))
                    
                    if baseX == floor(baseX) {
                        return .power(.divide(.n(Int(baseX)), .n(powerY.base)), .n(powerY.exponent))
                    }
                }
                return .divide(.n(x / a), .n(y / a))
                
            // log<x>(a) / log<x>(b) = log<b>(a)
            case let (.log(x, a), .log(y, b)) where x == y:
                return Expression.log(b, a)._simplified()
                
            // xlog<y>(a) / log<y>(b) = xlog<b>(a)
            case let (.multiply(x, .log(y1, a)), .log(y2, b)) where y1 == y2:
                return Expression.multiply(x, .log(b, a))._simplified()
                
            // log<y>(a) / xlog<y>(b) = (1 / x)log<b>(a)
            case let (.log(y1, a), .multiply(x, .log(y2, b))) where y1 == y2:
                return Expression.multiply(.divide(.n(1), x), .log(b, a))._simplified()
                
            // xlog<y>(a) / zlog<y>(b) = (x/z)log<b>(a)
            case let (.multiply(x1, .log(y1, a)), .multiply(x2, .log(y2, b))) where y1 == y2:
                return Expression.multiply(.divide(x1, x2), .log(b, a))._simplified()
                
            // x / log<a>(b) = xlog<b>(a)
            case let (x, .log(a, b)):
                return Expression.multiply(x, .log(b, a))._simplified()
                
            // no simplification
            case let (a, b):
                return .divide(a, b)
            }
            
        // Exponentiation
        case let .power(lhs, rhs):
            
            let lhsSimplified = lhs._simplified()
            let rhsSimplified = rhs._simplified()
            
            switch (lhsSimplified, rhsSimplified) {
                
            // 0 ^ 0
            case (0, 0):
                fatalError("0⁰ is not a number.")
                
            // x ^ 0 = 1
            case (_, 0):
                return .n(1)
                
            // 0 ^ x = 0
            case (0, _):
                return .n(0)
                
            // x ^ 1 = x
            case let (x, 1):
                return x
                
            // (x / y) ^ -e = (y / x) ^ e
            case let (.divide(x, y), .n(e)) where e < 0:
                return Expression.power(.divide(y, x), .n(-e))._simplified()
                
            // x ^ -e = 1 / (x ^ e)
            case let (x, .n(e)) where e < 0:
                return Expression.divide(.n(1), .power(x, .n(-e)))._simplified()
                
            // ˣ√(y) ^ x = y
            case let (.root(x1, y), x2) where x1 == x2:
                return y
                
            // x ^ logᵪy = y
            case let (x1, .log(x2, y)) where x1 == x2:
                return y
                
            // x ^ alogᵪy = y ^ a
            case let (x1, .multiply(a, .log(x2, y))) where x1 == x2:
                return .power(y, a)
                
            // (a ^ b) ^ c = a ^ bc
            case let (.power(a, b), c):
                return Expression.power(a, .multiply(b, c))._simplified()
                
            // Reduce power to lowest base
            case let (.n(x), y):
                if let perfectPower = x.perfectPower() {
                    return Expression.power(.n(perfectPower.base), .multiply(.n(perfectPower.exponent), y))._simplified()
                }
                return self
                
            // no simplification
            case let (a, b):
                return .power(a, b)
                
            }
            
        // Logarithms
        case let .log(lhs, rhs):
            let lhsSimplified = lhs._simplified()
            let rhsSimplified = rhs._simplified()
            
            switch (lhsSimplified, rhsSimplified) {
                
            // log<...1> = NaN
            case let (.n(x), _) where x < 2:
                fatalError("Cannot find the value of a log with an integral base less than 2")
                
            // logᵪ(x) = 1
            case let (x, y) where x == y:
                return .n(1)
                
            // log<ˣ√y>(y) = x
            // log<1 / ˣ√y>(1 / y) = x
            case let (.root(x, y1), y2) where y1 == y2,
                 let (.divide(1, .root(x, y1)), .divide(1, y2)) where y1 == y2:
                return x
                
            // log<1 / ˣ√y>(y) = -x
            // log<ˣ√y>(1 / y) = -x
            case let (.divide(1, .root(x, y1)), y2) where y1 == y2,
                 let (.root(x, y1), .divide(1, y2)) where y1 == y2:
                return -x
                
            // log<1/a>(1/b) = log<a>(b)
            case let (.divide(.n(1), a), .divide(.n(1), b)):
                return Expression.log(a, b)._simplified()
                
            // log<1/a>(b) = -log<a>(b)
            // log<a>(1/b) = -log<a>(b)
            case let (.divide(.n(1), a), b),
                 let (a, .divide(.n(1), b)):
                return Expression.subtract(.zero, .log(a, b))._simplified()
                
            // log<a^x>(b^x) = lob<a>(b)
            case let (.power(a, x1), .power(b, x2)) where x1 == x2:
                return Expression.log(a, b)._simplified()
                
            // log<a^y>(b^x) = (x / y) * lob<a>(b)
            case let (.power(a, x1), .power(b, x2)):
                return Expression.multiply(.divide(x2, x1), .log(a, b))._simplified()
                
            // log<b>(x^y) = ylog<b>(x)
            // log<root<y>(b)>(x) = ylog<b>(x)
            case let (b, .power(x, y)),
                 let (.root(y, b), x):
                return Expression.multiply(y, .log(b, x))._simplified()
                
            // log<b^y>(x) = (1/y) * log<b>(x)
            case let (.power(y, b), x):
                return Expression.multiply(.divide(.n(1), y), .log(b, x))._simplified()
             
            // log<4>(x) = ½log₂(x)
            case let (.n(x), y) where !y.isNumber:
                guard let perfectPower = x.perfectPower() else { return self }
                return Expression.multiply(.divide(.n(1), .n(perfectPower.exponent)), .log(.n(perfectPower.base), y))._simplified()
                
                
            // logᵪ(4) = 2logᵪ(2)
            case let (x, .n(y)) where !x.isNumber:
                guard let perfectPower = y.perfectPower() else { return self }
                return Expression.multiply(.n(perfectPower.exponent), .log(x, .n(perfectPower.base)))._simplified()
                
            // log₂₇(4) = ⅔log₃(2)
            case let (.n(x), .n(y)):
                let powerX = x.perfectPower()
                let powerY = y.perfectPower()
                switch (powerX, powerY) {
                case let (px?, py?):
                    if px.exponent == py.exponent {
                        return Expression.log(.n(px.base), .n(py.base))._simplified()
                    }
                    let a = gcd(px.exponent, py.exponent)
                    
                    if a == px.exponent {
                        return Expression.multiply(.n(py.exponent / a), .log(.n(px.base), .n(py.base)))._simplified()
                    }
                    return Expression.multiply(.divide(.n(py.exponent / a), .n(px.exponent / a)), .log(.n(px.base), .n(py.base)))._simplified()
                    
                case let (px?, _):
                    return Expression.multiply(.divide(.n(1), .n(px.exponent)), .log(.n(px.base), .n(y)))._simplified()
                    
                case let (_, py?):
                    return Expression.multiply(.n(py.exponent), .log(.n(x), .n(py.base)))._simplified()
                    
                default:
                    return self
                }
                
                
            // No simplification
            case let (a, b):
                return .log(a, b)
                
            }
            
        case let .root(lhs, rhs):
            let lhsSimplified = lhs._simplified()
            let rhsSimplified = rhs._simplified()
            
            switch (lhsSimplified, rhsSimplified) {
            // log<...1> = NaN
            case let (.n(x), _) where x < 2:
                fatalError("Cannot find the value of the nth root where n is less than 2")
                
            // √25 = 5
            case let (.n(x), .n(y)):
                let baseY = pow(Double(y), 1.0 / Double(x))
                if baseY == floor(baseY) {
                    return .n(Int(baseY))
                }
                return self
                
            // √(5^2) = 5
            case let (x1, .power(y, x2)) where x1 == x2:
                return y
                
                
            // no simplification
            case let (a, b):
                return .root(a, b)
                
            }
            
            
        }
        
        return self
    }
    
}



//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  Expression evaluation

public extension Expression {
    
    public func evaluate() -> Double {
        switch self {
        case let .add(a, b): return a.evaluate() + b.evaluate()
        case let .subtract(a, b): return a.evaluate() - b.evaluate()
        case let .multiply(a, b): return a.evaluate() * b.evaluate()
        case let .divide(a, b): return a.evaluate() / b.evaluate()
        case let .power(a, b): return pow(a.evaluate(), b.evaluate())
        case let .log(a, b): return log10(b.evaluate()) / log10(a.evaluate())
        case let .root(a, b):
            let x = a.evaluate()
            if x == 2 {
                return sqrt(b.evaluate())
            } else if x == 3 {
                return cbrt(b.evaluate())
            }
            return pow(b.evaluate(), 1.0 / a.evaluate())
        case let .n(a): return Double(a)
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
        default: return false
        }
    }
 
}


//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  Operators

public extension Expression {
    
    // Binary arithmetic operators
    public static func + (lhs: Expression, rhs: Expression) -> Expression {
        return Expression.add(lhs, rhs).simplified()
    }
    public static func - (lhs: Expression, rhs: Expression) -> Expression {
        return Expression.subtract(lhs, rhs).simplified()
    }
    public static func * (lhs: Expression, rhs: Expression) -> Expression {
        return Expression.multiply(lhs, rhs).simplified()
    }
    public static func / (lhs: Expression, rhs: Expression) -> Expression {
        return Expression.divide(lhs, rhs).simplified()
    }
    public static func ^ (lhs: Expression, rhs: Expression) -> Expression {
        return Expression.power(lhs, rhs).simplified()
    }
    
    // Compound assignment operators
    public static func += (lhs: inout Expression, rhs: Expression) {
        lhs = Expression.add(lhs, rhs).simplified()
    }
    public static func -= (lhs: inout Expression, rhs: Expression) {
        lhs = Expression.subtract(lhs, rhs).simplified()
    }
    public static func *= (lhs: inout Expression, rhs: Expression) {
        lhs = Expression.multiply(lhs, rhs).simplified()
    }
    public static func /= (lhs: inout Expression, rhs: Expression) {
        lhs = Expression.divide(lhs, rhs).simplified()
    }
    public static func ^= (lhs: inout Expression, rhs: Expression) {
        lhs = Expression.power(lhs, rhs).simplified()
    }
    
    // Prefix negative operator
    public static prefix func -(expression: Expression) -> Expression {
        if case let .n(x) = expression {
            return .n(-x)
        }
        return .subtract(.n(0), expression)
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
        case let (.add(a1, b1), .add(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.subtract(a1, b1), .subtract(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.multiply(a1, b1), .multiply(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.divide(a1, b1), .divide(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.power(a1, b1), .power(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.log(a1, b1), .log(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.root(a1, b1), .root(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.n(a), .n(b)): return a == b
        default: return false
        }
    }
}


//┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//┃ MARK: -  CustomStringConvertible Conformance

extension Expression: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case let .add(a, b):
            return "(" + a.description + " + " + b.description + ")"
        case let .subtract(.n(0), a):
            return "-" + a.description
        case let .subtract(a, b):
            return "(" + a.description + " - " + b.description + ")"
        case let .multiply(.n(a), b),
             let .multiply(b, .n(a)) where b.isLog || b.isRoot:
            return "\(a)" + b.description
            
        case let .multiply(a, b):
            return "(" + a.description + " * " + b.description + ")"
        case let .divide(a, b):
            return "(" + a.description + " / " + b.description + ")"
        case let .power(a, b):
            return "(" + a.description + " ^ " + b.description + ")"
        case let .log(base, n):
            var nStr = n.description
            if case .n = n { nStr = "(\(nStr))" }
            if case let .n(a) = base {
                let subscriptDict: [Character: String] = ["0" : "₀", "1" : "₁", "2" : "₂", "3" : "₃", "4" : "₄", "5" : "₅", "6" : "₆", "7" : "₇", "8" : "₈", "9" : "₉", "-" : "₋"]
                return "log" + "\(a)".reduce(into: "") { $0 += subscriptDict[$1]! } + nStr
            }
            
            return "log<" + base.description + ">" + nStr
                        
        case let .root(n, root):
            var rootStr = root.description
            if case .n = root { rootStr = "(\(rootStr))" }
            
            if case let .n(a) = n {
                switch a {
                case 2: return "√(" + root.description + ")"
                case 3: return "∛(" + root.description + ")"
                case 4: return "∜(" + root.description + ")"
                default:
                    let superscriptDict: [Character: String]  = ["0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",  "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "-": "⁻"]
                    
                    return "\(a)".reduce(into: "") { $0 += superscriptDict[$1]! } + "√" + rootStr
                }
            }
            return "root<" + n.description + ">" + rootStr

        case let .n(a):
            return "\(a)"
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
        }
    }
    
    public var latex: String {
        switch self {
        case let .add(a, b):
            return "\\left(" + a.latex + " + " + b.latex + "\\right)"
        case let .subtract(0, n):
            return "-" + n.latex
        case let .subtract(a, b):
            return "\\left(" + a.latex + ", " + b.latex + "\\right)"
        case let .multiply(a, b):
            return a.latex + "\\left(" + b.latex + "\\right)"
        case let .divide(a, b):
            return "\\frac{" + a.latex + "}{" + b.latex + "}"
        case let .power(a, b):
            return "\\left(" + a.latex + "\\right)^{" + b.latex + "}"
        case let .log(a, b):
            return "log_{" + a.latex + "}\\left(" + b.latex + "\\right)"
        case let .root(a, b):
            return "\\sqrt[" + a.latex + "]{" + b.latex + "}"
        case let .n(a):
            return "\(a)"
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


