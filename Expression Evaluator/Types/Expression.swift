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
    var isZero: Bool {
        if case let .n(value) = self, value.isZero {
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
        return _simplified2() // _simplified().expression
    }
    private func _simplified() -> (expression: Expression, didChange: Bool) {

        var `self` = self
        
        if case let .divide(a, b) = self {
            let aSimplified = a._simplified().expression
            let bSimplified = b._simplified().expression
            if bSimplified.isZero || bSimplified.isNaN || aSimplified.isNaN {
                return (.n(.nan), true)
            }
            self = .divide(a._simplified().expression, bSimplified)
        } else if case let .power(a, b) = self {
            let aSimplified = a._simplified().expression
            let bSimplified = b._simplified().expression
            if (aSimplified.isZero && bSimplified.isZero) || aSimplified.isNaN || bSimplified.isNaN {
                return (.n(.nan), true)
            }
            self = .power(aSimplified, bSimplified)
        }
        
        
        switch self {
            
        case .n: return (self, false)

        case .divide(_ , .n(0)), .power(.n(0), .n(0)):
            return (.n(.nan), true)
        
        case .add(.n(.nan), _), .add(_, .n(.nan)),
             .subtract(.n(.nan), _), .subtract(_, .n(.nan)),
             .multiply(.n(.nan), _), .multiply(_, .n(.nan)),
             .divide(.n(.nan), _), .divide(_, .n(.nan)),
             .power(.n(.nan), _), .power(_, .n(.nan)):
            return (.n(.nan), true)
            
        case .multiply(.n(0), _), .multiply(_, .n(0)), .divide(.n(0), _), .power(.n(0), _):
            return (.n(0), true)

        case let .subtract(a, b) where a == b:
            return (.n(0), true)

        case let .add(.n(a), .n(b)) where a == -b:
            return (.n(0), true)

        case let .multiply(t, .n(1)), let .multiply(.n(1), t),
             let .divide  (t, .n(1)),
             let .add     (t, .n(0)), let .add     (.n(0), t),
             let .subtract(t, .n(0)),
             let .power   (t, .n(1)):
            return (t._simplified().expression, true)
            
        
        case let .subtract(.n(0), .n(value)):
            return (.n(-value), true)
            
        case let .multiply(a, .power(b, .n(x))) where a == b,
             let .multiply(.power(a, .n(x)), b) where a == b:
            return (.power(a, .n(x + 1)), true)
            
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
                    return (.n(.nan), true)
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
                    return (.n(.nan), true)
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
                    return (.n(.nan), true)
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
                    return (.n(.nan), true)
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
                    return (.n(.nan), true)
                }
                return (Expression.power(sa.expression, sb.expression)._simplified().expression, true)
            }
        }
    }
    private func _simplified2() -> Expression {
        switch self {
        // Number
        case .n:
            return self
            
        // Addition
        case let .add(lhs, rhs):
            
            let lhsSimplified = lhs._simplified2()
            let rhsSimplified = rhs._simplified2()
            
            switch (lhsSimplified, rhsSimplified) {
            // NaN + x = NaN
            case let (x, _) where x.isNaN,
                 let (_, x) where x.isNaN:
                return .n(.nan)
                
            // 0 + x = x
            case let (x, y) where y.isZero,
                 let (y, x) where y.isZero:
                return x
                
            // x + (-x) = 0
            case let (.n(x), .n(y)) where x == -y:
                return .n(0)
                
            // x + (y - x) = y
            case let (x1, .subtract(y, x2)) where x1 == x2,
                 let (.subtract(y, x1), x2) where x1 == x2:
                return y
                
            // a(x) + b(x) = (a + b)(x)
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                return Expression.multiply(.add(a, b), x1)._simplified2()
                
            // no simplification
            case let (a, b):
                return .add(a, b)
            }
            
        // Subtraction
        case let .subtract(lhs, rhs):
            
            let lhsSimplified = lhs._simplified2()
            let rhsSimplified = rhs._simplified2()
            
            switch (lhsSimplified, rhsSimplified) {
            // NaN - x = NaN
            case let (x, _) where x.isNaN,
                 let (_, x) where x.isNaN:
                return .n(.nan)
                
            // x - 0 = x
            case let (x, y) where y.isZero:
                return x
                
            // x + (-x) = 0
            case let (x, y) where x == y:
                return .n(0)
                
            // 0 - x = -x
            case let (x, .n(y)) where x.isZero:
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
                return Expression.multiply(.subtract(a, b), x1)._simplified2()
                
            // no simplification
            case let (a, b):
                return .subtract(a, b)
            }
            
        // Multiplication
        case let .multiply(lhs, rhs):
            
            let lhsSimplified = lhs._simplified2()
            let rhsSimplified = rhs._simplified2()
            
            switch (lhsSimplified, rhsSimplified) {
            // NaN * x = NaN
            case let (x, _) where x.isNaN,
                 let (_, x) where x.isNaN:
                return .n(.nan)
                
            // 0x = 0
            case let (x, _) where x.isZero,
                 let (_, x) where x.isZero:
                return .n(0)
                
            // 1x = x
            case let (x, 1), let (1, x):
                return x
                
            // -1x = x
            case let (.n(x), -1), let (-1, .n(x)):
                return .n(-x)
                
            // x * x = x ^ 2
            case let (x, y) where x == y:
                return .power(x, .n(2))
                
            // x * (y / x) = y
            case let (x1, .divide(y, x2)) where x1 == x2,
                 let (.divide(y, x1), x2) where x1 == x2:
                return y
                
            // x * x ^ y = x ^ (y + 1)
            case let (x1, .power(x2, y)) where x1 == x2,
                 let (.power(x1, y), x2) where x1 == x2:
                if case let .n(value) = y {
                    return Expression.power(x1, .n(value + 1))._simplified2()
                }
                return Expression.power(x1, .add(.n(1), y))._simplified2()
                
            // (1 / x) * y = y / x
            case let (.divide(1, den), num),
                 let (num, .divide(1, den)):
                return Expression.divide(num, den)._simplified2()
                
            // (-1 / x) * y = y / x
            case let (.divide(-1, den), num),
                 let (num, .divide(-1, den)):
                if case let .n(x) = num {
                    return Expression.divide(.n(-x), den)._simplified2()
                } else if case let .n(y) = den {
                    return Expression.divide(num, .n(-y))._simplified2()
                }
                return Expression.divide(.subtract(.n(0), num), den)._simplified2()

            // (x / y) * (y / x) = 1
            case let (.divide(x1, y1), .divide(x2, y2)) where x1 == x2 && y1 == y2:
                 return .n(1)
                
            // no simplification
            case let (a, b):
                return .multiply(a, b)
            }
            
        // Division
        case let .divide(lhs, rhs):
            
            let lhsSimplified = lhs._simplified2()
            let rhsSimplified = rhs._simplified2()
            
            switch (lhsSimplified, rhsSimplified) {
            // NaN / x = NaN
            // x / 0 = NaN
            case let (x, _) where x.isNaN,
                 let (_, x) where x.isNaN || x.isZero:
                return .n(.nan)
              
            // 0 / x = x
            case let (x, _) where x.isZero:
                return .n(0)
                
            // x / 1 = x
            case let (x, 1):
                return x
                
            // x /- 1 = x
            case let (.n(x), -1):
                return .n(-x)
                
            // x / x = 1
            case let (x, y) where x == y:
                return .n(1)
                
            // (x * y) / x = y
            case let (.multiply(x1, y), x2) where x1 == x2,
                 let (.multiply(y, x1), x2) where x1 == x2:
                return y
                
            // x / (x * y) = 1 / y
            case let (x1, .multiply(x2, y)) where x1 == x2,
                 let (x1, .multiply(y, x2)) where x1 == x2:
                return .divide(.n(1), y)
                
            // no simplification
            case let (a, b):
                return .divide(a, b)
            }
            
        case let .power(lhs, rhs):
            
            let lhsSimplified = lhs._simplified2()
            let rhsSimplified = rhs._simplified2()
            
            switch (lhsSimplified, rhsSimplified) {
            // NaN ^ x = NaN
            case let (x, _) where x.isNaN,
                 let (_, x) where x.isNaN:
                return .n(.nan)
                
            // 0 ^ 0
            case let (x, y) where x.isZero && y.isZero:
                return .n(.nan)
                
            // x ^ 0 = 1
            case let (_, x) where x.isZero:
                return .n(1)
                
            // 0 ^ x = 0
            case let (x, _) where x.isZero:
                return .n(0)
                
            // x ^ 1 = x
            case let (x, 1):
                return x
                
            // (x / y) ^ -e = (y / x) ^ e
            case let (.divide(x, y), .n(e)) where e < 0:
                return Expression.power(.divide(y, x), .n(-e))._simplified2()
                
            // x ^ -e = 1 / x ^ e
            case let (x, .n(e)) where e < 0:
                return Expression.divide(.n(1), .power(x, .n(-e)))._simplified2()
                
            // no simplification
            case let (a, b):
                return .power(a, b)
            }
        }
    }
}
public extension Expression {
    public static func ~= (lhs: Double, rhs: Expression) -> Bool {
        if case let .n(x) = rhs, x == lhs {
            return true
        }
        return false
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

