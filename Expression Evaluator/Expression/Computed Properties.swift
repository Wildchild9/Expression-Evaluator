//
//  Computed Properties.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

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
