//
//  Expression.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-25.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation


var i = 0


public enum Expression {
    indirect case add(Expression, Expression)
    indirect case subtract(Expression, Expression)
    indirect case multiply(Expression, Expression)
    indirect case divide(Expression, Expression)
    indirect case power(Expression, Expression)
    case n(Double)
    
    
//    func containsTermOnTopLevel(_ t: (Expression), matchNumber: Bool = true) -> Bool {
//        switch self {
//        case let .add(a, b)      where a == t || b == t,
//             let .subtract(a, b) where a == t || b == t,
//             let .multiply(a, b) where a == t || b == t,
//             let .divide(a, b)   where a == t || b == t,
//             let .power(a, b)    where a == t || b == t:
//            return true
//        case .n where matchNumber && self == t:
//            return true
//        default:
//            return false
//        }
//    }
   
    func contains(where predicate: (Expression) -> Bool) -> Bool {
        guard !predicate(self) else { return true }
        
        switch self {
        case let .add(a, b),
             let .subtract(a, b),
             let .multiply(a, b),
             let .divide(a, b),
             let .power(a, b):
            if predicate(a) || predicate(b) {
                return true
            } else {
                return a.contains(where: predicate) || b.contains(where: predicate)
            }
        default: return false
        }
    }
    func contains(_ expression: Expression) -> Bool {
        guard self != expression else { return true }
        
        switch self {
        case let .add(a, b),
             let .subtract(a, b),
             let .multiply(a, b),
             let .divide(a, b),
             let .power(a, b):
            if a == expression || b == expression {
                return true
            } else {
                return a.contains(expression) || b.contains(expression)
            }
        default: return false
        }
    }
    
    
    public init (_ string: String, simplify: Bool = true) {
        let eq = _Expression.from(string)
        self.init(eq)
        if simplify {
            self = self.simplified()
        }
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
    
    var isNaN: Bool {
        if case let .n(value) = self, value.isNaN {
            return true
        }
        return false
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
    
    public func simplified() -> Expression {
        return _simplified().expression
    }
    private func _simplified() -> (expression: Expression, didChange: Bool) {

        switch self {
            
        case .n: return (self, false)

        case .divide(_ , .n(0)), .power(.n(0), .n(0)):
            return (.n(Double.nan), true)
        case .add(.n(Double.nan), _), .add(_, .n(Double.nan)),
             .subtract(.n(Double.nan), _), .subtract(_, .n(Double.nan)),
             .multiply(.n(Double.nan), _), .multiply(_, .n(Double.nan)),
             .divide(.n(Double.nan), _), .divide(_, .n(Double.nan)),
             .power(.n(Double.nan), _), .power(_, .n(Double.nan)):
            return (.n(Double.nan), true)
            
        case .multiply(.n(0), _), .multiply(_, .n(0)), .divide(.n(0), _), .power(.n(0), _):
            return (.n(0), true)

        case let .subtract(a, b) where a == b:
            return (.n(0), true)

        case let .add(.n(a), .n(b)) where a == -b:
            return (.n(0), true)

        case let .multiply(t, .n(1)), let .multiply(.n(1), t),
             let .divide  (.n(1), t),
             let .add     (t, .n(0)), let .add     (.n(0), t),
             let .subtract(t, .n(0)),
             let .power   (t, .n(1)):
            return (t._simplified().expression, true)
            
        
        case let .subtract(.n(0), .n(value)):
            return (.n(-value), true)
            
        case .power(_, .n(0)), .power(.n(1), _):
            return (.n(1), true)
            
        case let .divide(a, b) where a == b && b._simplified().expression != .n(0):
            return (.n(1), true)

        case let .multiply(a, .divide(x, b)) where a == b,
             let .multiply(.divide(a, x), b) where a == b,
             let .divide(.multiply(a, x), b) where a == b,
             let .divide(.multiply(x, a), b) where a == b:
            return (x._simplified().expression, true)
            
        case let .add(.multiply(a1, b1), .multiply(a2, b2)) where b1 == b2,
             let .add(.multiply(b1, a1), .multiply(b2, a2)) where b1 == b2:
            return (Expression.multiply(.add(a1, a2), b1)._simplified().expression, true)
            
        case let .subtract(.multiply(a1, b1), .multiply(a2, b2)) where b1 == b2,
             let .subtract(.multiply(b1, a1), .multiply(b2, a2)) where b1 == b2:
            return (Expression.multiply(.subtract(a1, a2), b1)._simplified().expression, true)
            
        case let .divide(a, .multiply(x, b)) where a == b,
             let .divide(a, .multiply(b, x)) where a == b:
            return (Expression.divide(.n(1), x)._simplified().expression, true)

        // Default returns
        case let .add(a, b):
            var sa = a._simplified()
            var sb = b._simplified()
            if !sa.didChange && !sb.didChange {
                return (.add(a, b), false)
            } else {
                while sa.didChange {
                    sa = sa.expression._simplified()
                }
                while sb.didChange {
                    sb = sb.expression._simplified()
                }
                if sa.expression.isNaN || sb.expression.isNaN {
                    return (.n(Double.nan), true)
                }
                return (Expression.add(sa.expression, sb.expression)._simplified().expression, true)
            }
        case let .subtract(a, b):
            var sa = a._simplified()
            var sb = b._simplified()
            if !sa.didChange && !sb.didChange {
                return (.subtract(a, b), false)
            } else {
                while sa.didChange {
                    sa = sa.expression._simplified()
                }
                while sb.didChange {
                    sb = sb.expression._simplified()
                }
                if sa.expression.isNaN || sb.expression.isNaN {
                    return (.n(Double.nan), true)
                }
                return (Expression.subtract(sa.expression, sb.expression)._simplified().expression, true)
            }
        case let .multiply(a, b):
            var sa = a._simplified()
            var sb = b._simplified()
            if !sa.didChange && !sb.didChange {
                return (.multiply(a, b), false)
            } else {
                while sa.didChange {
                    sa = sa.expression._simplified()
                }
                while sb.didChange {
                    sb = sb.expression._simplified()
                }
                if sa.expression.isNaN || sb.expression.isNaN {
                    return (.n(Double.nan), true)
                }
                return (Expression.multiply(sa.expression, sb.expression)._simplified().expression, true)
            }
        case let .divide(a, b):
            var sa = a._simplified()
            var sb = b._simplified()
            if !sa.didChange && !sb.didChange {
                return (.divide(a, b), false)
            } else {
                while sa.didChange {
                    sa = sa.expression._simplified()
                }
                while sb.didChange {
                    sb = sb.expression._simplified()
                }
                if sa.expression.isNaN || sb.expression.isNaN {
                    return (.n(Double.nan), true)
                }
                return (Expression.divide(sa.expression, sb.expression)._simplified().expression, true)
            }
        case let .power(a, b):
            var sa = a._simplified()
            var sb = b._simplified()
            if !sa.didChange && !sb.didChange {
                return (.power(a, b), false)
            } else {
                while sa.didChange {
                    sa = sa.expression._simplified()
                }
                while sb.didChange {
                    sb = sb.expression._simplified()
                }
                if sa.expression.isNaN || sb.expression.isNaN {
                    return (.n(Double.nan), true)
                }
                return (Expression.power(sa.expression, sb.expression)._simplified().expression, true)
            }
        }
    }
}

extension Expression: Equatable {
    public static func == (lhs: Expression, rhs: Expression) -> Bool {
        switch (lhs, rhs) {
        case let (.add(a1, b1), .add(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.subtract(a1, b1), .subtract(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.multiply(a1, b1), .multiply(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.divide(a1, b1), .divide(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.power(a1, b1), .power(a2, b2)) where a1 == a2 && b1 == b2: return true
        case let (.n(a), .n(b)): return a == b
        default: return false
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

