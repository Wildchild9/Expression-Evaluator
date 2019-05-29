//
//  Simplification.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation


///////
//MARK: - Mutating Simplification
public extension Expression {
    
    
    mutating func simplify() {
        _simplify()
        removeDifferenceOfSquares()
        _simplify()
        addSquareRoots()
    }
    
    private mutating func _simplify() {
        
        switch self {
        // Variable
        case .x, .n:
            return
            
        // Addition
        case var .add(lhs, rhs):
            
            lhs._simplify()
            rhs._simplify()
            
            self = lhs + rhs
            
            switch (lhs, rhs) {
                
            // 0 + x = x
            case let (x, 0),
                 let (0, x):
                self = x
                return
                
            // x + (-x) = 0
            case let (.n(x), .n(y)) where x == -y:
                self = .zero
                return
                
            // x + (0 - x) = 0
            case let (x, .subtract(0, y)) where x == y,
                 let (.subtract(0, y), x) where x == y:
                self = .zero
                return
                
                
            // x + (0 - x) = 0
            case let (x, .subtract(0, y)) where x == y,
                 let (.subtract(0, y), x) where x == y:
                self = .zero
                return
                
            // x + (0 - y) = x - y
            // (0 - y) + x = x - y
            case let (x, y) where !x.isNegative && y.isNegative,
                 let (y, x) where y.isNegative && !x.isNegative:
                self = x - (-y)
                _simplify()
                return
                 
                
            // x + (y - x) = y
            case let (x1, .subtract(y, x2)) where x1 == x2,
                 let (.subtract(y, x1), x2) where x1 == x2:
                self = y
                return
                
                
            // a(x) + b(x) = (a + b)(x)
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                self = (a + b) * x1
                _simplify()
                return
                
            // x + ax = (a + 1)(x)
            case let (x1, .multiply(a, x2)) where x1 == x2,
                 let (x1, .multiply(x2, a)) where x1 == x2,
                 let (.multiply(a, x1), x2) where x1 == x2,
                 let (.multiply(x1, a), x2) where x1 == x2:
                if case let .n(value) = a {
                    self = .n(value + 1) * x1
                }
                self = (a + 1) * x1
                _simplify()
                return
                
            // (a / x) + (b / x) = (a + b) / x
            case let (.divide(a, x1), .divide(b, x2)) where x1 == x2:
                self = (a + b) / x1
                _simplify()
                return
                
            // (a / x) + (b / xy) = (ay + b) / xy
            case let (.divide(a, x1), .divide(b, .multiply(y, x2))) where x1 == x2,
                 let (.divide(a, x1), .divide(b, .multiply(x2, y))) where x1 == x2,
                 let (.divide(b, .multiply(y, x1)), .divide(a, x2)) where x1 == x2,
                 let (.divide(b, .multiply(x1, y)), .divide(a, x2)) where x1 == x2:
                self = (a * y + b) / (x1 * y)
                _simplify()
                return
                
            // Add fractions with lcm
            case let (.divide(a, .n(x)), .divide(b, .n(y))):
                let d = lcm(x, y)
                self = (a * .n(d / x) + b * .n(d / y)) / .n(d)
                _simplify()
                return
                
            // a + (b / x) = (ax + b) / x
            case let (a, .divide(b, x)),
                 let (.divide(b, x), a):
                self = (a * x + b) / x
                _simplify()
                return
                
            // log<x>(a) + log<x>(b) = log<x>(ab)
            case let (.log(x, a), .log(y, b)) where x == y:
                self = .log(x, a * b)
                _simplify()
                return
                
            // a + b
            case let (.n(a), .n(b)):
                self = .n(a + b)
                return
                
                
            // No simplification
            case let (a, b):
                self = a + b
                return
            }
            
        // Subtraction
        case var .subtract(lhs, rhs):
            
            lhs._simplify()
            rhs._simplify()
            
            self = lhs - rhs
            
            switch (lhs, rhs) {
                
            // x - 0 = x
            case let (x, 0):
                self = x
                return
                
            // x - x = 0
            case let (x, y) where x == y:
                self = .zero
                return
                
            // 0 - x = -x
            case let (0, .n(y)):
                self = .n(-y)
                return
                
            // 0 - 0 - n
            case let (0, n) where n.isNegative:
                self = -n
                return
                
            // x - (x + y) = -y
            // (x - y) - x = -y
            case let (x1, .add(x2, y))      where x1 == x2,
                 let (x1, .add(y, x2))      where x1 == x2,
                 let (.subtract(x1, y), x2) where x1 == x2:
                self = -y
                return
                
            // (x + y) - x = y
            // x - (x - y) = y
            case let (.add(x1, y), x2)      where x1 == x2,
                 let (.add(y, x1), x2)      where x1 == x2,
                 let (x1, .subtract(x2, y)) where x1 == x2:
                self = y
                return
                
            // Difference of squares (decided to break apart difference of squares instead)
//            case let (.power(a, .n(b)), .power(c, .n(d))) where b.isMultiple(of: 2) && d.isMultiple(of: 2):
//                self = (a ^ .n(b / 2) - c ^ .n(d / 2)) * (a ^ .n(b / 2) + c ^ .n(d / 2))
//                _simplify()
//                return
//
//            case let (.n(a), .power(b, .n(c))) where a.asPower()?.exponent.isMultiple(of: 2) ?? false && c.isMultiple(of: 2):
//                self =  (.n(a / 2) - b ^ .n(c / 2)) * (.n(a / 2) + b ^ .n(c / 2))
//                _simplify()
//                return
//
//            case let (.power(b, .n(c)), .n(a)) where a.asPower() != nil, a.asPower()?.exponent.isMultiple(of: 2) ?? false && c.isMultiple(of: 2):
//                self =  (.n(a / 2) - b ^ .n(c / 2)) * (.n(a / 2) + b ^ .n(c / 2))
//
//                _simplify()
//                return
            // End: Difference of squares
                
            // a(x) - b(x) = (a - b)(x)
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                self = (a - b) * x1
                _simplify()
                return
                
            // x - ax = (a + 1)(x)
            case let (x1, .multiply(a, x2)) where x1 == x2,
                 let (x1, .multiply(x2, a)) where x1 == x2:
                if case let .n(value) = a {
                    self = .n(value + 1) * x1
                } else {
                    self = (a + 1) * x1
                }
                _simplify()
                return
                
            // ax - x = (a - 1)(x)
            case let (.multiply(a, x1), x2) where x1 == x2,
                 let (.multiply(x1, a), x2) where x1 == x2:
                if case let .n(value) = a {
                    self = .n(value - 1) * x1
                } else {
                    self = (a - 1) * x1
                }
                _simplify()
                return
                
            // (a / x) - (b / x) = (a - b) / x
            case let (.divide(a, x1), .divide(b, x2)) where x1 == x2:
                self = (a - b) / x1
                _simplify()
                return
                
            // (a / x) - (b / xy) = (ay - b) / xy
            case let (.divide(a, x1), .divide(b, .multiply(y, x2))) where x1 == x2,
                 let (.divide(a, x1), .divide(b, .multiply(x2, y))) where x1 == x2:
                self = (a * y - b) / (x1 * y)
                _simplify()
                return
                
            // (a / xy) - (b / x) = (a - by) / xy
            case let (.divide(a, .multiply(y, x1)), .divide(b, x2)) where x1 == x2,
                 let (.divide(a, .multiply(x1, y)), .divide(b, x2)) where x1 == x2:
                self = (a - b * y) / (x1 * y)
                _simplify()
                return
                
            // Subtract fractions with lcm
            case let (.divide(a, .n(x)), .divide(b, .n(y))):
                let d = lcm(x, y)
                self = (a * .n(d / x) - b * .n(d / y)) / .n(d)
                _simplify()
                return
                
            // Subtract fractions with common denominator multiplicand and lcm
            case let (.divide(a, .multiply(g1, .n(b))), .divide(x, .multiply(g2, .n(y)))) where g1 == g2,
                 let (.divide(a, .multiply(g1, .n(b))), .divide(x, .multiply(.n(y), g2))) where g1 == g2,
                 let (.divide(a, .multiply(.n(b), g1)), .divide(x, .multiply(g2, .n(y)))) where g1 == g2,
                 let (.divide(a, .multiply(.n(b), g1)), .divide(x, .multiply(.n(y), g2))) where g1 == g2:
                let lcmBY = lcm(b, y)
                self = ((a * .n(lcmBY / b) - (x * .n(lcmBY / y))) / (.n(lcmBY) * g1))
                _simplify()
                return
                
            // log<x>(a) - log<x>(b) = log<x>(a / b)
            case let (.log(x, a), .log(y, b)) where x == y:
                self = .log(x, a / b)
                _simplify()
                return
                
            // a - b
            case let (.n(a), .n(b)):
                self = .n(a - b)
                return
                
            // No simplification
            case let (a, b):
                self = a - b
                return
            }
            
        // Multiplication
        case var .multiply(lhs, rhs):
            
            lhs._simplify()
            rhs._simplify()
            
            self = lhs * rhs
            
            switch (lhs, rhs) {
                
            // 0x = 0
            case (0, _), (_, 0):
                self = .zero
                return
                
            // 1x = x
            case let (x, 1), let (1, x):
                self = x
                return
                
            // -1x = -x
            case let (x, -1), let (-1, x):
                self = -x
                return
                
            // x * x = x ^ 2
            case let (x, y) where x == y:
                self = x ^ 2
                _simplify()
                return
                
                
            // a * (b * x) = ab * x
            case let (.n(a), .multiply(.n(b), x)),
                 let (.n(a), .multiply(x, .n(b))),
                 let (.multiply(.n(a), x), .n(b)),
                 let (.multiply(x, .n(a)), .n(b)):
                self = .n(a * b) * x
                return
                
            // b * (a / b) = a
            case let (b1, .divide(a, b2)) where b1 == b2,
                 let (.divide(a, b1), b2) where b1 == b2:
                self = a
                return
                
            // x * (a / b) = ((x / GCD(x, b)) * a) / (b / GCD(x, b))
            case let (.n(x), .divide(a, .n(b))),
                 let (.divide(a, .n(b)), .n(x)):
                let gcdBX = gcd(b, x)
                self = (.n(x / gcdBX) * a) / .n(b / gcdBX)
                _simplify()
                return
                
            // x * x ^ y = x ^ (y + 1)
            case let (x1, .power(x2, y)) where x1 == x2,
                 let (.power(x1, y), x2) where x1 == x2:
                if case let .n(value) = y {
                    self = x1 ^ .n(value + 1)
                } else {
                    self = x1 ^ (1 + y)
                }
                _simplify()
                return
                
                //            // TODO: New
                //            // a * (log<x>(y) / b) = (a / b) * log<x>(y)
                //            case let (a, .divide(.log(x, y), b)),
                //                 let (.divide(.log(x, y), b), a):
                //                self = ((a / b) * .log(x, y))
                //                return
                
            // (1 / y) * x = x / y
            case let (.divide(1, den), num),
                 let (num, .divide(1, den)):
                self = (num /  den)
                _simplify()
                return
                
            // (-1 / y) * x = x / y
            case let (.divide(-1, den), num),
                 let (num, .divide(-1, den)):
                if case let .n(x) = num {
                    self = .n(-x) / den
                } else if case let .n(y) = den {
                    self = num / .n(-y)
                } else {
                    self = (.zero - num) / den
                }
                _simplify()
                return
                
            // (x / y) * (y / x) = 1
            case let (.divide(x1, y1), .divide(y2, x2)) where x1 == x2 && y1 == y2:
                self = .n(1)
                return
                
            // Cross reduction
            case let (.divide(.n(a), .n(b)), .divide(.n(x), .n(y))):
                let commonAY = gcd(a, y)
                let commonBX = gcd(b, x)
                self = .n((a / commonAY) * (x / commonBX)) / .n((y / commonAY) * (b / commonBX))
                _simplify()
                return
                
            // Cross reduction
            case let (.divide(.n(a), b), .divide(x, .n(y))):
                let commonAY = gcd(a, y)
                self = ((.n(a / commonAY) * x) / (.n(y / commonAY) * b))
                _simplify()
                return
                
            // Cross reduction
            case let (.divide(a, .n(b)), .divide(.n(x), y)):
                let commonBX = gcd(b, x)
                self = (a * .n(x / commonBX)) / (y * .n(b / commonBX))
                _simplify()
                return
                
            // a * (x / y) = ax / y
            case let (a, .divide(x, y)) where !a.isLog,
                 let (.divide(x, y), a) where !a.isLog:
                self = (a * x) / y
                _simplify()
                return
                
            // x^a * x^b = x^(a + b)
            case let (.power(x1, a), .power(x2, b)) where x1 == x2:
                self = x1 ^ (a + b)
                _simplify()
                return
                
            // x^a * px^b = px^(a + b)
            case let (.power(x1, a), .multiply(p, .power(x2, b))) where x1 == x2,
                 let (.power(x1, a), .multiply(.power(x2, b), p)) where x1 == x2,
                 let (.multiply(p, .power(x1, a)), .power(x2, b)) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .power(x2, b)) where x1 == x2:
                self = p * (x1 ^ (a + b))
                _simplify()
                return
                
            // px^a * qx^b = pqx^(a + b)
            case let (.multiply(p, .power(x1, a)), .multiply(q, .power(x2, b))) where x1 == x2,
                 let (.multiply(p, .power(x1, a)), .multiply(.power(x2, b), q)) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .multiply(q, .power(x2, b))) where x1 == x2,
                 let (.multiply(.power(x1, a), p), .multiply(.power(x2, b), q)) where x1 == x2:
                self = p * q * (x1 ^ (a + b))
                _simplify()
                return
                
            // Combining powers
            case let (.n(a), .power(.n(b), c)),
                 let (.power(.n(b), c), .n(a)):
                
                guard let power = a.asPower(), power.base == b else {
                    return
                }
                self = .n(b) ^ (.n(power.exponent) + c)
                _simplify()
                return
                
                //            case let (a, .multiply(.divide(b, c), d)),
                //                 let (.multiply(.divide(b, c), d), a),
                //                 let (a, .multiply(d, .divide(b, c))),
                //                 let (.multiply(d, .divide(b, c)), a):
                //                self = ((a * b) / c) * d
                //                _simplify()
                //                return
                
                
            // x * (x * y) = y * (x ^ 2)
            case let (x1, .multiply(x2, y)) where x1 == x2,
                 let (x1, .multiply(y, x2)) where x1 == x2,
                 let (.multiply(x2, y), x1) where x1 == x2,
                 let (.multiply(y, x2), x1) where x1 == x2:
                self = y * x1 ^ 2
                return
                
            // log<x>(a) * log<a>(y) = log<x>(y)
            case let (.log(x, a), .log(b, y)) where a == b:
                self = .log(x, y)
                _simplify()
                return
                
            // a * b
            case let (.n(a), .n(b)):
                self = .n(a * b)
                return
                
            // No simplification
            case let (a, b):
                self = a * b
                return
            }
            
