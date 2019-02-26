//
//  Quick Regex Functions.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-22.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

public extension String {
    public func r(_ s: String...) -> String {
        return s.reduce(self, +)
    }
    public func rEsc(fixCharSets: Bool = true) -> String {
        var escapedString = NSRegularExpression.escapedPattern(for: self)
        if fixCharSets {
            escapedString = escapedString.replacingOccurrences(of: "\\\\", with: "\\")
        }
        return escapedString
    }
    public func rGroup(_ groupType: RegexGroup = .capturing) -> String {
        return groupType.apply(to: self)
    }
    public func rOperator() -> String {
        let op = rEsc
        return ("\\s\(op)\\s|\(op)").rGroup()
    }
    public func rChars(escaped: Bool = true) -> String {
        return "[\((escaped ? rEsc() : self))]"
    }
    public func rBracketed() -> String {
        return "\\(\(self)\\)"
    }
    public func rOr(_ s: String..., group: RegexGroup = .capturing) -> String { return group.apply(to: self + "|" + s.joined(separator: "|")) }

}

public func rGroup(_ s: String, _ group: RegexGroup = .capturing) -> String { return group.apply(to: s) }
public func rEsc(_ s: String, fixCharSets: Bool = true) -> String {
    var escapedString = NSRegularExpression.escapedPattern(for: s)
    if fixCharSets {
        escapedString = escapedString.replacingOccurrences(of: "\\\\", with: "\\")
    }
    return escapedString
    
}
public let rOperator: (String) -> String = { let op = $0.rEsc(); return "\\s\(op)\\s".rOr(op).rGroup(.nonCapturing) }
public func rOr(_ s: String..., group: RegexGroup = .capturing) -> String { return group.apply(to: s.joined(separator: "|")) }
public func rChars(_ s: String..., escaped: Bool = true) -> String { return "[\(escaped ? rEsc(s.joined()) : s.joined())]" }
public let rBracketed: (String) -> String = { "\\(\($0)\\)" }



public enum RegexGroup {
    case capturing, nonCapturing, atomic, positiveLookahead, negativeLookahead, positiveLookbehind, negativeLookbehind, comment, none
    
    func apply(to str: String) -> String {
        switch self {
        case .capturing: return "(" + str + ")"
        case .nonCapturing: return "(?:" + str + ")"
        case .atomic: return "(?>" + str + ")"
        case .positiveLookahead: return "(?<=" + str + ")"
        case .negativeLookahead: return "(?<!" + str + ")"
        case .positiveLookbehind: return "(?=" + str + ")"
        case .negativeLookbehind: return "(?!" + str + ")"
        case .comment: return "(?#" + str + ")"
        case .none: return str
        }
    }
}






//
//public protocol QuickRegexExtensible: StringProtocol {
//    associatedtype T
//    var r: T { get }
//}
//public extension QuickRegexExtensible {
//    public var r: QuickRegex<Self> {
//        get { return QuickRegex(self) }
//    }
//}
//public struct QuickRegex<Base: StringProtocol> {
//    fileprivate let base: Base
//    fileprivate init(_ base: Base) {
//        self.base = base
//    }
//}
//
//extension String: QuickRegexExtensible { }
//extension String.SubSequence: QuickRegexExtensible { }
//public extension QuickRegex where Base: StringProtocol, Base.Index == String.Index {
//
//    func `_`(_ s: String...) -> String {
//        return s.reduce(String(base), +)
//    }
//    func esc(fixCharSets: Bool = true) -> String {
//        var escapedString = NSRegularExpression.escapedPattern(for: String(base))
//        if fixCharSets {
//            escapedString = escapedString.replacingOccurrences(of: "\\\\", with: "\\")
//        }
//        return escapedString
//    }
//    func group(_ groupType: RegexGroup = .capturing) -> String {
//        return groupType.apply(to: String(base))
//    }
//    func `operator`() -> String {
//        let op = rEsc
//        return ("\\s\(op)\\s|\(op)").rGroup()
//    }
//    func chars(escaped: Bool = true) -> String {
//        return "[\((escaped ? esc() : String(base)))]"
//    }
//    func bracketed() -> String {
//        return "\\(\\)"
//    }
//}
