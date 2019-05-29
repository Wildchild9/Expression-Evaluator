//
//  String Integer Subscript.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-25.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation


public extension StringProtocol {
    subscript (i: Int) -> Element {
        return self[index(startIndex, offsetBy: i)]
    }
    subscript (bounds: CountableClosedRange<Int>) -> SubSequence {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start...end]
    }
    
    subscript (bounds: CountableRange<Int>) -> SubSequence {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start..<end]
    }
    
    subscript (bounds: PartialRangeUpTo<Int>) -> SubSequence {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex..<end]
        
    }
    subscript (bounds: PartialRangeThrough<Int>) -> SubSequence {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex...end]
    }
    subscript (bounds: CountablePartialRangeFrom<Int>) -> SubSequence {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        return self[start..<endIndex]
    }
}


public extension String {
    subscript (i: Int) -> Element {
        get {
            return self[index(startIndex, offsetBy: i)]
        }
        set {
            let idx = index(startIndex, offsetBy: i)
            replaceSubrange(idx...idx, with: [newValue])
        }
    }
    subscript (bounds: CountableClosedRange<Int>) -> SubSequence {
        get {
            let start = index(startIndex, offsetBy: bounds.lowerBound)
            let end = index(startIndex, offsetBy: bounds.upperBound)
            return self[start...end]
        }
        set {
            let start = index(startIndex, offsetBy: bounds.lowerBound)
            let end = index(startIndex, offsetBy: bounds.upperBound)
            replaceSubrange(start...end, with: newValue)
        }
    }
    subscript (bounds: CountableRange<Int>) -> SubSequence {
        get {
            let start = index(startIndex, offsetBy: bounds.lowerBound)
            let end = index(startIndex, offsetBy: bounds.upperBound)
            return self[start..<end]
        }
        set {
            let start = index(startIndex, offsetBy: bounds.lowerBound)
            let end = index(startIndex, offsetBy: bounds.upperBound)
            replaceSubrange(start..<end, with: newValue)
        }
    }
    subscript (bounds: PartialRangeUpTo<Int>) -> SubSequence {
        get {
            let end = index(startIndex, offsetBy: bounds.upperBound)
            return self[startIndex..<end]
        }
        set {
            let end = index(startIndex, offsetBy: bounds.upperBound)
            replaceSubrange(startIndex..<end, with: newValue)
        }
    }
    subscript (bounds: PartialRangeThrough<Int>) -> SubSequence {
        get {
            let end = index(startIndex, offsetBy: bounds.upperBound)
            return self[startIndex...end]
        }
        set {
            let end = index(startIndex, offsetBy: bounds.upperBound)
            replaceSubrange(startIndex...end, with: newValue)
        }
    }
    subscript (bounds: CountablePartialRangeFrom<Int>) -> SubSequence {
        get {
            let start = index(startIndex, offsetBy: bounds.lowerBound)
            return self[start..<endIndex]
        }
        set {
            let start = index(startIndex, offsetBy: bounds.lowerBound)
            replaceSubrange(start..<endIndex, with: newValue)
        }
    }
}