        // Division
        case var .divide(lhs, rhs):
            
            lhs._simplify()
            rhs._simplify()
            
            self = lhs / rhs
            
            switch (lhs, rhs) {
            // x / 0 = NaN
            case (_, 0):
                fatalError("Division by zero")
                
            // 0 / x = 0
            case (0, _):
                self = .zero
                return
                
            // -x / -y = x / y
            case let (x, y) where x.isNegative && y.isNegative:
                self = -x / -y
                _simplify()
                return
                
            // -x / y = 0 - (x / y)
            case let (x, y) where x.isNegative:
                self = (-x / y)
                _simplify()
                self = 0 - self
                return
                
            // x / -y = 0 - (x / y)
            case let (x, y) where y.isNegative:
                self = (x / -y)
                _simplify()
                self = 0 - self
                return
                
            // x / 1 = x
            case let (x, 1):
                self = x
                return
                
            // x / x = 1
            case let (x, y) where x == y:
                self = .n(1)
                return
                
            // (x * y) / x = y
            case let (.multiply(x1, y), x2) where x1 == x2,
                 let (.multiply(y, x1), x2) where x1 == x2:
                self = y
                return
                
            // x / (x / y) = y
            case let (x1, .divide(x2, y)) where x1 == x2:
                self = y
                return
                
            // (a / b) / c = a / bc
            case let (.divide(a, b), c):
                self = a / (b * c)
                _simplify()
                return
                
            // a / (x / y) = a * (y / x)
            case let (a, .divide(x, y)):
                self = a * (y / x)
                _simplify()
                return
                
            // ax / bx = a / b
            case let (.multiply(a, x1), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, x1), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(x2, b)) where x1 == x2:
                self = a / b
                _simplify()
                return
                
