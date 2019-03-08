//
//  String.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-25.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

public extension String {
    public static func horizontalLine(ofLength n: Int) -> String {
        return String(repeating: " ̶", count: n)
    }
    
    public static var separatorLine: String {
        return String.horizontalLine(ofLength: 100)
    }
    
    @discardableResult public func solve(withX x: Double? = nil, showingSteps: Bool = true, printOverheadLine: Bool = true) -> Expression {
        let expression = Expression(self)
        let result = expression.evaluate(withX: x)
        
        if showingSteps {
            if printOverheadLine {
                print(String.separatorLine)
            }
            print(self)
            print("=", expression)
            print("=", result)
        }
        
        return expression
    }
    
    
    public func strippingOutermostBraces() -> String {
        print(self)
        let str = hasPrefix("\\left") ? dropFirst(5) : self[...]
        guard let firstCharacter = str.first else { return self }
        let braces: [(opening: Character, closing: Character)] = [("(", ")"), ("[", "]"), ("{", "}"), ("<", ">")]
        
        guard let bracePair = braces.first(where: { $0.opening == firstCharacter }), str.last == bracePair.closing else {
            return self
        }
        var level = 0
        for c in str.dropLast() {
            switch c {
            case bracePair.opening:
                level += 1
                
            case bracePair.closing:
                level -= 1
            default: break
            }
            guard level != 0 else { return self }
        }
        guard level == 1 else {
            return self
        }
        if hasSuffix("\\right\(bracePair.closing)") {
            print(String(str[str.index(after: str.startIndex)..<str.index(str.endIndex, offsetBy: -7)]))
            return String(str[str.index(after: str.startIndex)..<str.index(str.endIndex, offsetBy: -7)])
        }
        print(String(str[index(after: startIndex)..<index(before: endIndex)]))
        return String(str[index(after: startIndex)..<index(before: endIndex)])
    }
}
