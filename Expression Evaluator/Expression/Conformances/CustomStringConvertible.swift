//
//  CustomStringConvertible.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation


extension Expression: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return description
    }
    public var description: String {
        return _description.strippingOutermostBraces()
    }
    
    private var _description: String {
        switch self {
        case let .add(a, b):
            return "(" + a._description + " + " + b._description + ")"


        case let .subtract(.n(0), a):
            let aStr = a._description
            return aStr.hasPrefix("-") ? String(aStr.dropFirst()) : "-" + aStr
            
        case let .subtract(a, b):
            let bStr = b._description
            
            return "(" + a._description + (bStr.hasPrefix("-") ? " + \(bStr.dropFirst())" : " - \(bStr)") + ")"
            
            
        case .multiply:
            var chain = self.multiplicationChain()
            let sign = chain.enumerated().reduce(into: 1) { signum, term in
                if term.element.isNegative {
                    chain[term.offset] = -term.element
                    signum.negate()
                }
            }
            chain.sort {
                switch ($0, $1) {
                case (.n, _): return true
                case (_, .n): return false
                case (.x, _): return true
                case (_, .x): return false
                case (.log, _): return false
                case (_, .log): return true
                default: return true
                }
            }
            if case let (.n(a), .x) = (chain[0], chain[1]) {
                return (sign == -1 ? "-\(a)x" : "\(a)x") + (chain.count > 2 ? chain.dropFirst(2).map { $0.isLog ? $0._description : "(" + $0._description.strippingOutermostBraces() + ")" }.joined() : "")
            } else if case let (.n(a)) = chain[0] {
                return (sign == -1 ? "-\(a)" : "\(a)") + chain.dropFirst().map { $0.isLog ? $0._description : "(" + $0._description.strippingOutermostBraces() + ")" }.joined()
            } else if case (.x) = chain[0] {
                return (sign == -1 ? "-x" : "x") + chain.dropFirst().map { $0.isLog ? $0._description : "(" + $0._description.strippingOutermostBraces() + ")" }.joined()
            } else {
                return chain.map { $0.isLog ? $0._description : "(" + $0._description.strippingOutermostBraces() + ")" }.joined()
            }
            
        case let .divide(a, b):
            return "(" + a._description + " / " + b._description + ")"
        case let .power(a, b):
            return "(" + a._description + " ^ " + b._description + ")"
        case let .log(base, n):
            var nStr = n._description
            if !(n.isVariable || (n.isNumber && !n.isNegative)) {
                nStr = "(" + nStr.strippingOutermostBraces() + ")"
            }
            
            if base == 10 {
                return "log" + nStr
            }
            if case let .n(a) = base {
                
                let subscriptDict: [Character: String] = ["0" : "₀", "1" : "₁", "2" : "₂", "3" : "₃", "4" : "₄", "5" : "₅", "6" : "₆", "7" : "₇", "8" : "₈", "9" : "₉", "-" : "₋"]
                return "log" + "\(a)".reduce(into: "") { $0 += subscriptDict[$1]! } + nStr
            }
            
            
            return "log<" + base._description.strippingOutermostBraces() + ">" + nStr
            
        case let .root(n, root):
            var rootStr = root._description
            if case .n = root { rootStr = "(\(rootStr))" }
            if case .x = n {
                return "ˣ√" + rootStr
            }
            if case let .n(a) = n {
                switch a {
                case 2: return "√(" + root._description.strippingOutermostBraces() + ")"
                    //                case 3: return "∛(" + root._description + ")"
                //                case 4: return "∜(" + root._description + ")"
                default:
                    let superscriptDict: [Character: String]  = ["0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",  "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "-": "⁻"]
                    
                    return "\(a)".reduce(into: "") { $0 += superscriptDict[$1]! } + "√" + rootStr
                }
            }
            return "root<" + n._description.strippingOutermostBraces() + ">" + rootStr
            
        case let .n(a):
            return "\(a)"
            
        case .x:
            return "x"
        }
    }
    
}

extension Expression {
    func multiplicationChain() -> [Expression] {
        guard case let .multiply(a, b) = self else {
            return [self]
        }
        
        return [a, b].flatMap { $0.multiplicationChain() }
    }
}




/*
 
 case let .subtract(a, b):
 return "(" + a._description + " - " + b._description + ")"
 case let .multiply(a, b) where a.isDivision && (b.isLog || b.isPower || b.isRoot || b.isSubtraction || b.isAddition),
 let .multiply(b, a) where a.isDivision && (b.isLog || b.isPower || b.isRoot || b.isSubtraction || b.isAddition):
 if b.isNegative {
 return (-a)._description + (-b)._description
 }
 return a._description + b._description
 
 case let .multiply(.n(a), b) where b.isLog || b.isPower || b.isRoot || b.isSubtraction || b.isAddition,
 let .multiply(b, .n(a)) where b.isLog || b.isPower || b.isRoot || b.isSubtraction || b.isAddition:
 if b.isNegative {
 return "\(-a)" + b._description.dropFirst()
 }
 return "\(a)" + b._description
 case let .multiply(.multiply(.n(a), .x), b) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition || b.isLog,
 let .multiply(.multiply(.x, .n(a)), b) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition || b.isLog,
 let .multiply(b, .multiply(.n(a), .x)) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition || b.isLog,
 let .multiply(b, .multiply(.x, .n(a))) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition || b.isLog:
 if b.isNegative {
 return "\(-a)x" + b._description.dropFirst()
 }
 return "\(a)x" + b._description
 
 case let .multiply(.x, n) where !n.isVariable && !n.isMultiplication,
 let .multiply(n, .x) where !n.isVariable && !n.isMultiplication:
 if n.isNegative {
 return "-x" + n._description.dropFirst()
 }
 return "x" + n._description
 case let .multiply(.subtract(0, .x), .n(n)),
 let .multiply(.n(n), .subtract(0, .x)):
 if n < 0 {
 return "\(n)x"
 }
 return "-\(n)x"
 case let .multiply(.x, .n(n)),
 let .multiply(.n(n), .x):
 if n < 0 {
 return "-\(n)x"
 }
 return "\(n)x"
 
 case let .multiply(.subtract(0, .x), n) where !n.isVariable && !n.isMultiplication,
 let .multiply(n, .subtract(0, .x)) where !n.isVariable && !n.isMultiplication:
 if n.isNegative {
 return "x" + n._description.dropFirst()
 }
 return "-x" + n._description
 
 */