            // x / (x * y) = 1 / y
            case let (x1, .multiply(x2, y)) where x1 == x2,
                 let (x1, .multiply(y, x2)) where x1 == x2:
                self = 1 / y
                return
                
            // (ax + bx) / x = a + b
            case let (.add(.multiply(a, x1), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(a, x1), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.add(.multiply(x1, a), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3:
                self = a + b
                _simplify()
                return
                
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
                _simplify()
                return
                
            // (ax - bx) / x = a - b
            case let (.subtract(.multiply(a, x1), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(a, x1), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(b, x2)), x3) where x1 == x2 && x2 == x3,
                 let (.subtract(.multiply(x1, a), .multiply(x2, b)), x3) where x1 == x2 && x2 == x3:
                self = a - b
                _simplify()
                return
                
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
                _simplify()
                return
                
            // x^y / x = x ^ (y - 1)
            case let (.power(x1, y), x2) where x1 == x2:
                self = x1 ^ (y - 1)
                _simplify()
                return
                
            // x / x^y = x ^ (1 - y)
            case let (x1, .power(x2, y)) where x1 == x2:
                self = x1 ^ (1 - y)
                _simplify()
                return
                
            // x^a / x^b = x^(a - b)
            case let (.power(x1, a), .power(x2, b)) where x1 == x2:
                self = x1 ^ (a - b)
                _simplify()
                return
                
            // ax^y / x = ax^(y - 1)
            case let (.multiply(a, .power(x1, y)), x2) where x1 == x2,
                 let (.multiply(.power(x1, y), a), x2) where x1 == x2:
                self = a * x1 ^ (y - 1)
                _simplify()
                return
                
            // x^y / ax = (1 / a) * x^(y - 1)
            case let (.power(x1, y), .multiply(a, x2)) where x1 == x2,
                 let (.power(x1, y), .multiply(x2, a)) where x1 == x2:
                self = (1 / a) * x1 ^ (y - 1)
                _simplify()
                return
                
            // ax^y / bx = (a / b) * x^(y - 1)
            case let (.multiply(a, .power(x1, y)), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(a, .power(x1, y)), .multiply(x2, b)) where x1 == x2,
                 let (.multiply(.power(x1, y), a), .multiply(b, x2)) where x1 == x2,
                 let (.multiply(.power(x1, y), a), .multiply(x2, b)) where x1 == x2:
                self = (a / b) * x1 ^ (y - 1)
                _simplify()
                return
                
            // ax / x^y = ax^(1 - 1)
            case let (x1, .multiply(a, .power(x2, y))) where x1 == x2,
                 let (x1, .multiply(.power(x2, y), a)) where x1 == x2:
                self = a * x1 ^ (1 - y)
                _simplify()
                return
                
            // x / ax^y = (1 / a) * x^(1 - y)
            case let (.multiply(a, x1), .power(x2, y)) where x1 == x2,
                 let (.multiply(x1, a), .power(x2, y)) where x1 == x2:
                self = (1 / a) * x1 ^ (1 - y)
                _simplify()
                return
                
            // ax / bx^y = (a / b) * x^(1 - y)
            case let (.multiply(a, x1), .multiply(b, .power(x2, y))) where x1 == x2,
                 let (.multiply(x1, a), .multiply(b, .power(x2, y))) where x1 == x2,
                 let (.multiply(a, x1), .multiply(.power(x2, y), b)) where x1 == x2,
                 let (.multiply(x1, a), .multiply(.power(x2, y), b)) where x1 == x2:
                self = (a / b) * x1 ^ (1 - y)
                _simplify()
                return
                
                
            // ax^g / x^h = ax^(g - h)
            case let (.power(x1, g), .multiply(a, .power(x2, h))) where x1 == x2,
                 let (.power(x1, g), .multiply(.power(x2, h), a)) where x1 == x2:
                self = a * x1 ^ (g - h)
                _simplify()
                return
                
            // x^g / ax^h = (1 / a) * x^(g - h)
            case let (.multiply(a, .power(x1, g)), .power(x2, h)) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .power(x2, h)) where x1 == x2:
                self = (1 / a) * x1 ^ (g - h)
                _simplify()
                return
                
            // ax^g / bx^h = (a / b) * x^(g - h)
            case let (.multiply(a, .power(x1, g)), .multiply(b, .power(x2, h))) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .multiply(b, .power(x2, h))) where x1 == x2,
                 let (.multiply(a, .power(x1, g)), .multiply(.power(x2, h), b)) where x1 == x2,
                 let (.multiply(.power(x1, g), a), .multiply(.power(x2, h), b)) where x1 == x2:
                self = (a / b) * x1 ^ (g - h)
                _simplify()
                return
                
            // Combining powers
            case let (.n(a), .power(.n(b), c)):
                guard let power = a.asPower(), power.base == b else {
                    return
                }
                self = .n(b) ^ (.n(power.exponent) - c)
                _simplify()
                return
                
            // Combining powers
            case let (.power(.n(b), c), .n(a)):
                guard let power = a.asPower(), power.base == b else {
                    return
                }
                self = .n(b) ^ (c - .n(power.exponent))
                _simplify()
                return
                
            // 10 / 2 = 5
            case let (.n(x), .n(y)) where x % y == 0:
                self = .n(x / y)
                return
                
            // 10 / 5 = 2 / 1
            case let (.n(x), .n(y)):
                let a = gcd(x, y)
                let newX = x / a
                let newY = y / a
                guard newX != x else { return }
                
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
                return
                
            // log<x>(a) / log<x>(b) = log<b>(a)
            case let (.log(x, a), .log(y, b)) where x == y:
                self = .log(b, a)
                _simplify()
                return
                
            // xlog<y>(a) / log<y>(b) = xlog<b>(a)
            case let (.multiply(x, .log(y1, a)), .log(y2, b)) where y1 == y2,
                 let (.multiply(.log(y1, a), x), .log(y2, b)) where y1 == y2:
                self = x * .log(b, a)
                _simplify()
                return
                
            // log<y>(a) / xlog<y>(b) = (1 / x)log<b>(a)
            case let (.log(y1, a), .multiply(x, .log(y2, b))) where y1 == y2,
                 let (.log(y1, a), .multiply(.log(y2, b), x)) where y1 == y2:
                self = (.n(1) / x) * .log(b, a)
                _simplify()
                return
                
            // xlog<y>(a) / zlog<y>(b) = (x/z)log<b>(a)
            case let (.multiply(x1, .log(y1, a)), .multiply(x2, .log(y2, b))) where y1 == y2,
                 let (.multiply(x1, .log(y1, a)), .multiply(.log(y2, b), x2)) where y1 == y2,
                 let (.multiply(.log(y1, a), x1), .multiply(x2, .log(y2, b))) where y1 == y2,
                 let (.multiply(.log(y1, a), x1), .multiply(.log(y2, b), x2)) where y1 == y2:
                self = (x1 / x2) * .log(b, a)
                _simplify()
                return
                
            // (a * log<x>(y)) / b = (a / b) * log<x>(y)
            case let (.multiply(a, .log(x, y)), b),
                 let (.multiply(.log(x, y), a), b):
                self = (a / b) * .log(x, y)
                _simplify()
                return
                
            // x / log<a>(b) = xlog<b>(a)
            case let (x, .log(a, b)):
                self = x * .log(b, a)
                _simplify()
                return
                
            // No simplification
            case let (a, b):
                self = a / b
                return
            }
            
