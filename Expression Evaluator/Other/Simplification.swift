//
//  Simplification.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-08.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation


public extension Expression {
    public mutating func simplify2() {
        switch self {
        // Variable
        case .x, .n:
            return
            
        // Addition
        case var .add(lhs, rhs):
            
            lhs.simplify2()
            rhs.simplify2()
            
            self = lhs + rhs
            
            switch (lhs, rhs) {
                
            // 0 + x = x
            case let (x, 0),
                 let (0, x):
                self = x
                
            // x + (-x) = 0
            case let (.n(x), .n(y)) where x == -y:
                self = .zero
                
            // x + (0 - x) = 0
            case let (x, .subtract(0, y)) where x == y,
                 let (.subtract(0, y), x) where x == y:
                self = .zero
                
            // x + (y - x) = y
            case let (x1, .subtract(y, x2)) where x1 == x2,
                 let (.subtract(y, x1), x2) where x1 == x2:
                self = y
                
                
            // a(x) + b(x) = (a + b)(x)
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                self = (a + b) * x1
                simplify2()
                
            // x + ax = (a + 1)(x)
            case let (x1, .multiply(a, x2)) where x1 == x2,
                 let (x1, .multiply(x2, a)) where x1 == x2,
                 let (.multiply(a, x1), x2) where x1 == x2,
                 let (.multiply(x1, a), x2) where x1 == x2:
                if case let .n(value) = a {
                    self = (.n(value + 1) * x1)
                    simplify2()
                    return
                }
                self = (a + 1) * x1
                simplify2()
                
            // (a / x) + (b / x) = (a + b) / x
            case let (.divide(a, x1), .divide(b, x2)) where x1 == x2:
                self = (a + b) / x1
                simplify2()
                
            // (a / x) + (b / xy) = (ay + b) / xy
            case let (.divide(a, x1), .divide(b, .multiply(y, x2))) where x1 == x2,
                 let (.divide(a, x1), .divide(b, .multiply(x2, y))) where x1 == x2,
                 let (.divide(b, .multiply(y, x1)), .divide(a, x2)) where x1 == x2,
                 let (.divide(b, .multiply(x1, y)), .divide(a, x2)) where x1 == x2:
                self = (a * y + b) / (x1 * y)
                simplify2()
                
            // Add fractions with lcm
            case let (.divide(a, .n(x)), .divide(b, .n(y))):
                let d = lcm(x, y)
                self = (a * .n(d / x) + b * .n(d / y)) / .n(d)
                simplify2()
                
            // a + (b / x) = (ax + b) / x
            case let (a, .divide(b, x)),
                 let (.divide(b, x), a):
                self = (a * x + b) / x
                simplify2()
                
            // log<x>(a) + log<x>(b) = log<x>(ab)
            case let (.log(x, a), .log(y, b)) where x == y:
                self = .log(x, a * b)
                simplify2()
                
            // a + b
            case let (.n(a), .n(b)):
                self = .n(a + b)
                
                
            // No simplification
            default:
                return
            }
            
        // Subtraction
        case var .subtract(lhs, rhs):
            
            lhs.simplify2()
            rhs.simplify2()
            
            self = lhs - rhs
            
            switch (lhs, rhs) {
                
            // x - 0 = x
            case let (x, 0):
                self = x
                
            // x - x = 0
            case let (x, y) where x == y:
                self = .zero
                
            // 0 - x = -x
            case let (0, .n(y)):
                self = .n(-y)
                
                // x - (x + y) = -y
            // (x - y) - x = -y
            case let (x1, .add(x2, y))      where x1 == x2,
                 let (x1, .add(y, x2))      where x1 == x2,
                 let (.subtract(x1, y), x2) where x1 == x2:
                self = -y
                
                // (x + y) - x = y
            // x - (x - y) = y
            case let (.add(x1, y), x2)      where x1 == x2,
                 let (.add(y, x1), x2)      where x1 == x2,
                 let (x1, .subtract(x2, y)) where x1 == x2:
                self = y
                
            // a(x) - b(x) = (a - b)(x)
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                self = (a - b) * x1
                simplify2()
                
            // x - ax = (a + 1)(x)
            case let (x1, .multiply(a, x2)) where x1 == x2,
                 let (x1, .multiply(x2, a)) where x1 == x2:
                if case let .n(value) = a {
                    self = .n(value + 1) * x1
                    simplify2()
                    return
                }
                self = (a + 1) * x1
                simplify2()
                
            // ax - x = (a - 1)(x)
            case let (.multiply(a, x1), x2) where x1 == x2,
                 let (.multiply(x1, a), x2) where x1 == x2:
                if case let .n(value) = a {
                    self = .n(value - 1) * x1
                    simplify2()
                    return
                }
                self = (a - 1) * x1
                simplify2()
                
            // (a / x) - (b / x) = (a - b) / x
            case let (.divide(a, x1), .divide(b, x2)) where x1 == x2:
                self = (a - b) / x1
                simplify2()
                
            // (a / x) - (b / xy) = (ay - b) / xy
            case let (.divide(a, x1), .divide(b, .multiply(y, x2))) where x1 == x2,
                 let (.divide(a, x1), .divide(b, .multiply(x2, y))) where x1 == x2:
                self = (a * y - b) / (x1 * y)
                simplify2()
                
            // (a / xy) - (b / x) = (a - by) / xy
            case let (.divide(a, .multiply(y, x1)), .divide(b, x2)) where x1 == x2,
                 let (.divide(a, .multiply(x1, y)), .divide(b, x2)) where x1 == x2:
                self = (a - b * y) / (x1 * y)
                simplify2()
                
            // Subtract fractions with lcm
            case let (.divide(a, .n(x)), .divide(b, .n(y))):
                let d = lcm(x, y)
                self = (a * .n(d / x) - b * .n(d / y)) / .n(d)
                simplify2()
                
            // Subtract fractions with common denominator multiplicand and lcm
            case let (.divide(a, .multiply(g1, .n(b))), .divide(x, .multiply(g2, .n(y)))) where g1 == g2,
                 let (.divide(a, .multiply(g1, .n(b))), .divide(x, .multiply(.n(y), g2))) where g1 == g2,
                 let (.divide(a, .multiply(.n(b), g1)), .divide(x, .multiply(g2, .n(y)))) where g1 == g2,
                 let (.divide(a, .multiply(.n(b), g1)), .divide(x, .multiply(.n(y), g2))) where g1 == g2:
                let lcmBY = lcm(b, y)
                self = ((a * .n(lcmBY / b) - (x * .n(lcmBY / y))) / (.n(lcmBY) * g1))
                simplify2()
                
            // log<x>(a) - log<x>(b) = log<x>(a / b)
            case let (.log(x, a), .log(y, b)) where x == y:
                self = .log(x, a / b)
                simplify2()
                
            // a - b
            case let (.n(a), .n(b)):
                self = .n(a - b)
                
            // no simplification
            default:
                return
            }
            
        // Multiplication
        case var .multiply(lhs, rhs):
            
            lhs.simplify2()
            rhs.simplify2()
            
            self = lhs * rhs
            
            switch (lhs, rhs) {
                
            // 0x = 0
            case (0, _), (_, 0):
                self = .zero
                
            // 1x = x
            case let (x, 1), let (1, x):
                self = x
                
            // -1x = -x
            case let (x, -1), let (-1, x):
                self = -x
                
            // x * x = x ^ 2
            case let (x, y) where x == y:
                self = x ^ 2
                simplify2()
                
                
            // a * (b * x) = ab * x
            case let (.n(a), .multiply(.n(b), x)),
                 let (.n(a), .multiply(x, .n(b))),
                 let (.multiply(.n(a), x), .n(b)),
                 let (.multiply(x, .n(a)), .n(b)):
                self = .n(a * b) * x
                
            // b * (a / b) = a
            case let (b1, .divide(a, b2)) where b1 == b2,
                 let (.divide(a, b1), b2) where b1 == b2:
                self = a
                
            // x * (a / b) = ((x / GCD(x, b)) * a) / (b / GCD(x, b))
            case let (.n(x), .divide(a, .n(b))),
                 let (.divide(a, .n(b)), .n(x)):
                let gcdBX = gcd(b, x)
                self = (.n(x / gcdBX) * a) / .n(b / gcdBX)
                simplify2()
                
            // x * x ^ y = x ^ (y + 1)
            case let (x1, .power(x2, y)) where x1 == x2,
                 let (.power(x1, y), x2) where x1 == x2:
                if case let .n(value) = y {
                    self = x1 ^ .n(value + 1)
                    simplify2()
                    return
                }
                self = x1 ^ (1 + y)
                simplify2()
                
                //            // TODO: Record addition
                //            // a * (log<x>(y) / b) = (a / b) * log<x>(y)
                //            case let (a, .divide(.log(x, y), b)),
                //                 let (.divide(.log(x, y), b), a):
                //                self = (a / b) * .log(x, y)
                //                simplify2()
                
            // (1 / y) * x = x / y
            case let (.divide(1, den), num),
                 let (num, .divide(1, den)):
                self = (num /  den)
                simplify2()
                
            // (-1 / y) * x = x / y
            case let (.divide(-1, den), num),
                 let (num, .divide(-1, den)):
                if case let .n(x) = num {
                    self = (.n(-x) / den)
                } else if case let .n(y) = den {
                    self =  (num / .n(-y))
                } else {
                    self = ((.zero - num) / den)
                }
                simplify2()
                
            // (x / y) * (y / x) = 1
            case let (.divide(x1, y1), .divide(y2, x2)) where x1 == x2 && y1 == y2:
                self = .n(1)
                
            // Cross reduction
            case let (.divide(.n(a), .n(b)), .divide(.n(x), .n(y))):
                let commonAY = gcd(a, y)
                let commonBX = gcd(b, x)
                self = .n((a / commonAY) * (x / commonBX)) / .n((y / commonAY) * (b / commonBX))
                simplify2()
                
            // Cross reduction
            case let (.divide(.n(a), b), .divide(x, .n(y))):
                let commonAY = gcd(a, y)
                self = ((.n(a / commonAY) * x) / (.n(y / commonAY) * b))
                simplify2()
                
            // Cross reduction
            case let (.divide(a, .n(b)), .divide(.n(x), y)):
                let commonBX = gcd(b, x)
                self = (a * .n(x / commonBX)) / (y * .n(b / commonBX))
                simplify2()
                
            // a * (x / y) = ax / y
            case let (a, .divide(x, y)),
                 let (.divide(x, y), a):
                self = (a * x) / y
                simplify2()
                
            // x^a * x^b = x^(a + b)
            case let (.power(x1, a), .power(x2, b)) where x1 == x2:
                self = x1 ^ (a + b)
                simplify2()
                
            // x^a * px^b = px^(a + b)
            case let (.power(x1, a), .multiply(p, .power(x2, b))) where x1 == x2,
                 let (.power(x1, a), .multiply(.power(x2, b), p)) where x1 == x2,
                 let (.multiply(p, .power(x1, a)), .power(x2, b)) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .power(x2, b)) where x1 == x2:
                self = p * (x1 ^ (a + b))
                simplify2()
                
            // px^a * qx^b = pqx^(a + b)
            case let (.multiply(p, .power(x1, a)), .multiply(q, .power(x2, b))) where x1 == x2,
                 let (.multiply(p, .power(x1, a)), .multiply(.power(x2, b), q)) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .multiply(q, .power(x2, b))) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .multiply(.power(x2, b), q)) where x1 == x2:
                self = p * q * (x1 ^ (a + b))
                simplify2()
                
