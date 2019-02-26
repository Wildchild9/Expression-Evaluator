//
//  Operator.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-25.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

public enum Operator {
    case addition
    case subtraction
    case multiplication
    case division
    case exponentiation
    
    public static let allOperators = "^*/+-"
    
    public var operation: (Double, Double) -> Double {
        switch self {
        case .addition: return (+)
        case .subtraction: return (-)
        case .multiplication: return (*)
        case .division: return (/)
        case .exponentiation: return pow
        }
    }
    public init? <T: StringProtocol>(_ string: T) {
        switch string {
        case "+": self = .addition
        case "-": self = .subtraction
        case "*": self = .multiplication
        case "/": self = .division
        case "^": self = .exponentiation
        default: return nil
        }
        
    }
    
}




extension Operator: CustomStringConvertible {
    public var description: String {
        switch self {
        case .addition: return "+"
        case .subtraction: return "-"
        case .multiplication: return "*"
        case .division: return "/"
        case .exponentiation: return "^"
        }
    }
}


