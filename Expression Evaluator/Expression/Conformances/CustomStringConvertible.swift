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
        case let .subtract(.n(0), .root(a, b)):
            return "(- " + Expression.root(a, b)._description + ")"
        case let .subtract(.n(0), a):
            return "-" + a._description
        case let .subtract(a, b):
            return "(" + a._description + " - " + b._description + ")"
        case let .multiply(.n(a), b),
             let .multiply(b, .n(a)) where b.isLog || b.isRoot || b.isVariable:
            return "\(a)" + b._description
        case let .multiply(a, b):
            return "(" + a._description + " * " + b._description + ")"
        case let .divide(a, b):
            return "(" + a._description + " / " + b._description + ")"
        case let .power(a, b):
            return "(" + a._description + " ^ " + b._description + ")"
        case let .log(base, n):
            var nStr = n._description
            if case .n = n { nStr = "(\(nStr))" }
            if case let .n(a) = base {
                let subscriptDict: [Character: String] = ["0" : "₀", "1" : "₁", "2" : "₂", "3" : "₃", "4" : "₄", "5" : "₅", "6" : "₆", "7" : "₇", "8" : "₈", "9" : "₉", "-" : "₋"]
                return "log" + "\(a)".reduce(into: "") { $0 += subscriptDict[$1]! } + nStr
            }
            
            return "log<" + base._description + ">" + nStr
            
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
            return "root<" + n._description + ">" + rootStr
            
        case let .n(a):
            return "\(a)"
            
        case .x:
            return "x"
        }
    }
    
}
