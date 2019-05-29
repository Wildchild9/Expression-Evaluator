//
//  Replacement Methods.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

public extension Expression {
    func replacingX(with value: Int) -> Expression {
        var replacedExpression = self
        replacedExpression.replaceX(with: value)
        return replacedExpression
    }
    func replacingX(with expression: Expression) -> Expression {
        var replacedExpression = self
        replacedExpression.replaceX(with: expression)
        return replacedExpression
    }
    func replacingOccurrences(of target: Expression, with replacement: Expression) -> Expression {
        var replacedExpression = self
        replacedExpression.replaceOccurrences(of: target, with: replacement)
        return replacedExpression
    }
    
    
    @discardableResult mutating func replaceX(with value: Int) -> Expression {
        return replaceX(with: .n(value))
    }
    @discardableResult mutating func replaceX(with expression: Expression) -> Expression {
        switch self {
        case var .add(a, b):
            a = a.replaceX(with: expression)
            b = b.replaceX(with: expression)
            self = .add(a, b)
        case var .subtract(a, b):
            a = a.replaceX(with: expression)
            b = b.replaceX(with: expression)
            self = .subtract(a, b)
        case var .multiply(a, b):
            a = a.replaceX(with: expression)
            b = b.replaceX(with: expression)
            self = .multiply(a, b)
        case var .divide(a, b):
            a = a.replaceX(with: expression)
            b = b.replaceX(with: expression)
            self = .divide(a, b)
        case var .power(a, b):
            a = a.replaceX(with: expression)
            b = b.replaceX(with: expression)
            self = .power(a, b)
        case var .log(a, b):
            a = a.replaceX(with: expression)
            b = b.replaceX(with: expression)
            self = .log(a, b)
        case var .root(a, b):
            a = a.replaceX(with: expression)
            b = b.replaceX(with: expression)
            self = .root(a, b)
        case .n: break
        case .x: self = expression
        }
        return self
    }

    @discardableResult mutating func replaceOccurrences(of target: Expression, with replacement: Expression) -> Expression {
        switch self {
        case target: self = replacement
        case var .add(a, b):
            a.replaceOccurrences(of: target, with: replacement)
            b.replaceOccurrences(of: target, with: replacement)
            self = .add(a, b)
        case var .subtract(a, b):
            a.replaceOccurrences(of: target, with: replacement)
            b.replaceOccurrences(of: target, with: replacement)
            self = .subtract(a, b)
        case var .multiply(a, b):
            a.replaceOccurrences(of: target, with: replacement)
            b.replaceOccurrences(of: target, with: replacement)
            self = .multiply(a, b)
        case var .divide(a, b):
            a.replaceOccurrences(of: target, with: replacement)
            b.replaceOccurrences(of: target, with: replacement)
            self = .divide(a, b)
        case var .power(a, b):
            a.replaceOccurrences(of: target, with: replacement)
            b.replaceOccurrences(of: target, with: replacement)
            self = .power(a, b)
        case var .log(a, b):
            a.replaceOccurrences(of: target, with: replacement)
            b.replaceOccurrences(of: target, with: replacement)
            self = .log(a, b)
        case var .root(a, b):
            a.replaceOccurrences(of: target, with: replacement)
            b.replaceOccurrences(of: target, with: replacement)
            self = .root(a, b)
        case .n, .x: break
        }
        
        return self
    }
    
    
    
}
