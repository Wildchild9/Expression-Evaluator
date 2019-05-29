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
var expression = Expression(equation, simplify: false)
expression.simplify()
print(equation)
print("=", expression)
print("=", expression.evaluate())
print(expression.literalDescription)


///////////////////
print(String.separatorLine)

let exp1 = Expression("x ^ (3log<x>(2))")
exp1.solveForX(showingSteps: true)


///////////////////
print(String.separatorLine)

let exp2 = Expression("4 * 2 ^ (2x)")

///////////////////
print(String.separatorLine)
print(Expression("5log<4>(x)"))

///////////////////
print(String.separatorLine)

let eq1 = Expression("x^(5log<4>(x))")
let solutions = eq1.solveForX(showingSteps: true)!

///////////////////
print(String.separatorLine)

var exp3 = Expression("log<2>(5 + 2x) - log<2>(4 - x)")

print(exp3)
exp3.replaceX(with: .n(27) / .n(10)) // 2.7
print("=", exp3)
exp3.simplify()
print("=", exp3)
print("=", exp3.evaluate())


///////////////////
print(String.separatorLine)

let exp4: Expression = "(5 ^ (7 / x) + 1) / 2"
exp4.solveForX(showingSteps: true)

///////////////////
print(String.separatorLine)

let eq5 = "((x + 1) ^ (-1 / 4)) * ((x - 1) ^ (-1 / 2)) + ((x + 1) ^ (3 / 4)) * ((x - 1) ^ (1 / 2))"
var exp5 = Expression(eq5, simplify: false)
print(exp5)
print(exp5.latex)
exp5.simplify()
print(exp5)
print(exp5.latex)

///////////////////
print(String.separatorLine)

///////////////////
print(String.separatorLine)


///////////////////
print(String.separatorLine)

///////////////////
print(String.separatorLine)


///////////////////
print(String.separatorLine)


///////////////////
print(String.separatorLine)




// Convert roots to exponents with fractions

// Add simplifications when performing an operation when passing around terms

