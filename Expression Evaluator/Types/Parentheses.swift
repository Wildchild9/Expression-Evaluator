//
//  Parentheses.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-25.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation



public struct Parentheses: Hashable, CustomStringConvertible {
    public var depth, number: Int
    public var contents: Substring
    public var startIndex: String.Index { return contents.startIndex }
    public var endIndex: String.Index { return contents.endIndex }
    
    public var contentsWithoutParentheses: Substring {
        return contents[contents.index(after: contents.startIndex)..<contents.index(before: contents.endIndex)]
    }
    public var description: String {
        return "(\(depth), \(number)) -> \"\(contents)\""
    }
}

public func extractParentheses(in str: String) -> [Parentheses] {
    
    var parentheticChanges = [(depth: Int, index: String.Index)]()
    var parentheticChange = (depth: 0, index: str.startIndex) {
        didSet {
            parentheticChanges.append(parentheticChange)
        }
    }
    
    for (i, c) in zip(str.indices, str) {
        if c == "(" {
            parentheticChange = (depth: parentheticChange.depth + 1, index: i)
        } else if c == ")" {
            parentheticChange = (depth: parentheticChange.depth - 1, index: i)
        }
    }
    guard parentheticChange.depth == 0 else { fatalError("Invalid parenthetic format. Parentheses must be in pairs.") }
    
    var parentheses = [Parentheses]()
    parentheses.reserveCapacity(parentheticChanges.count / 2)
    
    var parentheticLevels = [Int: Int]()
    var idx = 0
    while idx < parentheticChanges.count {
        let openingParenthesis = parentheticChanges[idx]
        
        parentheticLevels[openingParenthesis.depth, default: 0] += 1
        let parenthesesNumberInLevel = parentheticLevels[openingParenthesis.depth]!
        
        guard let closingParenthesisIndex = parentheticChanges[(idx + 1)...].firstIndex(where: { $0.depth == openingParenthesis.depth - 1 }) else {
            fatalError("Invalid parenthetic format.")
        }
        let closingParenthesis = parentheticChanges.remove(at: closingParenthesisIndex)
        
        let parenthesesRange = openingParenthesis.index...closingParenthesis.index
        let parenthesesContents = str[parenthesesRange]
        let parenthesis = Parentheses(depth: openingParenthesis.depth, number: parenthesesNumberInLevel, contents: parenthesesContents)
        parentheses.append(parenthesis)
        
        idx += 1
    }
    
    parentheses.sort { $0.depth == $1.depth ? $0.number < $1.number : $0.depth < $1.depth }
    
    return parentheses
}
