//
//  Contains Methods.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

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
