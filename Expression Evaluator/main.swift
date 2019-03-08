//
//  main.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-19.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

// Operators ^, *, /, +, -

///////////////////
// Test Equations
do {
    let _ = "3 + (7 ^ 2 * (49 - 21) / (6 + 1) - (4 * (2 + 5))) - 2 * (7 * 5) ^ 2"
    let _ = "5(4) + 320(435) - (329 + 23)(329 + 2) ^ 2"
    let _ = "(100 - 100) + (3 + -3) - 4(1439023 / (0 ^ (2 - (3 + 6 * (16 * 3 * (1 / 3) / 2 ^ 4)))))"

}


/////////////////
print(String.separatorLine)
let equation = "log<4>(64) / log<243>(27)"
let expression = Expression(equation)
print(equation)
print("=", expression)
print("=", expression.evaluate())
print(expression.literalDescription)


/////////////////
print(String.separatorLine)

var exp: Expression = 5 ^ 3
print(exp)


print(Expression("2log<3>(16)"))

print(Expression("log<4>(64) / log<243>(27)", simplify: false).latex)


