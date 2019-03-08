//
//  Operator.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-25.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

public enum Operator: CaseIterable {
    case addition
    case subtraction
    case multiplication
    case division
    case exponentiation
    
    public enum Associativity {
        case left, right
    }
    
    public static let allOperators = Operator.allCases.map { $0.symbol }
    public static let allOperatorsString = allOperators.joined()
    public static let groupedByPrecedence = [(operators: [Operator.exponentiation],    associativity: Associativity.right),
                                             (operators: [.division, .multiplication], associativity: .left),
                                             (operators: [.addition, .subtraction],    associativity: .left)]
    
    public var symbol: String {
        switch self {
        case .addition: return "+"
        case .subtraction: return "-"
        case .multiplication: return "*"
        case .division: return "/"
        case .exponentiation: return "^"
        }
    }
    public var associativity: Associativity {
        switch self {
        case .addition: return .left
        case .subtraction: return .left
        case .multiplication: return .left
        case .division: return .left
        case .exponentiation: return .right
        }
    }
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


