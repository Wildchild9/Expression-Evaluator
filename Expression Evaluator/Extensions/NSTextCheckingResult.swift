//
//  NSTextCheckingResult.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-25.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

public extension Array where Element == NSTextCheckingResult {
    func captureGroups(in str: String) -> [(range: Range<String.Index>, captureGroups: [String])] {
        var captureGroups = [(range: Range<String.Index>, captureGroups: [String])]()
        captureGroups.reserveCapacity(count)
        
        for match in self {
            var captures = [String]()
            captures.reserveCapacity(match.numberOfRanges - 1)
            for captureGroup in 1..<match.numberOfRanges where match.range(at: captureGroup).lowerBound != NSNotFound {
                let range = match.range(at: captureGroup)
                captures.append(String(str[Range(range, in: str)!]))
            }
            
            captureGroups.append((range: Range(match.range, in: str)!, captureGroups: captures))
        }
        return captureGroups
    }
}
