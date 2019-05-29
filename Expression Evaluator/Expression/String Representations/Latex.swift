//
//  Latex.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

public extension Expression {
    var latex: String {
        return _latex.strippingOutermostBraces()
    }
    private var _latex: String {
        switch self {
        case let .add(a, b):
            return "\\left(" + a._latex + " + " + b._latex + "\\right)"
        case let .subtract(0, n):
            return "-" + n._latex
        case let .subtract(a, b):
            return "\\left(" + a._latex + " - " + b._latex + "\\right)"
        case let .multiply(a, b) where a.isDivision && (b.isLog || b.isPower || b.isRoot || b.isSubtraction || b.isAddition),
             let .multiply(b, a) where a.isDivision && (b.isLog || b.isPower || b.isRoot || b.isSubtraction || b.isAddition):
            if b.isNegative {
                return (-a)._latex + (-b)._latex
            }
            return a._latex + b._latex
            
        case let .multiply(.n(a), b) where b.isLog || b.isPower || b.isRoot || b.isSubtraction || b.isAddition,
             let .multiply(b, .n(a)) where b.isLog || b.isPower || b.isRoot || b.isSubtraction || b.isAddition:
            if b.isNegative {
                return "\(-a)" + b._latex.dropFirst()
            }
            return "\(a)" + b._latex
            
        case let .multiply(.multiply(.n(a), .x), b) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition,
             let .multiply(.multiply(.x, .n(a)), b) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition,
             let .multiply(b, .multiply(.n(a), .x)) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition,
             let .multiply(b, .multiply(.x, .n(a))) where b.isPower || b.isRoot || b.isSubtraction || b.isAddition:
            if b.isNegative {
                return "\(-a)x" + b._latex.dropFirst()
            }
            return "\(a)x" + b._latex
            
        case let .multiply(.x, n) where n.isPower || n.isRoot || n.isSubtraction || n.isAddition,
             let .multiply(n, .x) where n.isPower || n.isRoot || n.isSubtraction || n.isAddition:
            if n.isNegative {
                return "-x" + n._latex.dropFirst()
            }
            return "x" + n._latex
        case let .multiply(a, b):
            return "\\left(" + a._latex + " \\cdot " + b._latex + "\\right)"
        case let .divide(a, b):
            return "\\frac{" + a._latex.strippingOutermostBraces() + "}{" + b._latex.strippingOutermostBraces() + "}"
        case let .power(a, b):
            return a._latex + "^{" + b._latex.strippingOutermostBraces() + "}"
        case let .log(a, b):
            let strA = a.isDivision || a.isPower || a.isRoot ? "\\left(\(a._latex)\\right)" : a._latex
            let strB = b.isDivision || b.isPower || b.isRoot ? "\\left(\(b._latex)\\right)" : b._latex
            return "\\mathrm{log}_{" + strA + "}" + strB
        case let .root(2, n):
            return "\\sqrt{" + n._latex + "}"
        case let .root(a, b):
            return "\\sqrt[" + a._latex + "]{" + b._latex + "}"
        case let .n(a):
            return a < 0 ? "\\left(\(a)\\right)" : "\(a)"
        case .x:
            return "x"
        }
    }
}
