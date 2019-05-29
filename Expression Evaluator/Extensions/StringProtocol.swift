//
//  StringProtocol.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-25.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation


public extension StringProtocol {
    func leadingCount(where predicate: (Character) throws -> Bool) rethrows -> Int {
        var leadingCount = 0
        for char in self {
            guard try predicate(char) else { return 0 }
            leadingCount += 1
        }
        return leadingCount
    }
    func leadingCount(of character: Character) -> Int {
        var leadingCount = 0
        for char in self {
            guard char == character else { return 0 }
            leadingCount += 1
        }
        return leadingCount
    }
    func trailingCount(where predicate: (Character) throws -> Bool) rethrows -> Int {
        var leadingCount = 0
        for char in reversed() {
            guard try predicate(char) else { return 0 }
            leadingCount += 1
        }
        return leadingCount
    }
    func trailingCount(of character: Character) -> Int {
        var leadingCount = 0
        for char in reversed() {
            guard char == character else { return 0 }
            leadingCount += 1
        }
        return leadingCount
    }
}


public extension StringProtocol where Index == String.Index {
    func index(of string: Self, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }
    func endIndex(of string: Self, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
    func indices(of string: Self, options: String.CompareOptions = []) -> [Index] {
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
    func ranges(of string: Self, options: String.CompareOptions = []) -> [Range<Index>] {
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
    
    var nsRange: NSRange {
        return NSRange(startIndex..<endIndex, in: self)
    }
    var range: Range<String.Index> {
        return startIndex..<endIndex
    }
}

