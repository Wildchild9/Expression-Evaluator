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
expression = expression.simplified()
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



extension Expression {
    @discardableResult func solveForX(printResults: Bool = true, showingSteps: Bool = false) -> [Expression]? {
        guard containsVariable() else { return nil }
        
        let expression = simplified()
        if printResults {
            print("y =", expression)
        }
        let equation = Equation(expression: expression)
        let results = equation.isolated(showingSteps: showingSteps)
        
        
        guard !results.contains(where: { $0.left != .x }) else {
            if printResults {
                print("Cannot solve for x")
            }
            return nil
        }
        
        let solutions = results.map { $0.right.simplified() }
        if printResults {
            print("x =", solutions.map { "\($0)".replacingOccurrences(of: "x", with: "y") }.joined(separator: ", "))
        }
        
        return solutions
        
    }
    private struct Equation: CustomStringConvertible {
        var left: Expression
        var right: Expression = .y
    
        var description: String {
            return "\(left) = \("\(right)".replacingOccurrences(of: "x", with: "y"))"
        }
        
        init(expression: Expression) {
            left = expression
        }
        mutating func simplify() {
            left = left.simplified()
            right = right.simplified()
        }
        func simplified() -> Equation {
            var simplifiedEquation = self
            simplifiedEquation.simplify()
            return simplifiedEquation
        }
        
        func isolated(showingSteps: Bool = false) -> [Equation] {
            
            var equations = [Equation]()
            var equation = self
            var rhs: Expression {
                get { return equation.right }
                set { equation.right = newValue }
            }
            var lhs: Expression {
                get { return equation.left }
                set { equation.left = newValue }
            }
            if showingSteps {
                print(self)
            }
            switch lhs {
                
            // a ^ log<b>(c) = y
            // log<b>(c) * log<b>(a) = log<b>(y)
            case let .power(a, .log(b, c)) where !b.containsVariable():
                rhs = .log(b, rhs)
                lhs = .log(b, c) * .log(b, a)
                equations.append(equation)
           
            case let .power(a, .multiply(m, .log(b, c))) where !b.containsVariable(),
                 let .power(a, .multiply(.log(b, c), m)) where !b.containsVariable():
                rhs = .log(b, rhs)
                lhs = m * .log(b, c) * .log(b, a)
                equations.append(equation)
                
            // aˣ = y
            // x is odd:  a = ˣ√y
            // x is even: a = ±ˣ√y
            case let .power(a, .n(b)):
                rhs = .root(.n(b), rhs)
                lhs = a
                equations.append(equation)
                if b % 2 == 0 {
                    rhs = -rhs
                    equations.append(equation)
                }
                
            // a ^ b = y
            // blog(a) = logy
            case let .power(a, b):
                rhs = .log(2, rhs)
                lhs = b * .log(2, a)
                equations.append(equation)
                
            case let .root(a, b) where !a.containsVariable():
                rhs = rhs ^ a
                lhs = b
                equations.append(equation)
                
            // log<b>(x) = y
            // x = b ^ y
            case let .log(b, x) where !b.containsVariable():
                rhs = b ^ rhs
                lhs = x
                equations.append(equation)
                
                // log<b>(x) = y
            // b = x ^ (1 / y)
            case let .log(b, x) where !x.containsVariable():
                rhs = x ^ (1 / rhs)
                lhs = b
                equations.append(equation)
                
            // ax = y
            // x = y / a
            case let .multiply(a, b) where !a.containsVariable(),
                 let .multiply(b, a) where !a.containsVariable():
                rhs /= a
                lhs = b
                equations.append(equation)
                
            // a / b = y
            // a = by
            case let .divide(a, b) where !a.containsVariable():
                rhs *= b
                lhs = a
                equations.append(equation)
                
                
                // a / b = y
            // b = a / y
            case let .divide(a, b) where !b.containsVariable():
                rhs = a / rhs
                lhs = b
                equations.append(equation)
                
                
            // a + b = y
            // a = y - b
            case let .add(a, b) where !b.containsVariable(),
                 let .add(b, a) where !b.containsVariable():
                rhs = rhs - b
                lhs = a
                equations.append(equation)
                
            // a - b = y
            // b = a - y
            case let .subtract(a, b) where !a.containsVariable():
                rhs = a - rhs
                lhs = b
                equations.append(equation)
                
            // a - b = y
            // a = b + y
            case let .subtract(a, b) where !b.containsVariable():
                rhs = a + rhs
                lhs = a
                equations.append(equation)
                
            default:
                return [self]
            }
            
            
            return equations.flatMap { $0.simplified().isolated() }
            
        }
    }
}

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