        // Exponentiation
        case var .power(lhs, rhs):
            
            lhs._simplify()
            rhs._simplify()
            
            self = lhs ^ rhs

            // If performing power operation won't result in overflow, do operation
            if case let .power(.n(x), .n(y)) = self, y != 0,  abs(x) <= 15 && abs(y) <= 15 {
                self = .n(Int(pow(Double(x), Double(y))))
                return
            }
            
            
            switch (lhs, rhs) {
                
            // 0 ^ 0
            case (0, 0):
                fatalError("0⁰ is not a number.")
                
            // x ^ 0 = 1
            case (_, 0):
                self = .n(1)
                return
                
            // 0 ^ x = 0
            case (0, _):
                self = .zero
                return
                
            // x ^ 1 = x
            case let (x, 1):
                self = x
                return
            
            // (x / y) ^ -e = (y / x) ^ e
            case let (.divide(x, y), e) where e.isNegative:
                self = (y / x) ^ -e
                _simplify()
                return
                
            case let (a, .power(b, c)),
                 let (.power(a, b), c):
                self = a ^ (b * c)
                _simplify()
                return

                
            // Not sure if this is a good simplification
            // a ^ -b = 1 / (a ^ b)
            case let (a, b) where b.isNegative:
                self = 1 / (a ^ -b)
                _simplify()
                return
                
            //FIXME: Remove roots
            // y ^ (1 / x) = ˣ√y
//            case let (a, .divide(1, b)):
//                self = .root(b, a)
//                _simplify()
//                return
                
            //FIXME: Remove roots
            // ˣ√(y) ^ x = y
//            case let (.root(x1, y), x2) where x1 == x2:
//                self = y
//                return
                
            // x ^ logᵪy = y
            case let (x1, .log(x2, y)) where x1 == x2:
                self = y
                return
                
            // x ^ alogᵪy = y ^ a
            case let (x1, .multiply(a, .log(x2, y))) where x1 == x2,
                 let (x1, .multiply(.log(x2, y), a)) where x1 == x2:
                self = y ^ a
                return
                
            // Reduce power to lowest base
            case let (.n(x), y):
                
                if let perfectPower = x.asPower() {
                    self = .n(perfectPower.base) ^ (.n(perfectPower.exponent) * y)
                    _simplify()
                    //self = ((.n(perfectPower.base) ^ (.n(perfectPower.exponent) * y)._simplified()))
                    //return
                }
                return
            
            // No simplification
            case let (a, b):
                self = a ^ b
                return
                
            }
            
