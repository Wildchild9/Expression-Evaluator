//
//  StringProtocol.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-25.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation


public extension StringProtocol {
    public func leadingCount(where predicate: (Character) throws -> Bool) rethrows -> Int {
        var leadingCount = 0
        for char in self {
            guard try predicate(char) else { return 0 }
            leadingCount += 1
        }
        return leadingCount
    }
    public func leadingCount(of character: Character) -> Int {
        var leadingCount = 0
        for char in self {
            guard char == character else { return 0 }
            leadingCount += 1
        }
        return leadingCount
    }
    public func trailingCount(where predicate: (Character) throws -> Bool) rethrows -> Int {
        var leadingCount = 0
        for char in reversed() {
            guard try predicate(char) else { return 0 }
            leadingCount += 1
        }
        return leadingCount
    }
    public func trailingCount(of character: Character) -> Int {
        var leadingCount = 0
        for char in reversed() {
            guard char == character else { return 0 }
            leadingCount += 1
        }
        return leadingCount
    }
}


public extension StringProtocol where Index == String.Index {
    public func index(of string: Self, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }
    public func endIndex(of string: Self, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
    public func indices(of string: Self, options: String.CompareOptions = []) -> [Index] {
        var result: [Index] = []
        var start = startIndex
        while start < endIndex,
            let range = self[start..<endIndex].range(of: string, options: options) {
                result.append(range.lowerBound)
                start = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
    public func ranges(of string: Self, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var start = startIndex
        while start < endIndex,
            let range = self[start..<endIndex].range(of: string, options: options) {
                result.append(range)
                start = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
    
    public var nsRange: NSRange {
        return NSRange(startIndex..<endIndex, in: self)
    }
    public var range: Range<String.Index> {
        return startIndex..<endIndex
    }
}

