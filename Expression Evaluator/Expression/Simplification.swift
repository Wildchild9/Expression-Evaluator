//
//  Simplification.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation


public extension Expression {
    public func simplified() -> Expression {
        switch self {
        // Variable
        case .x, .n:
            return self
            
        // Addition
        case let .add(lhs, rhs):
            
            switch (lhs.simplified(), rhs.simplified()) {
                
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
                return ((a + b) * x1).simplified()
                
            // x + ax = (a + 1)(x)
            case let (x1, .multiply(a, x2)) where x1 == x2,
                 let (x1, .multiply(x2, a)) where x1 == x2,
                 let (.multiply(a, x1), x2) where x1 == x2,
                 let (.multiply(x1, a), x2) where x1 == x2:
                if case let .n(value) = a {
                    return ((.n(value + 1) * x1)).simplified()
                }
                return ((a + 1) * x1).simplified()
                
            // (a / x) + (b / x) = (a + b) / x
            case let (.divide(a, x1), .divide(b, x2)) where x1 == x2:
                return ((a + b) / x1).simplified()
                
            // (a / x) + (b / xy) = (ay + b) / xy
            case let (.divide(a, x1), .divide(b, .multiply(y, x2))) where x1 == x2,
                 let (.divide(a, x1), .divide(b, .multiply(x2, y))) where x1 == x2,
                 let (.divide(b, .multiply(y, x1)), .divide(a, x2)) where x1 == x2,
                 let (.divide(b, .multiply(x1, y)), .divide(a, x2)) where x1 == x2:
                return ((a * y + b) / (x1 * y)).simplified()
                
            // Add fractions with lcm
            case let (.divide(a, .n(x)), .divide(b, .n(y))):
                let d = lcm(x, y)
                return ((a * .n(d / x) + b * .n(d / y)) / .n(d)).simplified()
                
            // a + (b / x) = (ax + b) / x
            case let (a, .divide(b, x)),
                 let (.divide(b, x), a):
                return ((a * x + b) / x).simplified()
                
            // log<x>(a) + log<x>(b) = log<x>(ab)
            case let (.log(x, a), .log(y, b)) where x == y:
                return (Expression.log(x, a * b)).simplified()
                
            // a + b
            case let (.n(a), .n(b)):
                return .n(a + b)
                
                
            // No simplification
            case let (a, b):
                return a + b
            }
            
        // Subtraction
        case let .subtract(lhs, rhs):
            
            switch (lhs.simplified(), rhs.simplified()) {
                
            // x - 0 = x
            case let (x, 0):
                return x
                
            // x - x = 0
            case let (x, y) where x == y:
                return .zero
                
            // 0 - x = -x
            case let (0, .n(y)):
                return .n(-y)
                
                // x - (x + y) = -y
            // (x - y) - x = -y
            case let (x1, .add(x2, y))      where x1 == x2,
                 let (x1, .add(y, x2))      where x1 == x2,
                 let (.subtract(x1, y), x2) where x1 == x2:
                return -y
                
                // (x + y) - x = y
            // x - (x - y) = y
            case let (.add(x1, y), x2)      where x1 == x2,
                 let (.add(y, x1), x2)      where x1 == x2,
                 let (x1, .subtract(x2, y)) where x1 == x2:
                return y
                
                //TODO: NEW
            // 0 - 0 - n
            case let (0, n) where n.isNegative:
                return -n
                
            // a(x) - b(x) = (a - b)(x)
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                return ((a - b) * x1).simplified()
                
            // x - ax = (a + 1)(x)
            case let (x1, .multiply(a, x2)) where x1 == x2,
                 let (x1, .multiply(x2, a)) where x1 == x2:
                if case let .n(value) = a {
                    return (.n(value + 1) * x1).simplified()
                }
                return ((a + 1) * x1).simplified()
                
            // ax - x = (a - 1)(x)
            case let (.multiply(a, x1), x2) where x1 == x2,
                 let (.multiply(x1, a), x2) where x1 == x2:
                if case let .n(value) = a {
                    return (.n(value - 1) * x1).simplified()
                }
                return ((a - 1) * x1).simplified()
                
            // (a / x) - (b / x) = (a - b) / x
            case let (.divide(a, x1), .divide(b, x2)) where x1 == x2:
                return ((a - b) / x1).simplified()
                
            // (a / x) - (b / xy) = (ay - b) / xy
            case let (.divide(a, x1), .divide(b, .multiply(y, x2))) where x1 == x2,
                 let (.divide(a, x1), .divide(b, .multiply(x2, y))) where x1 == x2:
                return ((a * y - b) / (x1 * y)).simplified()
                
            // (a / xy) - (b / x) = (a - by) / xy
            case let (.divide(a, .multiply(y, x1)), .divide(b, x2)) where x1 == x2,
                 let (.divide(a, .multiply(x1, y)), .divide(b, x2)) where x1 == x2:
                return ((a - b * y) / (x1 * y)).simplified()
                
            // Subtract fractions with lcm
            case let (.divide(a, .n(x)), .divide(b, .n(y))):
                let d = lcm(x, y)
                return ((a * .n(d / x) - b * .n(d / y)) / .n(d)).simplified()
                
            // Subtract fractions with common denominator multiplicand and lcm
            case let (.divide(a, .multiply(g1, .n(b))), .divide(x, .multiply(g2, .n(y)))) where g1 == g2,
                 let (.divide(a, .multiply(g1, .n(b))), .divide(x, .multiply(.n(y), g2))) where g1 == g2,
                 let (.divide(a, .multiply(.n(b), g1)), .divide(x, .multiply(g2, .n(y)))) where g1 == g2,
                 let (.divide(a, .multiply(.n(b), g1)), .divide(x, .multiply(.n(y), g2))) where g1 == g2:
                let lcmBY = lcm(b, y)
                return (((a * .n(lcmBY / b) - (x * .n(lcmBY / y))) / (.n(lcmBY) * g1))).simplified()
                
            // log<x>(a) - log<x>(b) = log<x>(a / b)
            case let (.log(x, a), .log(y, b)) where x == y:
                return (Expression.log(x, a / b)).simplified()
                
            // a - b
            case let (.n(a), .n(b)):
                return .n(a - b)
                
            // no simplification
            case let (a, b):
                return a - b
            }
            
        // Multiplication
        case let .multiply(lhs, rhs):
            
            switch (lhs.simplified(), rhs.simplified()) {
                
            // 0x = 0
            case (0, _), (_, 0):
                return .zero
                
            // 1x = x
            case let (x, 1), let (1, x):
                return x
                
            // -1x = -x
            case let (x, -1), let (-1, x):
                return -x
                
            // x * x = x ^ 2
            case let (x, y) where x == y:
                return (x ^ 2).simplified()
                
                
            // a * (b * x) = ab * x
            case let (.n(a), .multiply(.n(b), x)),
                 let (.n(a), .multiply(x, .n(b))),
                 let (.multiply(.n(a), x), .n(b)),
                 let (.multiply(x, .n(a)), .n(b)):
                return .n(a * b) * x
                
            // b * (a / b) = a
            case let (b1, .divide(a, b2)) where b1 == b2,
                 let (.divide(a, b1), b2) where b1 == b2:
                return a
                
            // x * (a / b) = ((x / GCD(x, b)) * a) / (b / GCD(x, b))
            case let (.n(x), .divide(a, .n(b))),
                 let (.divide(a, .n(b)), .n(x)):
                let gcdBX = gcd(b, x)
                return ((.n(x / gcdBX) * a) / .n(b / gcdBX)).simplified()
                
            // x * x ^ y = x ^ (y + 1)
            case let (x1, .power(x2, y)) where x1 == x2,
                 let (.power(x1, y), x2) where x1 == x2:
                if case let .n(value) = y {
                    return (x1 ^ .n(value + 1)).simplified()
                }
                return (x1 ^ (1 + y)).simplified()
                
                //            // TODO: New
                //            // a * (log<x>(y) / b) = (a / b) * log<x>(y)
                //            case let (a, .divide(.log(x, y), b)),
                //                 let (.divide(.log(x, y), b), a):
                //                return ((a / b) * .log(x, y))
                
            // (1 / y) * x = x / y
            case let (.divide(1, den), num),
                 let (num, .divide(1, den)):
                return ((num /  den)).simplified()
                
            // (-1 / y) * x = x / y
            case let (.divide(-1, den), num),
                 let (num, .divide(-1, den)):
                if case let .n(x) = num {
                    return (.n(-x) / den).simplified()
                } else if case let .n(y) = den {
                    return  (num / .n(-y)).simplified()
                } else {
                    return ((.zero - num) / den).simplified()
                }
                
                
            // (x / y) * (y / x) = 1
            case let (.divide(x1, y1), .divide(y2, x2)) where x1 == x2 && y1 == y2:
                return .n(1)
                
            // Cross reduction
            case let (.divide(.n(a), .n(b)), .divide(.n(x), .n(y))):
                let commonAY = gcd(a, y)
                let commonBX = gcd(b, x)
                return (.n((a / commonAY) * (x / commonBX)) / .n((y / commonAY) * (b / commonBX))).simplified()
                
            // Cross reduction
            case let (.divide(.n(a), b), .divide(x, .n(y))):
                let commonAY = gcd(a, y)
                return (((.n(a / commonAY) * x) / (.n(y / commonAY) * b))).simplified()
                
            // Cross reduction
            case let (.divide(a, .n(b)), .divide(.n(x), y)):
                let commonBX = gcd(b, x)
                return ((a * .n(x / commonBX)) / (y * .n(b / commonBX))).simplified()
                
            // a * (x / y) = ax / y
            case let (a, .divide(x, y)) where !a.isLog,
                 let (.divide(x, y), a) where !a.isLog:
                return ((a * x) / y).simplified()
                
            // x^a * x^b = x^(a + b)
            case let (.power(x1, a), .power(x2, b)) where x1 == x2:
                return (x1 ^ (a + b)).simplified()
                
            // x^a * px^b = px^(a + b)
            case let (.power(x1, a), .multiply(p, .power(x2, b))) where x1 == x2,
                 let (.power(x1, a), .multiply(.power(x2, b), p)) where x1 == x2,
                 let (.multiply(p, .power(x1, a)), .power(x2, b)) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .power(x2, b)) where x1 == x2:
                return (p * (x1 ^ (a + b))).simplified()
                
            // px^a * qx^b = pqx^(a + b)
            case let (.multiply(p, .power(x1, a)), .multiply(q, .power(x2, b))) where x1 == x2,
                 let (.multiply(p, .power(x1, a)), .multiply(.power(x2, b), q)) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .multiply(q, .power(x2, b))) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .multiply(.power(x2, b), q)) where x1 == x2:
                return (p * q * (x1 ^ (a + b))).simplified()
                
