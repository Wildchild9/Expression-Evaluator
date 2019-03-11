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
            
            
            str = str.replacingOccurrences(of: "(?<=[^xX\\s\\d])" + anyOperator.rGroup() + "(?=[^xX\\s\\d])", with: "$1 $2 $3", options: .regularExpression)
            
        }
        
        // Replace adjacent variable mutiplication with star operator
        do {
            str = str.regex.replacing(pattern: "(?<=[^\\<\\+\\s\\(-])(x|X)", with: " * x")
            str = str.regex.replacing(pattern: "(x|X)(?=[^\\s\\>\\)])", with: "x * ")
        }
        
        // Replace parenthetic multiplication with star operator
        do {
            let parentheticMultiplicationPattern = rOr("(?<!log|root)(\(exactNumberRegex))\\s*(?=\\(|\(anyFunction)", "(\\))\\s*(?=\(exactNumberRegex))", "(\\))\\s*(?=\\(|\(anyFunction)", group: .none)
            
            str = str.replacingOccurrences(of: parentheticMultiplicationPattern, with: "$1$2$3 * ", options: .regularExpression)
            
            str = str.replacingOccurrences(of: "(?<=\\)|\\d|x|X)(\\()", with: " * (", options: .regularExpression)
            str = str.replacingOccurrences(of: "(\\))(?=\\(|\\w)", with: ") * ", options: .regularExpression)

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
            str = str.replacingOccurrences(of: "-(\\(|x|X)", with: "0 - $1", options: .regularExpression)
        }
        
        // Remove prefix positive operator
        do {
            
            if let firstCharacter = str.first, firstCharacter == "+" {
                str.removeFirst()
            }
            
            str = str.replacingOccurrences(of: "(?<=[\\s\\(])\\+(?=[^\\)\\s])", with: "", options: .regularExpression)
        }
        
        str = str.replacingOccurrences(of: "\\([\\s\\)\\(]*\\)", with: "")
        
        print(str)
        return str
        
    }
    
}

