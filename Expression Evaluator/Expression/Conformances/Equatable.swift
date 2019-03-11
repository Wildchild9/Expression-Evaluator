//
//  Equatable.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation


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