        // Logarithms
        case var .log(lhs, rhs):
            
            lhs._simplify()
            rhs._simplify()
            
            self = .log(lhs, rhs)
            
            switch (lhs, rhs) {
                
            // log<...1> = NaN
            case let (.n(x), _) where x < 2:
                fatalError("Cannot find the value of a log with an integral base less than 2")
            
            // log<b>(1) = 0
            case (_, 1):
                self = 0
                return
                
            // logᵪ(x) = 1
            case let (x, y) where x == y:
                self = .n(1)
                return
                
                // log<ˣ√y>(y) = x
            // log<1 / ˣ√y>(1 / y) = x
            case let (.root(x, y1), y2) where y1 == y2,
                 let (.divide(1, .root(x, y1)), .divide(1, y2)) where y1 == y2:
                self = x
                return
                
            // log<1 / ˣ√y>(y) = -x
            // log<ˣ√y>(1 / y) = -x
            case let (.divide(1, .root(x, y1)), y2) where y1 == y2,
                 let (.root(x, y1), .divide(1, y2)) where y1 == y2:
                self = -x
                return
                
            // log<1/a>(1/b) = log<a>(b)
            case let (.divide(.n(1), a), .divide(.n(1), b)):
                self = .log(a, b)
                _simplify()
                return
                
                // log<1/a>(b) = -log<a>(b)
            // log<a>(1/b) = -log<a>(b)
            case let (.divide(.n(1), a), b),
                 let (a, .divide(.n(1), b)):
                self = -(.log(a, b))
                _simplify()
                return
                
            // log<a^x>(b^x) = lob<a>(b)
            case let (.power(a, x1), .power(b, x2)) where x1 == x2:
                self = .log(a, b)
                _simplify()
                return
                
            // log<a^y>(b^x) = (x / y) * lob<a>(b)
            case let (.power(a, x1), .power(b, x2)):
                self = (x2 / x1) * .log(a, b)
                _simplify()
                return
                
                // log<b>(x^y) = ylog<b>(x)
            // log<root<y>(b)>(x) = ylog<b>(x)
            case let (b, .power(x, y)),
                 let (.root(y, b), x):
                self = y * .log(b, x)
                _simplify()
                return
                
            // log<b^y>(x) = (1/y) * log<b>(x)
            case let (.power(y, b), x):
                self = (1 / y) * .log(b, x)
                _simplify()
                return
                
            // log<x>(xy) = 1 + log<x>(y)
            case let (x1, .multiply(x2, y)) where x1 == x2,
                 let (x1, .multiply(y, x2)) where x1 == x2:
                self = 1 + .log(x1, y)
                _simplify()
                return
                
            // log<x>(x / y) = 1 - log<x>(y)
            case let (x1, .divide(x2, y)) where x1 == x2:
                self = 1 - .log(x1, y)
                _simplify()
                return
                
            // log<x>(x / y) = log<x>(y) - 1
            case let (x1, .divide(x2, y)) where x1 == x2:
                self = .log(x1, y) - 1
                _simplify()
                return
                
            // log₂₇(4) = ⅔log₃(2)
            case let (.n(x), .n(y)):
                let powerX = x.asPower()
                let powerY = y.asPower()
                switch (powerX, powerY) {
                case let (px?, py?):
                    if px.exponent == py.exponent {
                        self = .log(.n(px.base), .n(py.base))
                        _simplify()
                        return
                    }
                    let a = gcd(px.exponent, py.exponent)
                    
                    if a == px.exponent {
                        self = .n(py.exponent / a) * .log(.n(px.base), .n(py.base))
                        _simplify()
                        return
                    }
                    self = (.n(py.exponent / a) / .n(px.exponent / a)) * .log(.n(px.base), .n(py.base))
                    _simplify()
                    return
                    
                case let (px?, _):
                    self = (1 / .n(px.exponent)) * .log(.n(px.base), .n(y))
                    _simplify()
                    return
                    
                case let (_, py?):
                    self = .n(py.exponent) * .log(.n(x), .n(py.base))
                    _simplify()
                    return
                    
                default:
                    return
                }
            // log<4>(x) = ½log₂(x)
            case let (.n(x), y):
                guard let perfectPower = x.asPower() else { return }
                self = (1 / .n(perfectPower.exponent)) * .log(.n(perfectPower.base), y)
                if !y.isVariable {
                    _simplify()
                }
                return
                
                
            // logᵪ(4) = 2logᵪ(2)
            case let (x, .n(y)):
                guard let perfectPower = y.asPower() else { return }
                self = .n(perfectPower.exponent) * .log(x, .n(perfectPower.base))
                if !x.isVariable {
                    _simplify()
                }
                return
                
                
                
            // No simplification
            case let (a, b):
                self = .log(a, b)
                return
                
            }
            
