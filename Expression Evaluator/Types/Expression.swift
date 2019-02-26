//
//  Expression.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-25.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation




public enum Expression {
    indirect case add(Expression, Expression)
    indirect case subtract(Expression, Expression)
    indirect case multiply(Expression, Expression)
    indirect case divide(Expression, Expression)
    indirect case power(Expression, Expression)
    case n(Double)
    
    
    public init (_ string: String) {
        let eq = _Expression.from(string)
        self.init(eq)
    }
    private init (_ exp: _Expression) {
        switch exp {
        case let .add(a, b): self = .add(Expression(a), Expression(b))
        case let .subtract(a, b): self = .subtract(Expression(a), Expression(b))
        case let .multiply(a, b): self = .multiply(Expression(a), Expression(b))
        case let .divide(a, b): self = .divide(Expression(a), Expression(b))
        case let .power(a, b): self = .power(Expression(a), Expression(b))
        case let .n(a): self = .n(a)
        default: fatalError("Cannot convert equation")
        }
    }
    
    public func evaluate() -> Double {
        switch self {
        case let .add(a, b): return a.evaluate() + b.evaluate()
        case let .subtract(a, b): return a.evaluate() - b.evaluate()
        case let .multiply(a, b): return a.evaluate() * b.evaluate()
        case let .divide(a, b): return a.evaluate() / b.evaluate()
        case let .power(a, b): return pow(a.evaluate(), b.evaluate())
        case let .n(a): return a
        }
    }
}

extension Expression: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .add(a, b):
            return "(" + a.description + " + " + b.description + ")"
        case let .subtract(a, b):
            return "(" + a.description + " - " + b.description + ")"
        case let .multiply(a, b):
            return "(" + a.description + " * " + b.description + ")"
        case let .divide(a, b):
            return "(" + a.description + " / " + b.description + ")"
        case let .power(a, b):
            return "(" + a.description + " ^ " + b.description + ")"
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
        case let .n(a):
            return ".n(\(a))"
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


private enum _Expression {
    indirect case add(_Expression, _Expression)
    indirect case subtract(_Expression, _Expression)
    indirect case multiply(_Expression, _Expression)
    indirect case divide(_Expression, _Expression)
    indirect case power(_Expression, _Expression)
    case `operator`(Operator)
    case n(Double)
    
    var isPower: Bool {
        if case .power(_, _) = self {
            return true
        }
        return false
    }
    
    private enum Associativity {
        case left, right
    }
    
    private static func operation(between a: _Expression, and b: _Expression, with operation: Operator) -> _Expression {
        switch operation {
        case .addition: return .add(a, b)
        case .subtraction: return .subtract(a, b)
        case .multiplication: return .multiply(a, b)
        case .division: return .divide(a, b)
        case .exponentiation: return .power(a, b)
        }
    }
    
    private static func level2terms<T: StringProtocol>(from str: T, level: [Parentheses]) -> [Substring] where T.SubSequence == Substring {
        guard !level.isEmpty else {
            let leadingSpaceCount = str.leadingCount(of: " ")
            let trailingSpaceCount = str.trailingCount(of: " ")
            let trimmedSection = str[str.index(str.startIndex, offsetBy: leadingSpaceCount)..<str.index(str.endIndex, offsetBy: -trailingSpaceCount)]
            
            return trimmedSection.split(separator: " ")
        }
        var arr = [(contents: Substring, isParentheses: Bool)]()
        var currentIndex = str.startIndex
        var currentParenthesesIndex = 0
        while currentIndex < str.endIndex {
            let firstIndexOfParentheses = str[currentIndex...].firstIndex(of: "(") ?? str.endIndex
            let nonParenthesesSubstring = str[currentIndex..<firstIndexOfParentheses]
            if !nonParenthesesSubstring.isEmpty {
                arr.append((contents: nonParenthesesSubstring, isParentheses: false))
            }
            
            guard firstIndexOfParentheses != str.endIndex else { break }
            
            let currentParentheses = level[currentParenthesesIndex]
            arr.append((contents: currentParentheses.contents, isParentheses: true))
            
            currentIndex = currentParentheses.endIndex
            currentParenthesesIndex += 1
        }
        
        let equationArr = arr.reduce(into: [Substring]()) { runningArr, section in
            guard !section.isParentheses else {
                runningArr.append(section.contents)
                return
            }
            let leadingSpaceCount = section.contents.leadingCount(of: " ")
            let trailingSpaceCount = section.contents.trailingCount(of: " ")
            let trimmedSection = str[section.contents.index(section.contents.startIndex, offsetBy: leadingSpaceCount)..<section.contents.index(section.contents.endIndex, offsetBy: -trailingSpaceCount)]
            
            runningArr.append(contentsOf: trimmedSection.split(separator: " "))
        }
        return equationArr
    }
    
