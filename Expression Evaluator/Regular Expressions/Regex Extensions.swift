//
//  Regex.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-22.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

public protocol RegexExtensible: StringProtocol {
    associatedtype T
    var regex: T { get }
}
public extension RegexExtensible {
    public var regex: Regex<Self> {
        get {
            return Regex(base: self)
        }
    }
}
public struct Regex<Base: StringProtocol> {
    fileprivate let base: Base
    fileprivate init(base: Base) {
        self.base = base
    }
}
extension String: RegexExtensible { }
extension String.SubSequence: RegexExtensible { }


public extension Regex where Base: StringProtocol, Base.Index == String.Index {
    
    public func replacing<Target: StringProtocol, Replacement: StringProtocol>(pattern target: Target, with replacement: Replacement, caseInsensitive: Bool = false) -> String {
        
        let str = base
        
        var replacementOptions: String.CompareOptions = .regularExpression
        if caseInsensitive { replacementOptions.insert(.caseInsensitive) }
        
        return str.replacingOccurrences(of: target, with: replacement, options: replacementOptions)
    }
    
    public func  doesMatch<Target: StringProtocol>(pattern regex: Target) -> Bool {
        let str = base

        return str.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    public func matches<Target: StringProtocol>(pattern regex: Target, options: NSRegularExpression.MatchingOptions = []) -> [Substring] {
        return matches(pattern: regex, options: options, in: base.startIndex..<base.endIndex)
    }
    
    public func matches<Target: StringProtocol, Region: RangeExpression>(pattern regex: Target, options: NSRegularExpression.MatchingOptions = [], in region: Region) -> [Substring] where Region.Bound == Base.Index {
        
        let s = String(base)
        
        do {
            let regex = try NSRegularExpression(pattern: String(regex))
            
            let results = regex.matches(in: s, options: options, range: NSRange(region.relative(to: s), in: s))
            
            let finalResult = results.map { s[Range($0.range, in: s)!] }
            return finalResult
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    public func numberOfMatches<Target: StringProtocol>(with pattern: Target) -> Int {
        let s = String(base)
        
        do {
            let r = try NSRegularExpression(pattern: s)
            return r.numberOfMatches(in: s, options: [], range: NSRange(s.startIndex..., in: s))
            
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
            return 0
        }
    }
}

public extension Regex where Base == String {
    
    public func replacing<Target: StringProtocol, Replacement: StringProtocol>(pattern target: Target, options: NSRegularExpression.Options = [], with replacement: (_ match: Substring, _ captureGroups: [Substring]) -> Replacement) -> String {
        
        var str = base
        
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: String(target), options: options)
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
            return str
        }
        
        let matches = regex.matches(in: str, range: str.nsRange)
        var replacements = [(range: Range<String.Index>, replacement: String)]()
        replacements.reserveCapacity(matches.count)
        
        for match in matches {
            let matchSubstring = match.matchedString(in: str)
            let captureGroupSubstrings = match.captureGroups(in: str)
            let matchReplacement = String(replacement(matchSubstring, captureGroupSubstrings))
            
            replacements.append((range: match.range(in: str), replacement: matchReplacement))
        }
        
        replacements.sorted { $0.range.lowerBound > $1.range.lowerBound }
                    .forEach { str.replaceSubrange($0.range, with: $0.replacement) }
        
        return str
        
    }
}

public extension NSTextCheckingResult {
    public func range(in str: String) -> Range<String.Index> {
        return Range(range, in: str)!
    }
    
    public func matchedString(in str: String) -> Substring {
        return str[range(in: str)]
    }
    
    public func captureGroups(in str: String) -> [Substring] {
        var captures = [Substring]()
        for captureGroupNumber in 1..<numberOfRanges where range(at: captureGroupNumber).lowerBound != NSNotFound {
            let captureGroupRange = range(at: captureGroupNumber)
            captures.append(str[captureGroupRange.range(in: str)])
        }
        return captures
    }
    
}
public extension NSRange {
    public func range(in str: String) -> Range<String.Index> {
        return Range(self, in: str)!
    }
}

/*
public protocol RegexExtensible: StringProtocol {
    associatedtype T
    var regex: T { mutating get }
}
public extension RegexExtensible {
    public var regex: Regex<Self> {
        mutating get { return Regex(&self) }
    }
}
public struct Regex<Base: StringProtocol> {
    fileprivate let base: UnsafeMutablePointer<Base>
    fileprivate init(_ base: UnsafeMutablePointer<Base>) {
        self.base = base
    }
}


public struct Regex<Base: StringProtocol> {
    fileprivate var base: UnsafeMutablePointer<Base>
    fileprivate init(_ base: UnsafeMutablePointer<Base>) {
        self.base = base
    }
}
public struct MutableRegex<Base: StringProtocol> {
    fileprivate let base: UnsafeMutablePointer<Base>
    fileprivate init(_ base: UnsafeMutablePointer<Base>) {
        self.base = base
    }
}
 
*/