            // Combining powers
            case let (.n(a), .power(.n(b), c)),
                 let (.power(.n(b), c), .n(a)):
                
                guard let power = a.asPower(), power.base == b else {
                    return
                }
                self = .n(b) ^ (.n(power.exponent) + c)
                simplify2()
                
                
                
            // log<x>(a) * log<a>(y) = log<x>(y)
            case let (.log(x, a), .log(b, y)) where a == b:
                self = .log(x, y)
                simplify2()
                
            // a * b
            case let (.n(a), .n(b)):
                self = .n(a * b)
                
            // No simplification
            default:
                return
            }
            
        // Division
        case var .divide(lhs, rhs):
            
            lhs.simplify2()
            rhs.simplify2()
            
            switch (lhs, rhs) {
            // x / 0 = NaN
            case (_, 0):
                fatalError("Division by zero")
                
            // 0 / x = 0
            case (0, _):
                self = .zero
                
            // x / 1 = x
            case let (x, 1):
                self = x
                
            // x / -1 = -x
            case let (x, -1):
                self = -x
                
            // x / x = 1
            case let (x, y) where x == y:
                self = .n(1)
                
            // (x * y) / x = y
            case let (.multiply(x1, y), x2) where x1 == x2,
                 let (.multiply(y, x1), x2) where x1 == x2:
                self = y
                
            // x / (x / y) = y
            case let (x1, .divide(x2, y)) where x1 == x2:
                self = y
                
            // (a / b) / c = a / bc
            case let (.divide(a, b), c):
                self = a / (b * c)
                simplify2()
                
            // a / (x / y) = a * (y / x)
            case let (a, .divide(x, y)):
                self = a * (y / x)
                simplify2()
                
            // ax / bx = a / b
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                self = a / b
                simplify2()
                
            // x / (x * y) = 1 / y
            case let (x1, .multiply(x2, y)) where x1 == x2,
                 let (x1, .multiply(y, x2)) where x1 == x2:
                self = 1 / y
                
            // (ax + bx) / x = a + b
            case let (.add(.multiply(a, x1), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3:
                self = a + b
                simplify2()
                
            // (ax + bx) / cx = (a + b) / c
            case let (.add(.multiply(a, x1), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3:
                self = (a + b) / c
                simplify2()
                
            // (ax - bx) / x = a - b
            case let (.subtract(.multiply(a, x1), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3:
                self = a - b
                simplify2()
                
            // (ax - bx) / cx = (a - b) / c
            case let (.subtract(.multiply(a, x1), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), .multiply(c, x3)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), .multiply(x3, c)) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), .multiply(x3, c)) where x1 == x2 && x2 == x3:
                self = (a - b) / c
                simplify2()
                
            // x^y / x = x ^ (y - 1)
            case let (.power(x1, y), x2) where x1 == x2:
                self = x1 ^ (y - 1)
                simplify2()
                
            // x / x^y = x ^ (1 - y)
            case let (x1, .power(x2, y)) where x1 == x2:
                self = x1 ^ (1 - y)
                simplify2()
                
            // x^a / x^b = x^(a - b)
            case let (.power(x1, a), .power(x2, b)) where x1 == x2:
                self = x1 ^ (a - b)
                simplify2()
                
            // ax^y / x = ax^(y - 1)
            case let (.multiply(a, .power(x1, y)), x2) where x1 == x2,
                 let (.multiply(.power(x1, y), a), x2) where x1 == x2:
                self = a * x1 ^ (y - 1)
                simplify2()
                
            // x^y / ax = (1 / a) * x^(y - 1)
            case let (.power(x1, y), .multiply(a, x2)) where x1 == x2,
                 let (.power(x1, y), .multiply(x2, a)) where x1 == x2:
                self = (1 / a) * x1 ^ (y - 1)
                simplify2()
                
            // ax^y / bx = (a / b) * x^(y - 1)
            case let (.multiply(a, .power(x1, y)), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, .power(x1, y)), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(.power(x1, y), a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(.power(x1, y), a), .multiply(x2, b)) where x1 == x2:
                self = (a / b) * x1 ^ (y - 1)
                simplify2()
                
            // ax / x^y = ax^(1 - 1)
            case let (x1, .multiply(a, .power(x2, y))) where x1 == x2,
                 let (x1, .multiply(.power(x2, y), a)) where x1 == x2:
                self = a * x1 ^ (1 - y)
                simplify2()
                
            // x / ax^y = (1 / a) * x^(1 - y)
            case let (.multiply(a, x1), .power(x2, y)) where x1 == x2,
                 let (.multiply(x1, a), .power(x2, y)) where x1 == x2:
                self = (1 / a) * x1 ^ (1 - y)
                simplify2()
                
            // ax / bx^y = (a / b) * x^(1 - y)
            case let (.multiply(a, x1), .multiply(b, .power(x2, y))) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, .power(x2, y))) where x1 == x2,
                 let (.multiply(a, x1), .multiply(.power(x2, y), b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(.power(x2, y), b)) where x1 == x2:
                self = (a / b) * x1 ^ (1 - y)
                simplify2()
                
                
            // ax^g / x^h = ax^(g - h)
            case let (.power(x1, g), .multiply(a, .power(x2, h))) where x1 == x2,
                 let (.power(x1, g), .multiply(.power(x2, h), a)) where x1 == x2:
                self = a * x1 ^ (g - h)
                simplify2()
                
            // x^g / ax^h = (1 / a) * x^(g - h)
            case let (.multiply(a, .power(x1, g)), .power(x2, h)) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .power(x2, h)) where x1 == x2:
                self = (1 / a) * x1 ^ (g - h)
                simplify2()
                
            // ax^g / bx^h = (a / b) * x^(g - h)
            case let (.multiply(a, .power(x1, g)), .multiply(b, .power(x2, h))) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .multiply(b, .power(x2, h))) where x1 == x2,
                 let (.multiply(a, .power(x1, g)), .multiply(.power(x2, h), b)) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .multiply(.power(x2, h), b)) where x1 == x2:
                self = (a / b) * x1 ^ (g - h)
                simplify2()
                
            // Combining powers
            case let (.n(a), .power(.n(b), c)):
                guard let power = a.asPower(), power.base == b else {
                    return
                }
                self = .n(b) ^ (.n(power.exponent) - c)
                simplify2()
                
            // Combining powers
            case let (.power(.n(b), c), .n(a)):
                guard let power = a.asPower(), power.base == b else {
                    return
                }
                self = .n(b) ^ (c - .n(power.exponent))
                simplify2()
                
            // 10 / 2 = 5
            case let (.n(x), .n(y)) where x % y == 0:
                self = .n(x / y)
                
            // 10 / 5 = 1 / 2
            case let (.n(x), .n(y)):
                let a = gcd(x, y)
                let newX = x / a
                let newY = y / a
                
                if let powerY = newY.asPower() {
                    if newX == 1 {
                        self = .n(powerY.base) ^ .n(-powerY.exponent)
                        return
                    }
                    let baseX = pow(Double(newX), 1.0 / Double(powerY.exponent))
                    
                    if baseX == floor(baseX) {
                        self = (.n(Int(baseX)) / .n(powerY.base)) ^ .n(powerY.exponent)
                        return
                    }
                }
                self = .n(x / a) / .n(y / a)
                
            // log<x>(a) / log<x>(b) = log<b>(a)
            case let (.log(x, a), .log(y, b)) where x == y:
                self = .log(b, a)
                simplify2()
                
            // xlog<y>(a) / log<y>(b) = xlog<b>(a)
            case let (.multiply(x, .log(y1, a)), .log(y2, b)) where y1 == y2:
                self = x * .log(b, a)
                simplify2()
                
            // log<y>(a) / xlog<y>(b) = (1 / x)log<b>(a)
            case let (.log(y1, a), .multiply(x, .log(y2, b))) where y1 == y2:
                self = (.n(1) / x) * .log(b, a)
                simplify2()
                
            // xlog<y>(a) / zlog<y>(b) = (x/z)log<b>(a)
            case let (.multiply(x1, .log(y1, a)), .multiply(x2, .log(y2, b))) where y1 == y2:
                self = (x1 / x2) * .log(b, a)
                simplify2()
                
                //            // (a * log<x>(y)) / b = (a / b) * log<x>(y)
                //            case let (.multiply(a, .log(x, y)), b),
                //                 let (.multiply(.log(x, y), a), b):
                //                self = (a / b) * .log(x, y)
                //                simplify2()
                
            // x / log<a>(b) = xlog<b>(a)
            case let (x, .log(a, b)):
                self = x * .log(b, a)
                simplify2()
                
            // No simplification
            default:
                return
            }
            
        // Exponentiation
        case var .power(lhs, rhs):
            
            lhs.simplify2()
            rhs.simplify2()
            
            self = lhs ^ rhs
            
            switch (lhs, rhs) {
                
            // 0 ^ 0
            case (0, 0):
                fatalError("0⁰ is not a number.")
                
            // x ^ 0 = 1
            case (_, 0):
                self = .n(1)
                
            // 0 ^ x = 0
            case (0, _):
                self = .zero
                
            // x ^ 1 = x
            case let (x, 1):
                self = x
                
            // (x / y) ^ -e = (y / x) ^ e
            case let (.divide(x, y), .n(e)) where e < 0:
                self = (y / x) ^ .n(-e)
                simplify2()
                
                // Not sure if this is a good simplification
            // a ^ -b = 1 / (a ^ b)
            case let (a, b) where b.isNegative:
                self = 1 / (a ^ -b)
                simplify2()
                
            // ˣ√(y) ^ x = y
            case let (.root(x1, y), x2) where x1 == x2:
                self = y
                
            // x ^ logᵪy = y
            case let (x1, .log(x2, y)) where x1 == x2:
                self = y
                
            // x ^ alogᵪy = y ^ a
            case let (x1, .multiply(a, .log(x2, y))) where x1 == x2,
                 let (x1, .multiply(.log(x2, y), a)) where x1 == x2:
                self = y ^ a
                
                
                
            // (a ^ b) ^ c = a ^ bc
            case let (.power(a, b), c):
                self = a ^ (b * c)
                simplify2()
                
            // Reduce power to lowest base
            case let (.n(x), y):
                if let perfectPower = x.asPower() {
                    self = .n(perfectPower.base) ^ (.n(perfectPower.exponent) * y)
                    simplify2()
                    //self = (.n(perfectPower.base) ^ (.n(perfectPower.exponent) * y)._simplified())
                }
                return
                
            // No simplification
            default:
                return
                
            }
            
        // Logarithms
        case var .log(lhs, rhs):
            
            lhs.simplify2()
            rhs.simplify2()
            
            self = .log(lhs, rhs)
            
            switch (lhs, rhs) {
                
            // log<...1> = NaN
            case let (.n(x), _) where x < 2:
                fatalError("Cannot find the value of a log with an integral base less than 2")
                
            // logᵪ(x) = 1
            case let (x, y) where x == y:
                self = .n(1)
                
                // log<ˣ√y>(y) = x
            // log<1 / ˣ√y>(1 / y) = x
            case let (.root(x, y1), y2) where y1 == y2,
                 let (.divide(1, .root(x, y1)), .divide(1, y2)) where y1 == y2:
                self = x
                
                // log<1 / ˣ√y>(y) = -x
            // log<ˣ√y>(1 / y) = -x
            case let (.divide(1, .root(x, y1)), y2) where y1 == y2,
                 let (.root(x, y1), .divide(1, y2)) where y1 == y2:
                self = -x
                
            // log<1/a>(1/b) = log<a>(b)
            case let (.divide(.n(1), a), .divide(.n(1), b)):
                self = .log(a, b)
                simplify2()
                
                // log<1/a>(b) = -log<a>(b)
            // log<a>(1/b) = -log<a>(b)
            case let (.divide(.n(1), a), b),
                 let (a, .divide(.n(1), b)):
                self = -(.log(a, b))
                simplify2()
                
            // log<a^x>(b^x) = lob<a>(b)
            case let (.power(a, x1), .power(b, x2)) where x1 == x2:
                self = .log(a, b)
                simplify2()
                
            // log<a^y>(b^x) = (x / y) * lob<a>(b)
            case let (.power(a, x1), .power(b, x2)):
                self = (x2 / x1) * .log(a, b)
                simplify2()
                
                // log<b>(x^y) = ylog<b>(x)
            // log<root<y>(b)>(x) = ylog<b>(x)
            case let (b, .power(x, y)),
                 let (.root(y, b), x):
                self = y * .log(b, x)
                simplify2()
                
            // log<b^y>(x) = (1/y) * log<b>(x)
            case let (.power(y, b), x):
                self = (1 / y) * .log(b, x)
                simplify2()
                
            // log<x>(xy) = 1 + log<x>(y)
            case let (x1, .multiply(x2, y)) where x1 == x2,
                 let (x1, .multiply(y, x2)) where x1 == x2:
                self = 1 + .log(x1, y)
                simplify2()
                
            // log<x>(x / y) = 1 - log<x>(y)
            case let (x1, .divide(x2, y)) where x1 == x2:
                self = 1 - .log(x1, y)
                simplify2()
                
            // log<x>(x / y) = log<x>(y) - 1
            case let (x1, .divide(x2, y)) where x1 == x2:
                self = .log(x1, y) - 1
                simplify2()
                
            // log₂₇(4) = ⅔log₃(2)
            case let (.n(x), .n(y)):
                let powerX = x.asPower()
                let powerY = y.asPower()
                switch (powerX, powerY) {
                case let (px?, py?):
                    if px.exponent == py.exponent {
                        self = .log(.n(px.base), .n(py.base))
                        return
                    }
                    let a = gcd(px.exponent, py.exponent)
                    
                    if a == px.exponent {
                        self = .n(py.exponent / a) * .log(.n(px.base), .n(py.base))
                        return
                    }
                    self = (.n(py.exponent / a) / .n(px.exponent / a)) * .log(.n(px.base), .n(py.base))
                    
                case let (px?, _):
                    self = (1 / .n(px.exponent)) * .log(.n(px.base), .n(y))
                    
                case let (_, py?):
                    self = .n(py.exponent) * .log(.n(x), .n(py.base))
                    
                default:
                    return
                }
            // log<4>(x) = ½log₂(x)
            case let (.n(x), y):
                guard let perfectPower = x.asPower() else { return }
                self = (1 / .n(perfectPower.exponent)) * .log(.n(perfectPower.base), y)
                if !y.isVariable {
                    simplify2()
                }
                
                
            // logᵪ(4) = 2logᵪ(2)
            case let (x, .n(y)):
                guard let perfectPower = y.asPower() else { return }
                self = .n(perfectPower.exponent) * .log(x, .n(perfectPower.base))
                if !x.isVariable {
                    simplify2()
                }
                
                
                
            // No simplification
            default:
                return
                
            }
            
        // Root
        case var .root(lhs, rhs):
            
            lhs.simplify2()
            rhs.simplify2()
            
            self = .root(lhs, rhs)
            
            switch (lhs, rhs) {
            // log<...0> = NaN
            case let (.n(x), _) where x <= 0:
                fatalError("Cannot find the value of the nth root where n is less than 2")
                
            // ¹√x = x
            case let (1, x):
                self = x
                
            // √25 = 5
            case let (.n(x), .n(y)):
                let baseY = pow(Double(y), 1.0 / Double(x))
                if baseY == floor(baseY) {
                    self = .n(Int(baseY))
                }
                
            // √(5^2) = 5
            case let (x1, .power(y, x2)) where x1 == x2:
                self = y
                
                
            // No simplification
            default:
                return
                
            }
        }
    }
    
    public func simplified2() -> Expression {
        var simplifiedExpression = self
        simplifiedExpression.simplify2()
        return simplifiedExpression
    }
}
