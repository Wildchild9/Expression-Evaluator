//
//  Expression Formatting.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-25.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

public let numberRegex = "[-\\+]?\\d+(?:\\.\\d+)?(?:[eE][-\\+]?\\d+)?"


public func applyFormatting<T: StringProtocol>(to equation: T) -> String {
    
    let operators = Operator.allOperatorsString
    
    var str = String(equation)
    
    // Replace other braces with parentheses
    do {
        let braceDict: [Character: String] = ["{" : "(", "[" : "(", "]" : ")", "}" : ")"]
        str = str.reduce("") { $0 + (braceDict[$1] ?? "\($1)") }
    }
    
    
    // Space binary operators
    do {
        str = str.replacingOccurrences(of: rOr(numberRegex, "\\)") + operators.rEsc().rChars().rGroup() + rOr(numberRegex, "\\(", group: .positiveLookbehind), with: "$1 $2 ", options: .regularExpression)
    }
    
    
    // Replace parenthetic multiplication with star operator
    do {
        let parentheticMultiplicationPattern = rOr("(\(numberRegex))\\s*(?=\\()", "(\\))\\s*(?=\(numberRegex))", "(\\))\\s*(?=\\()", group: .none)
        
        str = str.replacingOccurrences(of: parentheticMultiplicationPattern, with: "$1$2$3 * ", options: .regularExpression)
    }
    
    // Fix prefix negative operator
    do {
        if let firstCharacter = str.first, firstCharacter == "-" {
            str.replaceSubrange(str.startIndex...str.startIndex, with: "0 - ")
        }
        
        str = str.replacingOccurrences(of: "-(?=\\(|\\d)", with: "0 - ", options: .regularExpression)
    }
    
    str = str.removingExtraParantheses()
    
    
    
    return str
    
}

public extension StringProtocol {
    public func formatEquation() -> String {
        return applyFormatting(to: self)
    }
}
