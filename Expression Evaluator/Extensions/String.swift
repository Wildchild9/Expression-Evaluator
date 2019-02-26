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
    
    @discardableResult public func solve(showingSteps: Bool = true, printOverheadLine: Bool = true) -> Expression {
        let expression = Expression(self)
        let result = expression.evaluate()
        
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
}
