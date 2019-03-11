//
//  Operators.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation




///////
//MARK: - Binary Arithmetic Operators
public extension Expression {
    
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
    
}


///////
//MARK: - Compound Assignment Operators
public extension Expression {

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
}


///////
//MARK: - Prefix Negative Operator
public extension Expression {
    
    public static prefix func -(expression: Expression) -> Expression {
        var negativeExpression = expression
        negativeExpression.negate()
        return negativeExpression
    }
    
    public mutating func negate() {
        if case let .n(x) = expression {
            self = .n(-x)
        } else if case let .subtract(0, x) = expression {
            self = x
        } else {
            self = .subtract(.zero, expression)
        }
    }
    
}


///////
//MARK: - Pattern Matching with Integers
public extension Expression {
    public static func ~= (lhs: Int, rhs: Expression) -> Bool {
        if case let .n(x) = rhs, x == lhs {
            return true
        }
        return false
    }
}


///////
//MARK: - Exponentiation Operator Precedence
precedencegroup ExponentiationPrecedence {
    higherThan: MultiplicationPrecedence
    lowerThan: BitwiseShiftPrecedence
    associativity: right
}
infix operator ^: ExponentiationPrecedence


