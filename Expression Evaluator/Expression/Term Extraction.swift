//
//  Term Extraction.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

public extension Expression {
    
    enum Extraction {
        case allTerms(Expression)
        case singleTerm(Expression, x: Expression)
        case none(Expression)
    }
    
    @discardableResult public func extractNonVariableTerms() -> Extraction {
        
        switch self {
        case .x:
            return .none(.x)
        case .n:
            return .allTerms(self)
        case let .add(a, b):
            let extractionA = a.extractNonVariableTerms()
            let extractionB = b.extractNonVariableTerms()
            
            switch (extractionA, extractionB) {
            case (.none, .none):
                return .none(self)
                
            case (.allTerms, .allTerms):
                return .allTerms(self)
                
            case let (.allTerms(a), .none(b)),
                 let (.none(b), .allTerms(a)):
                return .singleTerm(a, x: b)
                
            case let (.allTerms(a), .singleTerm(b1, x: b2)),
                 let (.singleTerm(b1, x: b2), .allTerms(a)):
                return .singleTerm(a + b1, x: b2)
                
            case let (.singleTerm(a1, x: a2), .singleTerm(b1, x: b2)):
                return .singleTerm(a1 + b1, x: a2 + b2)
                
            case let (.singleTerm(a1, x: a2), .none(b)),
                 let (.none(b), .singleTerm(a1, x: a2)):
                return .singleTerm(a1, x: a2 + b)
                
            }
            
            
        case let .subtract(a, b):
            let extractionA = a.extractNonVariableTerms()
            let extractionB = b.extractNonVariableTerms()
            
            switch (extractionA, extractionB) {
            case (.none, .none):
                return .none(self)
                
            case (.allTerms, .allTerms):
                return .allTerms(self)
                
            case let (.allTerms(a), .none(b)):
                return .singleTerm(a, x: -b)
                
            case let (.none(b), .allTerms(a)):
                return .singleTerm(-a, x: b)
                
            case let (.allTerms(a), .singleTerm(b1, x: b2)):
                return .singleTerm(a - b1, x: -b2)
                
            case let (.singleTerm(b1, x: b2), .allTerms(a)):
                return .singleTerm(b1 - a, x: b2)
                
                
            case let (.singleTerm(a1, x: a2), .singleTerm(b1, x: b2)):
                return .singleTerm(a1 - b1, x: a2 - b2)
                
            case let (.singleTerm(a1, x: a2), .none(b)):
                return .singleTerm(a1, x: a2 - b)
                
            case let (.none(b), .singleTerm(a1, x: a2)):
                return .singleTerm(-a1, x: b - a2)
                
            }
            
        case let .multiply(a, b):
            let extractionA = a.extractNonVariableTerms()
            let extractionB = b.extractNonVariableTerms()
            
            switch (extractionA, extractionB) {
            case (.none, .none):
                return .none(self)
                
            case (.allTerms, .allTerms):
                return .allTerms(self)
                
            case let (.allTerms(a), .none(b)),
                 let (.none(b), .allTerms(a)):
                return .none(a * b)
                
            // a(b + x) -> ab, ax
            case let (.allTerms(a), .singleTerm(b, x: x)),
                 let (.singleTerm(b, x: x), .allTerms(a)):
                return .singleTerm(a * b, x: a * x)
                
            //(a + x)(b + y) -> ab, ay + bx + xy
            case let (.singleTerm(a, x: x), .singleTerm(b, x: y)):
                return .singleTerm(a * b, x: (a * y) + (b * x) + (x * y))
                
                
            case let (.singleTerm(a, x: x), .none(y)),
                 let (.none(y), .singleTerm(a, x: x)):
                return .none((y * a) + (y * x))
                
            }
        case let .divide(a, b):
            
            let extractionA = a.extractNonVariableTerms()
            let extractionB = b.extractNonVariableTerms()
            
            switch (extractionA, extractionB) {
            case (.none, .none):
                return .none(self)
                
            case (.allTerms, .allTerms):
                return .allTerms(self)
                
            case (.allTerms, .none),
                 (.none, .allTerms):
                return .none(self)
                
            case let (.allTerms(a), .singleTerm(b, x: x)):
                return .none(a / (b + x))
                
            case let (.singleTerm(a, x: x), .allTerms(b)):
                return .singleTerm(a / b, x: x / b)
                
                
            case let (.singleTerm(a, x: x), .singleTerm(b, x: y)):
                return .none((a + x) / (b + y))
                
            case let (.singleTerm(a, x: x), .none(y)):
                return .none((a + x) / y)
                
            case let (.none(x), .singleTerm(a, x: y)):
                return .none(x / (a + y))
                
            }
            
        case let .power(a, b):
            let extractionA = a.extractNonVariableTerms()
            let extractionB = b.extractNonVariableTerms()
            
            switch (extractionA, extractionB) {
            case (.none, .none):
                return .none(self)
                
            case (.allTerms, .allTerms):
                return .allTerms(self)
                
            case (.allTerms, .none),
                 (.none, .allTerms):
                return .none(self)
                
            case let (.allTerms(a), .singleTerm(b1, x: b2)):
                return .none((a ^ b1) * (a ^ b2))
                
            case let (.singleTerm(b1, x: b2), .allTerms(a)):
                return .none((b1 + b2) ^ a)
                
            case let (.singleTerm(a1, x: a2), .singleTerm(b1, x: b2)):
                return .none(((a1 + a2) ^ b1) * ((a1 + a2) ^ b2))
                
            case let (.singleTerm(a1, x: a2), .none(b)):
                return .none((a1 + a2) ^ b)
                
            case let (.none(b), .singleTerm(a1, x: a2)):
                return .none((b ^ a1) * (b ^ a2))
                
            }
        case let .log(a, b):
            
            let extractionA = a.extractNonVariableTerms()
            let extractionB = b.extractNonVariableTerms()
            
            switch (extractionA, extractionB) {
            case let (.none(a), .none(b)):
                return .none(.log(a, b))
                
            case let (.allTerms(a), .allTerms(b)):
                return .allTerms(.log(a, b))
                
            case let (.allTerms(a), .none(b)),
                 let (.none(a), .allTerms(b)):
                return .none(.log(a, b))
                
            case let (.allTerms(a), .singleTerm(b1, x: b2)):
                return .none(.log(a, b1 + b2))
                
            case let (.singleTerm(b1, x: b2), .allTerms(a)):
                return .none(.log(b1 + b2, a))
                
            case let (.singleTerm(a1, x: a2), .singleTerm(b1, x: b2)):
                return .none(.log(a1 + a2, b1 + b2))
                
            case let (.singleTerm(a1, x: a2), .none(b)):
                return .none(.log(a1 + a2, b))
                
            case let (.none(b), .singleTerm(a1, x: a2)):
                return .none(.log(b, a1 + a2))
                
            }
            
            
            
        case let .root(a, b):
            
            let extractionA = a.extractNonVariableTerms()
            let extractionB = b.extractNonVariableTerms()
            
            switch (extractionA, extractionB) {
            case let (.none(a), .none(b)):
                return .none(.root(a, b))
                
            case let (.allTerms(a), .allTerms(b)):
                return .allTerms(.root(a, b))
                
            case let (.allTerms(a), .none(b)),
                 let (.none(a), .allTerms(b)):
                return .none(.root(a, b))
                
            case let (.allTerms(a), .singleTerm(b1, x: b2)):
                return .none(.root(a, b1 + b2))
                
            case let (.singleTerm(b1, x: b2), .allTerms(a)):
                return .none(.root(b1 + b2, a))
                
            case let (.singleTerm(a1, x: a2), .singleTerm(b1, x: b2)):
                return .none(.root(a1 + a2, b1 + b2))
                
            case let (.singleTerm(a1, x: a2), .none(b)):
                return .none(.root(a1 + a2, b))
                
            case let (.none(b), .singleTerm(a1, x: a2)):
                return .none(.root(b, a1 + a2))
                
            }
            
        }
    }
}