    private static func terms2expression(_ arr: [Substring]) -> _Expression {
        guard arr.count > 0 else { fatalError() }
        guard arr.count > 1 else { return .n(Double(String(arr[0]))!) }
        guard arr.count % 2 == 1 else { fatalError("Invalid format") }
        
        let operators = Operator.allOperators
        
        var operatorArr: [Operator] = [Operator]()
        var termArr = [Substring]()
        operatorArr.reserveCapacity(arr.count / 2)
        termArr.reserveCapacity(arr.count / 2 + 1)
        
        var equationArr = [_Expression]()

        
        arr.forEach {
            if let op = Operator($0) {
                operatorArr.append(op)
                equationArr.append(.operator(op))
            } else {
                termArr.append($0)
                equationArr.append(term(from: $0))
            }
        }
        
        
        
        func incorporate(operations: Operator..., associativity: Associativity = .left) {
            let operators: [(index: Int, `operator`: Operator)] = Array(equationArr.lazy
                .filter {
                    if case .operator(_) = $0 { return true }
                    else { return false }
                }
                .enumerated()
                .map {
                    guard case let .operator(op) = $0.element else { fatalError() }
                    return (index: $0.offset * 2 + 1, operator: op)
                }
            )
            if associativity == .left {
                var combinationOffset = 0
                
                for (index, `operator`) in operators where operations.contains(`operator`) {
                    let a = equationArr[index - 1 - combinationOffset]
                    let b = equationArr[index + 1 - combinationOffset]
                    
                    let replacementOperation = _Expression.operation(between: a, and: b, with: `operator`)

                    equationArr[(index - 1 - combinationOffset)...(index + 1 - combinationOffset)] = [replacementOperation]
                    combinationOffset += 2
                }
            } else {
                for (index, `operator`) in operators.reversed() where operations.contains(`operator`) {
                    let a = equationArr[index - 1]
                    let b = equationArr[index + 1]
                    
                    let replacementOperation = _Expression.operation(between: a, and: b, with: `operator`)
                    
                    equationArr[(index - 1)...(index + 1)] = [replacementOperation]
                }
            }
        }
        
        guard equationArr.count > 1 else { return equationArr.first! }

        incorporate(operations: .exponentiation, associativity: .right)
        
        guard equationArr.count > 1 else { return equationArr.first! }

        incorporate(operations: .multiplication, .division)
        
        guard equationArr.count > 1 else { return equationArr.first! }
        
        incorporate(operations: .addition, .subtraction)
        
        guard equationArr.count == 1 else { fatalError() }
        
        return equationArr[0]
    }
    
    static func term(from term: Substring) -> _Expression {
        if let first = term.first, first == "(" {
            let parentheses = Parentheses(depth: 0, number: 0, contents: term)
            let expressionInParentheses = _Expression.from(parentheses.contentsWithoutParentheses)
            return expressionInParentheses
        } else {
            guard let value = Double(String(term)) else { fatalError("Invalid format") }
            return .n(value)
        }
    }
    static func from<T: StringProtocol>(_ str: T) -> _Expression {
        
        guard !str.isEmpty else { return .n(0) }
        
        let str = applyFormatting(to: str)
        let parentheses = extractParentheses(in: str).filter { $0.depth == 1 }
        let termArr = level2terms(from: str, level: parentheses)
        
        //  print(termArr)
        let expression = terms2expression(termArr)
        
        
        return expression
    }
}
extension _Expression: CustomStringConvertible {
    var description: String {
        switch self {
        case let .add(a, b):
            return "(" + a.description + " + " + b.description + ")"
        case let .subtract(a, b):
            return "(" + a.description + " - " + b.description + ")"
        case let .multiply(a, b):
            return "(" + a.description + " * " + b.description + ")"
        case let .divide(a, b):
            return "(" + a.description + " / " + b.description + ")"
        case let .power(a, b):
            return "(" + a.description + " ^ " + b.description + ")"
        case let .`operator`(a):
            return " " + a.description + " "
        case let .n(a):
            return "\(a)"
        }
    }
    var literalDescription: String {
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
        case let .`operator`(a):
            return ".operator(\(a.description))"
        case let .n(a):
            return ".n(\(a))"
        }
    }
}


fileprivate extension Array where Element == NSTextCheckingResult {
    fileprivate func captureGroups(in str: String) -> [(range: Range<String.Index>, captureGroups: [String])] {
        var captureGroups = [(range: Range<String.Index>, captureGroups: [String])]()
        captureGroups.reserveCapacity(count)
        
        for match in self {
            var captures = [String]()
            captures.reserveCapacity(match.numberOfRanges - 1)
            for captureGroup in 1..<match.numberOfRanges where match.range(at: captureGroup).lowerBound != NSNotFound {
                let range = match.range(at: captureGroup)
                captures.append(String(str[Range(range, in: str)!]))
            }
            
            captureGroups.append((range: Range(match.range, in: str)!, captureGroups: captures))
        }
        return captureGroups
    }
}
