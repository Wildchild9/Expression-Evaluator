//
//  main.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-19.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

// Operators ^, *, /, +, -
// Add support for simplifications like (a - b)(a + b) = a² - b²

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
var expression = Expression(equation, simplify: false) {
    willSet {
        print(expression)
    }
}
expression.simplify()
print(equation)
print("=", expression)
print("=", expression.evaluate())
print(expression.literalDescription)


///////////////////
print(String.separatorLine)

let exp1 = Expression("x ^ (3log<x>(2))")
print(exp1)

///////////////////
print(String.separatorLine)

let exp2 = Expression("4 * 2 ^ (2x)")



print(Expression("5log<4>(x)"))


var eq = Expression("x^(5log<4>(x))")





let n = eq.evaluate(withX: 10)
print(eq.simplified())

eq.solveForX()