            // Combining powers
            case let (.n(a), .power(.n(b), c)),
                 let (.power(.n(b), c), .n(a)):
                
                guard let power = a.asPower(), power.base == b else {
                    return self
                }
                return (.n(b) ^ (.n(power.exponent) + c)).simplified()
                
                //            case let (a, .multiply(.divide(b, c), d)),
                //                 let (.multiply(.divide(b, c), d), a),
                //                 let (a, .multiply(d, .divide(b, c))),
                //                 let (.multiply(d, .divide(b, c)), a):
                //                return (((a * b) / c) * d).simplified()
                
            // TODO: NEW
            case let (x1, .multiply(x2, y)) where x1 == x2,
                 let (x1, .multiply(y, x2)) where x1 == x2,
                 let (.multiply(x2, y), x1) where x1 == x2,
                 let (.multiply(y, x2), x1) where x1 == x2:
                return y * x1 ^ 2
                
            // log<x>(a) * log<a>(y) = log<x>(y)
            case let (.log(x, a), .log(b, y)) where a == b:
                return (Expression.log(x, y)).simplified()
                
            // a * b
            case let (.n(a), .n(b)):
                return .n(a * b)
                
            // No simplification
            case let (a, b):
                return a * b
            }
            
        // Division
        case let .divide(lhs, rhs):
            
            switch (lhs.simplified(), rhs.simplified()) {
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
                return (a / (b * c)).simplified()
                
            // a / (x / y) = a * (y / x)
            case let (a, .divide(x, y)):
                return (a * (y / x)).simplified()
                
            // ax / bx = a / b
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                return (a / b).simplified()
                
            // x / (x * y) = 1 / y
            case let (x1, .multiply(x2, y)) where x1 == x2,
                 let (x1, .multiply(y, x2)) where x1 == x2:
                return 1 / y
                
            // (ax + bx) / x = a + b
            case let (.add(.multiply(a, x1), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3:
                return (a + b).simplified()
                
            // (ax + bx) / cx = (a + b) / c
            case let (.add(.multiply(a, x1), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3:
                return ((a + b) / c).simplified()
                
            // (ax - bx) / x = a - b
            case let (.subtract(.multiply(a, x1), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3:
                return (a - b).simplified()
                
            // (ax - bx) / cx = (a - b) / c
            case let (.subtract(.multiply(a, x1), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3:
                return ((a - b) / c).simplified()
                
            // x^y / x = x ^ (y - 1)
            case let (.power(x1, y), x2) where x1 == x2:
                return (x1 ^ (y - 1)).simplified()
                
            // x / x^y = x ^ (1 - y)
            case let (x1, .power(x2, y)) where x1 == x2:
                return (x1 ^ (1 - y)).simplified()
                
            // x^a / x^b = x^(a - b)
            case let (.power(x1, a), .power(x2, b)) where x1 == x2:
                return (x1 ^ (a - b)).simplified()
                
            // ax^y / x = ax^(y - 1)
            case let (.multiply(a, .power(x1, y)), x2) where x1 == x2,
                 let (.multiply(.power(x1, y), a), x2) where x1 == x2:
                return (a * x1 ^ (y - 1)).simplified()
                
            // x^y / ax = (1 / a) * x^(y - 1)
            case let (.power(x1, y), .multiply(a, x2)) where x1 == x2,
                 let (.power(x1, y), .multiply(x2, a)) where x1 == x2:
                return ((1 / a) * x1 ^ (y - 1)).simplified()
                
            // ax^y / bx = (a / b) * x^(y - 1)
            case let (.multiply(a, .power(x1, y)), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, .power(x1, y)), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(.power(x1, y), a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(.power(x1, y), a), .multiply(x2, b)) where x1 == x2:
                return ((a / b) * x1 ^ (y - 1)).simplified()
                
            // ax / x^y = ax^(1 - 1)
            case let (x1, .multiply(a, .power(x2, y))) where x1 == x2,
                 let (x1, .multiply(.power(x2, y), a)) where x1 == x2:
                return (a * x1 ^ (1 - y)).simplified()
                
            // x / ax^y = (1 / a) * x^(1 - y)
            case let (.multiply(a, x1), .power(x2, y)) where x1 == x2,
                 let (.multiply(x1, a), .power(x2, y)) where x1 == x2:
                return ((1 / a) * x1 ^ (1 - y)).simplified()
                
            // ax / bx^y = (a / b) * x^(1 - y)
            case let (.multiply(a, x1), .multiply(b, .power(x2, y))) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, .power(x2, y))) where x1 == x2,
                 let (.multiply(a, x1), .multiply(.power(x2, y), b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(.power(x2, y), b)) where x1 == x2:
                return ((a / b) * x1 ^ (1 - y)).simplified()
                
                
            // ax^g / x^h = ax^(g - h)
            case let (.power(x1, g), .multiply(a, .power(x2, h))) where x1 == x2,
                 let (.power(x1, g), .multiply(.power(x2, h), a)) where x1 == x2:
                return (a * x1 ^ (g - h)).simplified()
                
            // x^g / ax^h = (1 / a) * x^(g - h)
            case let (.multiply(a, .power(x1, g)), .power(x2, h)) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .power(x2, h)) where x1 == x2:
                return ((1 / a) * x1 ^ (g - h)).simplified()
                
            // ax^g / bx^h = (a / b) * x^(g - h)
            case let (.multiply(a, .power(x1, g)), .multiply(b, .power(x2, h))) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .multiply(b, .power(x2, h))) where x1 == x2,
                 let (.multiply(a, .power(x1, g)), .multiply(.power(x2, h), b)) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .multiply(.power(x2, h), b)) where x1 == x2:
                return ((a / b) * x1 ^ (g - h)).simplified()
                
            // Combining powers
            case let (.n(a), .power(.n(b), c)):
                guard let power = a.asPower(), power.base == b else {
                    return self
                }
                return (.n(b) ^ (.n(power.exponent) - c)).simplified()
                
            // Combining powers
            case let (.power(.n(b), c), .n(a)):
                guard let power = a.asPower(), power.base == b else {
                    return self
                }
                return (.n(b) ^ (c - .n(power.exponent))).simplified()
                
            // 10 / 2 = 5
            case let (.n(x), .n(y)) where x % y == 0:
                return .n(x / y)
                
            // 10 / 5 = 1 / 2
            case let (.n(x), .n(y)):
                let a = gcd(x, y)
                let newX = x / a
                let newY = y / a
                
                if let powerY = newY.asPower() {
                    if newX == 1 {
                        return .n(powerY.base) ^ .n(-powerY.exponent)
                    }
                    let baseX = pow(Double(newX), 1.0 / Double(powerY.exponent))
                    
                    if baseX == floor(baseX) {
                        return (.n(Int(baseX)) / .n(powerY.base)) ^ .n(powerY.exponent)
                    }
                }
                return .n(x / a) / .n(y / a)
                
            // log<x>(a) / log<x>(b) = log<b>(a)
            case let (.log(x, a), .log(y, b)) where x == y:
                return (Expression.log(b, a)).simplified()
                
            // xlog<y>(a) / log<y>(b) = xlog<b>(a)
            case let (.multiply(x, .log(y1, a)), .log(y2, b)) where y1 == y2:
                return (x * .log(b, a)).simplified()
                
            // log<y>(a) / xlog<y>(b) = (1 / x)log<b>(a)
            case let (.log(y1, a), .multiply(x, .log(y2, b))) where y1 == y2:
                return ((.n(1) / x) * .log(b, a)).simplified()
                
            // xlog<y>(a) / zlog<y>(b) = (x/z)log<b>(a)
            case let (.multiply(x1, .log(y1, a)), .multiply(x2, .log(y2, b))) where y1 == y2:
                return ((x1 / x2) * .log(b, a)).simplified()
                
                // TODO: new
            // (a * log<x>(y)) / b = (a / b) * log<x>(y)
            case let (.multiply(a, .log(x, y)), b),
                 let (.multiply(.log(x, y), a), b):
                return ((a / b) * .log(x, y)).simplified()
                
            // x / log<a>(b) = xlog<b>(a)
            case let (x, .log(a, b)):
                return (x * .log(b, a)).simplified()
                
            // No simplification
            case let (a, b):
                return a / b
            }
            
        // Exponentiation
        case let .power(lhs, rhs):
            
            switch (lhs.simplified(), rhs.simplified()) {
                
            // 0 ^ 0
            case (0, 0):
                fatalError("0⁰ is not a number.")
                
            // x ^ 0 = 1
            case (_, 0):
                return .n(1)
                
            // 0 ^ x = 0
            case (0, _):
                return .zero
                
            // x ^ 1 = x
            case let (x, 1):
                return x
                
            // (x / y) ^ -e = (y / x) ^ e
            case let (.divide(x, y), .n(e)) where e < 0:
                return ((y / x) ^ .n(-e)).simplified()
                
            // Not sure if this is a good simplification
            // a ^ -b = 1 / (a ^ b)
            case let (a, b) where b.isNegative:
                return (1 / (a ^ -b)).simplified()
                
            // ˣ√(y) ^ x = y
            case let (.root(x1, y), x2) where x1 == x2:
                return y
                
            // x ^ logᵪy = y
            case let (x1, .log(x2, y)) where x1 == x2:
                return y
                
            // x ^ alogᵪy = y ^ a
            case let (x1, .multiply(a, .log(x2, y))) where x1 == x2,
                 let (x1, .multiply(.log(x2, y), a)) where x1 == x2:
                return y ^ a
                
            // (a ^ b) ^ c = a ^ bc
            case let (.power(a, b), c):
                return (a ^ (b * c)).simplified()
                
            // Reduce power to lowest base
            case let (.n(x), y):
                if let perfectPower = x.asPower() {
                    return (.n(perfectPower.base) ^ (.n(perfectPower.exponent) * y)).simplified()
                    //return ((.n(perfectPower.base) ^ (.n(perfectPower.exponent) * y)._simplified()))
                }
                return self
                
            // No simplification
            case let (a, b):
                return a ^ b
                
            }
            
        // Logarithms
        case let .log(lhs, rhs):
            
            switch (lhs.simplified(), rhs.simplified()) {
                
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
                return (Expression.log(a, b)).simplified()
                
                // log<1/a>(b) = -log<a>(b)
            // log<a>(1/b) = -log<a>(b)
            case let (.divide(.n(1), a), b),
                 let (a, .divide(.n(1), b)):
                return (-(.log(a, b))).simplified()
                
            // log<a^x>(b^x) = lob<a>(b)
            case let (.power(a, x1), .power(b, x2)) where x1 == x2:
                return (Expression.log(a, b)).simplified()
                
            // log<a^y>(b^x) = (x / y) * lob<a>(b)
            case let (.power(a, x1), .power(b, x2)):
                return ((x2 / x1) * .log(a, b)).simplified()
                
                // log<b>(x^y) = ylog<b>(x)
            // log<root<y>(b)>(x) = ylog<b>(x)
            case let (b, .power(x, y)),
                 let (.root(y, b), x):
                return (y * .log(b, x)).simplified()
                
            // log<b^y>(x) = (1/y) * log<b>(x)
            case let (.power(y, b), x):
                return ((1 / y) * .log(b, x)).simplified()
                
            // log<x>(xy) = 1 + log<x>(y)
            case let (x1, .multiply(x2, y)) where x1 == x2,
                 let (x1, .multiply(y, x2)) where x1 == x2:
                return (1 + .log(x1, y)).simplified()
                
            // log<x>(x / y) = 1 - log<x>(y)
            case let (x1, .divide(x2, y)) where x1 == x2:
                return (1 - .log(x1, y)).simplified()
                
            // log<x>(x / y) = log<x>(y) - 1
            case let (x1, .divide(x2, y)) where x1 == x2:
                return (.log(x1, y) - 1).simplified()
                
            // log₂₇(4) = ⅔log₃(2)
            case let (.n(x), .n(y)):
                let powerX = x.asPower()
                let powerY = y.asPower()
                switch (powerX, powerY) {
                case let (px?, py?):
                    if px.exponent == py.exponent {
                        return (Expression.log(.n(px.base), .n(py.base))).simplified()
                    }
                    let a = gcd(px.exponent, py.exponent)
                    
                    if a == px.exponent {
                        return (.n(py.exponent / a) * .log(.n(px.base), .n(py.base))).simplified()
                    }
                    return ((.n(py.exponent / a) / .n(px.exponent / a)) * .log(.n(px.base), .n(py.base))).simplified()
                    
                case let (px?, _):
                    return ((1 / .n(px.exponent)) * .log(.n(px.base), .n(y))).simplified()
                    
                case let (_, py?):
                    return (.n(py.exponent) * .log(.n(x), .n(py.base))).simplified()
                    
                default:
                    return self
                }
            // log<4>(x) = ½log₂(x)
            case let (.n(x), y):
                guard let perfectPower = x.asPower() else { return self }
                let eq = ((1 / .n(perfectPower.exponent)) * .log(.n(perfectPower.base), y)).simplified()
                return y.isVariable ? eq : eq.simplified()
                
                
            // logᵪ(4) = 2logᵪ(2)
            case let (x, .n(y)):
                guard let perfectPower = y.asPower() else { return self }
                let eq = (.n(perfectPower.exponent) * .log(x, .n(perfectPower.base))).simplified()
                return x.isVariable ? eq : eq.simplified()
                
                
                
            // No simplification
            case let (a, b):
                return .log(a, b)
                
            }
            
        // Root
        case let .root(lhs, rhs):
            
            switch (lhs.simplified(), rhs.simplified()) {
            // log<...0> = NaN
            case let (.n(x), _) where x <= 0:
                fatalError("Cannot find the value of the nth root where n is less than 2")
                
            // ¹√x = x
            case let (1, x):
                return x
                
            // √25 = 5
            case let (.n(x), .n(y)):
                let baseY = pow(Double(y), 1.0 / Double(x))
                if baseY == floor(baseY) {
                    return .n(Int(baseY))
                }
                
            // √(5^2) = 5
            case let (x1, .power(y, x2)) where x1 == x2:
                return y
                
                
            // No simplification
            case let (a, b):
                return .root(a, b)
                
            }
        }
        return self
    }
}

