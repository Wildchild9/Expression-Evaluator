//
//  Numeric Functions.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-28.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

@_transparent public func gcd(_ m: Int, _ n: Int) -> Int {
    
    var a = 0
    var b = max(m, n)
    var r = min(m, n)
    
    while r != 0 {
        a = b
        b = r
        r = a % b
    }
    return b
}

@_transparent public func lcm(_ m: Int, _ n: Int) -> Int {
    return m / gcd(m, n) * n
}


extension Int {
    @_transparent public func asPower() -> (base: Int, exponent: Int)? {
        for base in 2... {
            let squared = Int(pow(Double(base), 2.0))
            
            guard squared <= self else { break }
            guard self % base == 0 else { continue }
            
            if squared == self {
                return (base: base, exponent: 2)
            }
            
            for exp in 3... {
                let power = Int(pow(Double(base), Double(exp)))
                guard power <= self else { break }
                
                if power == self {
                    return (base: base, exponent: exp)
                }
            }
        }
        return nil
    }
}


public func nsExpressionSolve(_ equation: String) -> Double? {
    let mathExpression = NSExpression(format: equation.replacingOccurrences(of: "^", with: "**"))
    let mathValue = mathExpression.expressionValue(with: nil, context: nil) as? Double
    return mathValue
}
