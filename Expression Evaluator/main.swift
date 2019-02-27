//
//  main.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-19.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

// Operators ^, *, /, +, -

//TODO: Use custom Fraction type with big integer as numerator and denominator


/////////////////
let equation1 = "3 + (7 ^ 2 * (49 - 21) / (6 + 1) - (4 * (2 + 5))) - 2 * (7 * 5) ^ 2"
equation1.solve()

let mathExpression = NSExpression(format: equation1.formatEquation().replacingOccurrences(of: "^", with: "**"))
let mathValue = mathExpression.expressionValue(with: nil, context: nil) as? Double
print(mathValue!)


/////////////////
let equation2 = "5(4) + 320(435) - (329 + 23)(329 + 329)"
equation2.solve()

/////////////////
let equation3 = "(100-100)/(100-100)"
equation3.solve()

/////////////////
let equation4 = "(100 - 100) + (3 + -3) - 4(1439023 / (0 ^ (2 - (3 + 6 * (16 * 3 * (1 / 3) / 2 ^ 4)))))" //"(100 - 100) + (3 + -3) - 4(1439023 / 4)"
var expression4 = Expression(equation4, simplify: false)
print(String.separatorLine)
print(equation4)
print(expression4)
print()

measure(label: "Simplification", tests: 10000) {
    _ = expression4.simplified()
}
expression4 = expression4.simplified()
print(expression4)

//print(expression4)
//print(expression4.literalDescription)
//print(expression4.evaluate())


/////////////////
print(String.separatorLine)


