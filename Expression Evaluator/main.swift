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
print(exp1)

///////////////////
print(String.separatorLine)

let exp2 = Expression("4 * 2 ^ (2x)")



print(Expression("5log<4>(x)"))


var eq = Expression("x^(5log<4>(x))")





let n = eq.evaluate(withX: 10)
print(eq.simplified())

eq.solveForX()

print(eq.solveForX()!.first!.latex)
//let e = pow(2, 1.0 / log(2))
//print("e =", pow(2, 1.0 / log(2)))
//print("e =", M_E)


var expression10 = Expression("log<2>(3)-log<2>(27)+log<2>(x+2)")
print(expression10.evaluate(withX: 10))
print(expression10.solveForX()!.first!.evaluate(withX: 0.4150374992788439))

// Convert roots to exponents with fractions
// Only convert to roots in printing

// Add simplifications when performing an operation when passing around terms

var exp5: Expression = 5 * (.x - 3 * (2 - 4 - .x))
print(exp5)
print(exp5.extractNonVariableTerms())
print(Expression("log<2>(5)"))

print(Expression("-x").literalDescription)

print(Expression("4(-x)log<5>(3)"))