        // Root
        case var .root(lhs, rhs):
            
            lhs._simplify()
            rhs._simplify()
            
            //FIXME: Convert all roots to exponents
            self = lhs ^ (1 / rhs)
            _simplify()
            return
            ////////////////////////////
            
            
        }
    }
    
    private mutating func removeDifferenceOfSquares() {
        switch self {
        case var .add(lhs, rhs):
            lhs.removeDifferenceOfSquares()
            rhs.removeDifferenceOfSquares()
            self = .add(lhs, rhs)
            
        case var .subtract(lhs, rhs):
            lhs.removeDifferenceOfSquares()
            rhs.removeDifferenceOfSquares()
            self = .subtract(lhs, rhs)
            
        case var .multiply(lhs, rhs):
            lhs.removeDifferenceOfSquares()
            rhs.removeDifferenceOfSquares()
            self = .multiply(lhs, rhs)
            
            switch (lhs, rhs) {
            case let (.add(a, b), .subtract(c, d)) where a == c && b == d,
                 let (.subtract(c, d), .add(a, b)) where a == c && b == d:
                self = (a ^ 2) - (c ^ 2)
                _simplify()
                return
                
            default:
                return
            }
            
        case var .divide(lhs, rhs):
            lhs.removeDifferenceOfSquares()
            rhs.removeDifferenceOfSquares()
            self = .divide(lhs, rhs)
            
        case var .power(lhs, rhs):
            lhs.removeDifferenceOfSquares()
            rhs.removeDifferenceOfSquares()
            self = .power(lhs, rhs)
            
        case var .log(lhs, rhs):
            lhs.removeDifferenceOfSquares()
            rhs.removeDifferenceOfSquares()
            self = .log(lhs, rhs)
            
        case var .root(lhs, rhs):
            lhs.removeDifferenceOfSquares()
            rhs.removeDifferenceOfSquares()
            self = .root(lhs, rhs)
            
        default:
            return
            
        }
    }
    
    private mutating func addSquareRoots() {
        switch self {
        case var .add(lhs, rhs):
            lhs.addSquareRoots()
            rhs.addSquareRoots()
            self = .add(lhs, rhs)
            
        case var .subtract(lhs, rhs):
            lhs.addSquareRoots()
            rhs.addSquareRoots()
            self = .subtract(lhs, rhs)
            
        case var .multiply(lhs, rhs):
            lhs.addSquareRoots()
            rhs.addSquareRoots()
            self = .multiply(lhs, rhs)
            
        case var .divide(lhs, rhs):
            lhs.addSquareRoots()
            rhs.addSquareRoots()
            self = .divide(lhs, rhs)
            
        case var .power(lhs, rhs):
            lhs.addSquareRoots()
            rhs.addSquareRoots()
            self = .power(lhs, rhs)
            
            switch (lhs, rhs) {
            case let (a, .divide(b, 2)):
                var discriminant = a ^ b
                discriminant._simplify()
                self = .root(2, discriminant)
                return
                
            default:
                return
            }
            
        case var .log(lhs, rhs):
            lhs.addSquareRoots()
            rhs.addSquareRoots()
            self = .log(lhs, rhs)
            
        case var .root(lhs, rhs):
            lhs.addSquareRoots()
            rhs.addSquareRoots()
            self = .root(lhs, rhs)
            
        default:
            return
            
        }
        
    }
    
}

///////
//MARK: - Nonmutating Simplification
public extension Expression {
    
    public func simplified() -> Expression {
        var simplifiedExpression = self
        simplifiedExpression.simplify()
        return simplifiedExpression
    }
    
}

