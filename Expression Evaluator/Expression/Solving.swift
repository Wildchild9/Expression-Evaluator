//
//  Solving.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

public extension Expression {
    
    
    @discardableResult func solveForX(printResults: Bool = true, showingSteps: Bool = false) -> [Expression]? {
        guard containsVariable() else { return nil }
        
        let expression = self.simplified()
        if printResults || showingSteps {
            print("y =", expression)
        }
        let equation = Equation(expression: expression)
        let results = equation.isolated(showingSteps: showingSteps)
        
        
        guard results.allSatisfy({ $0.left.isVariable }) else {
            if printResults || showingSteps {
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
        var right: Expression
        
        var description: String {
            return oneSided ? "\(left) = \("\(right)".replacingOccurrences(of: "x", with: "y"))" : "\(left) = \(right)"
        }
        
        private var oneSided: Bool
        
        init(expression: Expression) {
            left = expression
            right = .y
            oneSided = true
        }
        
        mutating func simplify() {
            left.simplify()
            right.simplify()
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
                lhs = m * (.log(b, c) * .log(b, a))
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
            case let .divide(a, b) where !b.containsVariable():
                rhs *= b
                lhs = a
                equations.append(equation)
                
                
            // a / b = y
            // b = a / y
            case let .divide(a, b) where !a.containsVariable():
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
                let extractedTerm = lhs.extractTerms(containingVariables: false)
                switch extractedTerm {
                case .none:
                    return [self]
                case let .singleTerm(a, x: b):
                    lhs = b
                    rhs -= a
                    equations.append(equation)
                case let .allTerms(a):
                    lhs -= a
                    rhs = 0
                    equations.append(equation)

                    return equations
                }
            }
            
            return equations.flatMap { $0.simplified().isolated(showingSteps: showingSteps) }
            
        }
    }
}
