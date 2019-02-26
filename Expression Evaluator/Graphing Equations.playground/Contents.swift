import UIKit
//
//
//
//public protocol RegexExtensible: StringProtocol {
//    associatedtype T
//    var regex: T { get }
//}
//public extension RegexExtensible {
//    public var regex: Regex<Self> {
//        get { return Regex(self) }
//    }
//}
//public struct Regex<Base: StringProtocol> {
//    fileprivate let base: Base
//    fileprivate init(_ base: Base) {
//        self.base = base
//    }
//}
//extension String: RegexExtensible { }
//extension String.SubSequence: RegexExtensible { }
//public extension Regex where Base: StringProtocol, Base.Index == String.Index {
//
//    public func replacing<Target: StringProtocol, Replacement: StringProtocol>(pattern target: Target, with replacement: Replacement, caseInsensitive: Bool = false) -> String {
//
//        var replacementOptions: String.CompareOptions = .regularExpression
//        if caseInsensitive { replacementOptions.insert(.caseInsensitive) }
//
//        return base.replacingOccurrences(of: target, with: replacement, options: replacementOptions)
//    }
//
//    public func  doesMatch<Target: StringProtocol>(pattern regex: Target) -> Bool {
//        return base.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
//    }
//
//    public func matches<Target: StringProtocol>(pattern regex: Target, options: NSRegularExpression.MatchingOptions = []) -> [Substring] {
//        let s = String(base)
//        do {
//            let regex = try NSRegularExpression(pattern: String(regex))
//
//            let results = regex.matches(in: s, options: options, range: NSRange(s.startIndex..., in: s))
//
//            let finalResult = results.map { s[Range($0.range, in: s)!] }
//            return finalResult
//        } catch let error {
//            print("Invalid regex: \(error.localizedDescription)")
//            return []
//        }
//    }
//
//    public func numberOfMatches<Target: StringProtocol>(with pattern: Target) -> Int {
//        let s = String(base)
//
//        do {
//
//            let r = try NSRegularExpression(pattern: s)
//            return r.numberOfMatches(in: s, options: [], range: NSRange(s.startIndex..., in: s))
//
//        } catch let error {
//            print("Invalid regex: \(error.localizedDescription)")
//            return 0
//        }
//    }
//}
//
//
//extension StringProtocol where Index == String.Index {
//    func index(of string: Self, options: String.CompareOptions = []) -> Index? {
//        return range(of: string, options: options)?.lowerBound
//    }
//    func endIndex(of string: Self, options: String.CompareOptions = []) -> Index? {
//        return range(of: string, options: options)?.upperBound
//    }
//    func indexes(of string: Self, options: String.CompareOptions = []) -> [Index] {
//        var result: [Index] = []
//        var start = startIndex
//        while start < endIndex,
//            let range = self[start..<endIndex].range(of: string, options: options) {
//                result.append(range.lowerBound)
//                start = range.lowerBound < range.upperBound ? range.upperBound :
//                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
//        }
//        return result
//    }
//    func ranges(of string: Self, options: String.CompareOptions = []) -> [Range<Index>] {
//        var result: [Range<Index>] = []
//        var start = startIndex
//        while start < endIndex,
//            let range = self[start..<endIndex].range(of: string, options: options) {
//                result.append(range)
//                start = range.lowerBound < range.upperBound ? range.upperBound :
//                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
//        }
//        return result
//    }
//}
//
//extension String {
//    func braceContents(openingBraceIndex: Index) -> Substring {
//        let openingBrace = self[openingBraceIndex]
//        let closingBrace: Character
//        switch openingBrace {
//        case "[": closingBrace = "]"
//        case "(": closingBrace = ")"
//        case "{": closingBrace = "}"
//        default: fatalError("Invalid opening brace")
//        }
//        var open = 0
//        var close = 0
//        for (i, c) in zip(distance(from: startIndex, to: openingBraceIndex)..., self[openingBraceIndex...]) {
//            switch c {
//            case openingBrace: open += 1
//            case closingBrace: close += 1
//            default: continue
//            }
//            guard open != close else { return self[openingBraceIndex...index(startIndex, offsetBy: i)] }
//        }
//
//        fatalError("Invalid format, no closing brace")
//    }
//    func braceContents(closingBraceIndex: Index) -> Substring {
//        let closingBrace = self[closingBraceIndex]
//        let openingBrace: Character
//        switch closingBrace {
//        case "]": openingBrace = "["
//        case ")": openingBrace = "("
//        case "}": openingBrace = "{"
//        default: fatalError("Invalid close brace")
//        }
//        var open = 0
//        var close = 0
//        for (i, c) in zip((0...distance(from: startIndex, to: closingBraceIndex)).reversed(), self[...closingBraceIndex].reversed()) {
//            switch c {
//            case openingBrace: open += 1
//            case closingBrace: close += 1
//            default: continue
//            }
//            guard open != close else { return self[index(startIndex, offsetBy: i)...closingBraceIndex] }
//        }
//
//        fatalError("Invalid format, no closing brace")
//    }
//    func braceContentsRange(closingBraceIndex: Index) -> ClosedRange<Index> {
//        let closingBrace = self[closingBraceIndex]
//        let openingBrace: Character
//        switch closingBrace {
//        case "]": openingBrace = "["
//        case ")": openingBrace = "("
//        case "}": openingBrace = "{"
//        default: fatalError("Invalid close brace")
//        }
//        var open = 0
//        var close = 0
//        for (i, c) in zip((0...distance(from: startIndex, to: closingBraceIndex)).reversed(), self[...closingBraceIndex].reversed()) {
//            switch c {
//            case openingBrace: open += 1
//            case closingBrace: close += 1
//            default: continue
//            }
//            guard open != close else { return index(startIndex, offsetBy: i)...closingBraceIndex }
//        }
//
//        fatalError("Invalid format, no closing brace")
//    }
//    func braceContentsRange(openingBraceIndex: Index) -> ClosedRange<Index> {
//        let openingBrace = self[openingBraceIndex]
//        let closingBrace: Character
//        switch openingBrace {
//        case "[": closingBrace = "]"
//        case "(": closingBrace = ")"
//        case "{": closingBrace = "}"
//        default: print(openingBrace, " "); fatalError("Invalid opening brace")
//        }
//        var open = 0
//        var close = 0
//        for (i, c) in zip(distance(from: startIndex, to: openingBraceIndex)...   , self[openingBraceIndex...]) {
//            switch c {
//            case openingBrace: open += 1
//            case closingBrace: close += 1
//            default: continue
//            }
//            guard open != close else { return openingBraceIndex...index(startIndex, offsetBy: i) }
//        }
//
//        fatalError("Invalid format, no closing brace")
//    }
//
//}
//extension StringProtocol {
//    var escaped: String {
//        return NSRegularExpression.escapedPattern(for: String(self))
//    }
//
//    var `operator`: String {
//        let op = self.escaped
//        return "(?:\\s\(op)\\s|\(op))"
//    }
//
//    var eitherOperatorGrouped: String {
//        let op = "([\(escaped)])"
//        return "(?:\\s\(op)\\s|\(op))"
//
//    }
//
//    var plus: String {
//        return self + "+"
//    }
//
//    var grouped: String {
//        return "(\(self))"
//    }
//    var nonCapturingGrouped: String {
//        return "(?:\(self))"
//    }
//    var atomicGrouped: String {
//        return "(?>\(self))"
//    }
//    var bracketed: String {
//        return "\\(\(self)\\)"
//    }
//}
//extension NSRange {
//    func toRange(in str: String) -> Range<String.Index> {
//        return Range(self, in: str)!
//        //str.index(str.startIndex, offsetBy: lowerBound)..<str.index(str.startIndex, offsetBy: upperBound)
//    }
//    func substring(in str: String) -> Substring  {
//        return str[toRange(in: str)]
//    }
//}
//extension Array where Element == NSTextCheckingResult {
//    func captureGroups(in str: String) -> [(range: Range<String.Index>, captureGroups: [String])] {
//        var captureGroups = [(range: Range<String.Index>, captureGroups: [String])]()
//        captureGroups.reserveCapacity(count)
//
//        for match in self {
//            var captures = [String]()
//            captures.reserveCapacity(match.numberOfRanges - 1)
//            for captureGroup in 1..<match.numberOfRanges where match.range(at: captureGroup).lowerBound != NSNotFound {
//                let range = match.range(at: captureGroup)
//                captures.append(String(str[Range(range, in: str)!]))
//            }
//
//            captureGroups.append((range: Range(match.range, in: str)!, captureGroups: captures))
//        }
//        return captureGroups
//    }
//}
//extension NSTextCheckingResult {
//    func captureGroups(in str: String) -> [String] {
//        var captures = [String]()
//        for captureGroup in 1..<numberOfRanges where range(at: captureGroup).lowerBound != NSNotFound {
//            let r = range(at: captureGroup)
//            captures.append(String(str[Range(r, in: str)!]))
//        }
//        return captures
//    }
//
//    func matchedString(in str: String) -> String {
//        return String(str[Range(range, in: str)!])
//    }
//
//    func range(in str: String) -> Range<String.Index> {
//        return Range(range, in: str)!
//    }
//
//
//}
//
//let num = "[-\\+]?\\d+(?:\\.\\d+)?(?:[eE][-\\+]?\\d+(?:\\.\\d+)?)?"
//
//let exponentiationRegex = (((num.atomicGrouped + "+").grouped.bracketed + "|" + num.grouped).nonCapturingGrouped + "^".operator).nonCapturingGrouped + "+" + num.grouped
//let multiplicationDivisionRegex = ((num.grouped + "|" + num.grouped.bracketed).nonCapturingGrouped + "*/".eitherOperatorGrouped).nonCapturingGrouped + "+" + (num.grouped + "|" + num.grouped.bracketed).nonCapturingGrouped
//let additionSubtractionRegex = "(?:" + num.grouped + "+-".eitherOperatorGrouped + num.grouped + ")(?!\\()"
//
//extension String {
//
//    func removingFreeBraces() -> String {
//        return replacingOccurrences(of: "(?<![\\)\\d])" + num.grouped.bracketed, with: "$1", options: .regularExpression)
//    }
//    mutating func removeFreeBraces() {
//        self = removingFreeBraces()
//    }
//
//    @discardableResult mutating func operate(with pattern: String, operation: (Double, Double) -> Double) -> Bool {
//        let regex = try! NSRegularExpression(pattern: pattern)
//        let matches = regex.matches(in: self, options: [], range: NSRange(startIndex..., in: self))
//
//        guard matches.count > 0 else { return false }
//
//        let captures = matches.captureGroups(in: self)
//        for match in captures.reversed() {
//            guard match.captureGroups.count == 2 else { fatalError("Invalid number of capture groups in expression") }
//            let (a, b) = (Double(match.captureGroups[0])!, Double(match.captureGroups[1])!)
//            let result = operation(a, b)
//            replaceSubrange(match.range, with: "\(result)")
//        }
//
//        return true
//    }
//
//    func operated(with pattern: String, operation: (Double, Double) -> Double) -> String {
//        var str = self
//        str.operate(with: pattern, operation: operation)
//        return str
//    }
//
//
//}
//enum Operation: CaseIterable {
//    case exponentiation, multiplicationDivision, additionSubtraction //multiplication, division, addition, subtraction
//
//    static let operators = "*/^+-"
//
//    @discardableResult private func operateExponent(on str: inout String) -> Bool {
//        let pattern = exponentiationRegex
//        let regex = try! NSRegularExpression(pattern: pattern)
//        var matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex..., in: str))
//
//        guard matches.count > 0 else { return false }
//
//        matches = matches.filter { $0.range.lowerBound != NSNotFound }
//        matches.sort { $0.range.lowerBound > $1.range.lowerBound }
//
//        for match in matches {
//
//            let numbers = match.matchedString(in: str).regex.matches(pattern: num)//match.captureGroups(in: str)
//
//            guard numbers.count >= 2 else { fatalError("Invalid number of capture groups in expression") }
//
//            let result = numbers.reversed().reduce(1.0) { pow(Double($1)!, $0) }
//
//            let replacement: String
//            if match.matchedString(in: str).contains("(") {
//                replacement = "(\(result))"
//            } else {
//                replacement = "\(result)"
//            }
//
//            str.replaceSubrange(match.range.toRange(in: str), with: replacement)
//        }
//
//        return true
//    }
//    @discardableResult private func operateMultiplicationDivision(on str: inout String) -> Bool {
//        let pattern = multiplicationDivisionRegex
//        let regex = try! NSRegularExpression(pattern: pattern)
//        var firstMatch = regex.firstMatch(in: str, options: [], range: NSRange(str.startIndex..., in: str))
//
//        guard let _ = firstMatch else { return false }
//
//        while let match = firstMatch {
//
//            let matchStr = match.matchedString(in: str)
//            let numbers = matchStr.regex.matches(pattern: num)
//
//            guard numbers.count >= 2 else { fatalError("Invalid number of capture groups in expression") }
//
//            let operators: [(Double, Double) -> Double] = "*\(matchStr)".lazy.filter { $0 == "*" || $0 == "/" }.map { $0 == "*" ? (*) : (/) }
//
//            let result = zip(numbers, operators).reduce(1.0) { $1.1($0, Double($1.0)!) }
//
//            let replacement: String
//            if matchStr.contains("(") {
//                replacement = "(\(result))"
//            } else {
//                replacement = "\(result)"
//            }
//
//            str.replaceSubrange(match.range.toRange(in: str), with: replacement)
//
//            firstMatch = regex.firstMatch(in: str, options: [], range: NSRange(str.startIndex..., in: str))
//        }
//
//        return true
//    }
//    @discardableResult private func operateAdditionSubtraction(on str: inout String) -> Bool {
//        let pattern = additionSubtractionRegex
//        let regex = try! NSRegularExpression(pattern: pattern)
//        var firstMatch = regex.firstMatch(in: str, options: [], range: NSRange(str.startIndex..., in: str))
//
//        guard let _ = firstMatch else { return false }
//
//        while let match = firstMatch {
//
//            let matchStr = match.matchedString(in: str)
//            let numbers = matchStr.regex.matches(pattern: num)
//
//            guard numbers.count >= 2 else { fatalError("Invalid number of capture groups in expression") }
//
//            let operators: [(Double, Double) -> Double] = "+ \(matchStr)".regex.matches(pattern: "(?<!\\d)([\\+\\-])(?!\\d)").map { $0 == "+" ? (+) : (-) }
//
//            let result = zip(numbers, operators).reduce(0) { $1.1($0, Double($1.0)!) }
//
//            let replacement: String
//            if matchStr.contains("(") {
//                replacement = "(\(result))"
//            } else {
//                replacement = "\(result)"
//            }
//
//            str.replaceSubrange(match.range.toRange(in: str), with: replacement)
//
//            firstMatch = regex.firstMatch(in: str, options: [], range: NSRange(str.startIndex..., in: str))
//        }
//
//        return true
//    }
//
//    @discardableResult func operate(on str: inout String) -> Bool {
//        let didOperate: Bool
//        switch self {
//        case .exponentiation:
//            didOperate = operateExponent(on: &str)
//        case .multiplicationDivision:
//            didOperate = operateMultiplicationDivision(on: &str)
//        case .additionSubtraction:
//            didOperate = operateAdditionSubtraction(on: &str)
//
//            //        case .multiplication:
//            //            didOperate = str.operate(with: multiplicationRegex, operation: *)
//            //        case .division:
//            //            didOperate = str.operate(with: divisionRegex, operation: /)
//            //        case .addition:
//            //            didOperate = str.operate(with: additionRegex, operation: +)
//            //        case .subtraction:
//            //            didOperate = str.operate(with: subtractionRegex, operation: -)
//        }
//
//        // Remove free braces
//        str.removeFreeBraces()
//
//        return didOperate
//    }
//}
//func formatExpression(_ exp: String) -> String {
//    var str = exp
//
//    // Replace braces
//    let braceDict: [Character: String] = ["{" : "(", "[" : "(", "]" : ")", "}" : ")"]
//    str = str.reduce("") { $0 + (braceDict[$1] ?? "\($1)") }
//
//    // Remove free bracketed terms
//    str.removeFreeBraces()
//
//    // Add spaces between numbers and operators
//    do {
//        str = str.replacingOccurrences(of: (num + "|\\)").grouped + "([\(Operation.operators.escaped)])" + "(?=" + num + "|\\()", with: "$1 $2 ", options: .regularExpression)
//    }
//
//
//    // Fix prefix negative operator
//    do {
//        str = str.replacingOccurrences(of: "-\\(", with: "-1 * (", options: .regularExpression)
//    }
//
//
//
//    // Add exponent braces
//    do {
//
//        let regex = try! NSRegularExpression(pattern: "\\)?" + exponentiationRegex) //"\\)" + "^".operator + num
//        var matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex..., in: str))
//
//
//
//        matches = matches.filter { $0.range.lowerBound != NSNotFound }
//        matches.sort { $0.range.lowerBound > $1.range.lowerBound }
//
//        for match in matches {
//
//            var matchStr = match.matchedString(in: str)
//            var range = match.range(in: str)
//
//            if matchStr.first == ")" {
//                let braceRange = str.braceContentsRange(closingBraceIndex: range.lowerBound)
//
//                range = braceRange.lowerBound..<range.upperBound
//                matchStr = String(str[braceRange]) + matchStr
//            }
//
//            str.replaceSubrange(range, with: "(\(matchStr))")
//
//        }
//
//    }
//
//    // Replace multiplication brackets with star operator
//    do {
//
//        let regex = try! NSRegularExpression(pattern: (num.grouped + "\\(".grouped + "|" + "\\)".grouped + num.grouped + "|" + "\\)".grouped + "\\(".grouped).nonCapturingGrouped)
//
//        str = regex.stringByReplacingMatches(in: str, options: [], range: NSRange(str.startIndex..., in: str), withTemplate: "$1 * $2")
//
//    }
//
//    // Remove free bracketed terms
//    str.removeFreeBraces()
//
//    // Add multiplication and  division braces
//    do {
//        let regex = try! NSRegularExpression(pattern: (("\\)" + "|" + num.grouped).nonCapturingGrouped + "*/".eitherOperatorGrouped + (multiplicationDivisionRegex + "|" + num).nonCapturingGrouped).nonCapturingGrouped) // + "(?!\\))"
//        var matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex..., in: str))
//
//        var braceIndices = [Int]()
//
//        while matches.count != 0 {
//
//            guard let match = matches.first(where: { !braceIndices.contains($0.range.upperBound) }) else { break }
//
//            let range = match.range(in: str)
//
//            let lowerBound: String.Index
//
//            if match.matchedString(in: str).first! == ")" {
//                lowerBound = str.braceContentsRange(closingBraceIndex: str.index(str.startIndex, offsetBy: match.range.lowerBound)).lowerBound
//            } else {
//                lowerBound = range.lowerBound
//            }
//
//            str.insert(")", at: range.upperBound)
//            str.insert("(", at: lowerBound)
//
//            braceIndices.append(match.range.upperBound)
//
//            braceIndices = braceIndices.map { i in
//                var n = i
//                if match.range.upperBound < i { n += 2 }
//                else if lowerBound.encodedOffset <= i { n += 1 }
//                return n
//            }
//
//            matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex..., in: str))
//        }
//    }
//
//    // Remove free bracketed terms
//    str.removeFreeBraces()
//
//    return str
//}
//func evaluate(_ expression: String) -> Double {
//    var expression = formatExpression(expression)
//    loop: while Double(expression) == nil {
//        for operation in Operation.allCases {
//            //print(expression)
//            guard Double(expression) == nil else { break loop }
//            guard !operation.operate(on: &expression) else { continue loop }
//        }
//
//        fatalError("Invalid format, cannot evaluate any further")
//    }
//    return Double(expression)!
//}
//@discardableResult func evaluate<T: Sequence>(_ equation: String, xValues: T, printResults: Bool = true) -> [(x: T.Element, y: Double)] where T.Element: SignedNumeric {
//    var results = [(x: T.Element, y: Double)]()
//    if printResults { print("Equation:", equation, terminator: "\n\n") }
//
//    for x in xValues {
//        let tempEq = equation.replacingOccurrences(of: "x", with: "(\(x))")
//        let result = evaluate(tempEq)
//        results.append((x: x, y: result))
//        if printResults {
//            print(tempEq.removingFreeBraces(), "=", evaluate(tempEq))
//        }
//    }
//    if printResults { print() }
//    return results
//}
//@discardableResult func evaluate<T: SignedNumeric>(_ equation: String, x: T) -> (x: T, y: Double) {
//
//    let tempEq = equation.replacingOccurrences(of: "x", with: "(\(x))")
//    let result = evaluate(tempEq)
//    return (x: x, y: result)
//
//}


//let eq1 = "((-(5 - 2) * 5 / 4 + 2) + 4)"
//print(formatExpression(eq1) + "\n=", evaluate(eq1), terminator: "\n\n")
//
//let eq2 = "5 * 3 / 2 * 7(34) + 32 * 34"
//print(formatExpression(eq2) + "\n=", evaluate(eq2), terminator: "\n\n")
//
//let eq3 = "5(2)^2^2^2+3-1--5*4"
//print(formatExpression(eq3) + "\n=", evaluate(eq3), terminator: "\n\n")
//
//let eqX = "2x^2 + 5"
//evaluate(eqX, xValues: 0...21)


//func graph<T: Sequence>(equation: String, forValuesOfX xValues: T) -> UIBezierPath where T.Element: BinaryFloatingPoint & SignedNumeric {
//
//}
//extension UIImage {
//    public func image(withFrame frame: CGRect) -> UIImage {
//
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.colors = colors
//        gradientLayer.frame = frame
//
//        gradientLayer.startPoint = startPoint
//        gradientLayer.endPoint = endPoint
//
//        gradientLayer.colors = colors.map { $0.cgColor }
//
//        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
//        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
//
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        return image!
//
//    }
//}
//extension UIImage {
//    public static func gradient(of colors: [UIColor], angle: CGFloat = 90, for frame: CGRect) -> UIImage {
//        
//        var colors = colors
//        
//        if colors.isEmpty { colors = [.clear, .clear] }
//        else if colors.count == 1 { colors = [colors.first!, colors.first!] }
//        
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.colors = colors
//        gradientLayer.frame = frame
//        
//        // Set angle
//        do {
//            var angle = angle
//            if !(angle > -360 && angle < 360) {
//                angle = angle.truncatingRemainder(dividingBy: 360)
//            }
//            if angle < 0 { angle = 360 + angle }
//            
//            let tanx = { tan($0 * CGFloat.pi / 180) }
//            
//            let n: CGFloat = 0.5
//            
//            switch angle {
//            case 0...45, 315...360:
//                gradientLayer.startPoint = CGPoint(x: 0, y: n * tanx(angle) + n)
//                gradientLayer.endPoint = CGPoint(x: 1, y: n * tanx(-angle) + n)
//                
//            case 45...135:
//                gradientLayer.startPoint = CGPoint(x: n * tanx(angle - 90) + n, y: 1)
//                gradientLayer.endPoint = CGPoint(x: n * tanx(-angle - 90) + n, y: 0)
//                
//            case 135...225:
//                gradientLayer.startPoint = CGPoint(x: 1, y: n * tanx(-angle) + n)
//                gradientLayer.endPoint = CGPoint(x: 0, y: n * tanx(angle) + n)
//                
//            case 225...315:
//                gradientLayer.startPoint = CGPoint(x: n * tanx(-angle - 90) + n, y: 0)
//                gradientLayer.endPoint = CGPoint(x: n * tanx(angle - 90) + n, y: 1)
//                
//            default:
//                gradientLayer.startPoint = CGPoint(x: 0, y: n)
//                gradientLayer.endPoint = CGPoint(x: 1, y: n)
//            }
//        }
//        
//        gradientLayer.colors = colors.map { $0.cgColor }
//        
//        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
//        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
//        
//        let image = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
//        
//        return image
//        
//    }
//    public static func gradient(of colors: UIColor..., angle: CGFloat = 90, for frame: CGRect) -> UIImage {
//        return gradient(of: colors, angle: angle, for: frame)
//    }
//    public static func gradient(of colors: [UIColor], angle: CGFloat = 90, for size: CGSize) -> UIImage {
//        return gradient(of: colors, angle: angle, for: CGRect(origin: .zero, size: size))
//    }
//    public static func gradient(of colors: UIColor..., angle: CGFloat = 90, for size: CGSize) -> UIImage {
//        return gradient(of: colors, angle: angle, for: size)
//    }
//
//
//
//}
//enum Scale: Equatable {
//    case x(Double)
//    case y(Double)
//    case nonuniform(Double, Double)
//    case uniform(Double)
//    case none
//    
//    var scaleFactor: (x: Double, y: Double) {
//        switch self {
//        case let .x(x): return (x: x, y: 1)
//        case let .y(y): return (x: 1, y: y)
//        case let .nonuniform(x, y): return (x: x, y: y)
//        case let .uniform(s): return (x: s, y: s)
//        case .none: return (x: 1, y: 1)
//        }
//    }
//    
//    static func == (lhs: Scale, rhs: Scale) -> Bool {
//        return lhs.scaleFactor == rhs.scaleFactor
//    }
//    
//    static func * (lhs: Scale, rhs: Scale) -> Scale {
//        let (lhsScale, rhsScale) = (lhs.scaleFactor, rhs.scaleFactor)
//        switch (lhsScale.x * rhsScale.x, lhsScale.y * rhsScale.y) {
//        case (1, 1): return .none
//        case (let x, 1): return .x(x)
//        case (1, let y): return .y(y)
//        case let (x, y) where x == y: return .uniform(x)
//        case let (x, y): return .nonuniform(x, y)
//        }
//    }
//}
//
//enum FunctionType {
//    case linear, quadratic, cubic
//    
//    static func from(degree: Int) -> FunctionType {
//        return degree % 3 == 0 ? .cubic : (degree % 2 == 0 ? .quadratic : .linear)
//    }
//}
//func graph<T: Sequence>(equation: String, forValuesOfX xValues: T, defaultSize baseScaleSize: CGSize? = CGSize(width: 200, height: 200), scaledBy scale: Scale = .none) -> UIBezierPath where T.Element: BinaryInteger & SignedNumeric {
//    
//    guard equation.contains("x") else { fatalError("Equation needs to contain a variable to be graphable") }
////
////    let functionType: FunctionType
////    // Check if equation is linear, quadratic, or cubic
////    do {
////        let str = formatExpression(equation.replacingOccurrences(of: "x", with: "(x)"))
////        let regex = try! NSRegularExpression(pattern: "\\)" + "^".operator + num.grouped)
////
////        let matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex..., in: str))
////
////        var degree = 1
////        for match in matches where str.braceContents(closingBraceIndex: match.range(in: str).lowerBound).contains("x") {
////            let currentDegree = Int(Double(match.matchedString(in: str).regex.matches(pattern: num).first!)!.rounded())
////            print(currentDegree)
////            if currentDegree > degree { degree = currentDegree }
////        }
////
////        functionType = FunctionType.from(degree: degree)
////    }
//    
//    
//    let values = evaluate(equation, xValues: xValues, printResults: false)
//    guard let firstValue = values.first else {
//        return UIBezierPath()
//    }
//    
//    let path = UIBezierPath()
//    guard values.count > 1 else {
//        path.move(to: CGPoint(x: Double(firstValue.x), y: firstValue.y))
//        return path
//    }
//    
//    var (maxY, minY, minX, maxX) = (firstValue.y, firstValue.y, Double(firstValue.x), Double(firstValue.x))
//    
//    
//    var points = [CGPoint]()
//    points.reserveCapacity(values.count)
//    
//    for value in values {
//        if value.y > maxY { maxY = value.y }
//        if value.y < minY { minY = value.y }
//        if Double(value.x) < minX { minX = Double(value.x) }
//        if Double(value.x) > maxX { maxX = Double(value.x) }
//
//        let point = CGPoint(x: Double(value.x), y: value.y)
//        points.append(point)
//    }
//    // Sort by increasing values of x then by increasing values of y
//    points.sorted { $0.x != $1.x ? $0.x < $1.x : $0.y < $1.y }
//    
//    // First and last points on the parabola
//    guard let a = points.first, let b = points.last else { fatalError("Impossible!") }
//    print(a, b)
//
//    path.move(to: a)
//    for p in points[1...] {
//        path.addLine(to: p)
//    }
//    
////    switch functionType {
////    case .linear:
////        path.addLine(to: b)
////        
////    case .quadratic:
//////        let controlPoint = CGPoint(x: (a.x + b.x) / 2,
//////                                   y: ((a.x + b.x) / 2) * 2 * )
////        var (controlPoint, vertex) = (CGPoint(), CGPoint())
////        
////        vertex.x = (a.x - b.x) / 2 //(max(a.x, b.x) + 1).rounded()//(a.x + b.x) / 2
////        
////        
////        // Ensure a.x and b.x are not equal to randX and adjust randX by 1 accordingly
//////        switch (a.x, b.x) {
//////        case (randX, randX): randX += 1;
//////        case (randX + 1, randX), (randX, randX + 1): randX -= 1;
//////        case (randX - 1, randX), (randX, randX - 1): randX += 1;
//////        default: break
//////        }
////        
////        vertex.y = CGFloat(evaluate(equation, x: vertex.x).y)
////        
////        controlPoint.x = 2 * vertex.x - a.x / 2 - b.x / 2
////        controlPoint.y = 2 * vertex.y - a.y / 2 - b.y / 2
////        
////        path.addQuadCurve(to: b, controlPoint: controlPoint)
////        
////    case .cubic:
////        #warning("Fuck, I need to do this!")
////        fatalError("Fuck, you still need to implement this. Don't try me!")
////        
////    }
//   
//    // Apply default scale
//    if let defaultScaleSize = baseScaleSize {
//        let uniformScaleFactor = min(defaultScaleSize.width / CGFloat(maxX), defaultScaleSize.height / CGFloat(maxY))
//        path.apply(CGAffineTransform(scaleX: uniformScaleFactor, y: uniformScaleFactor))
//        //CGAffineTransform(scaleX: defaultScaleSize.width / CGFloat(maxX), y: defaultScaleSize.height / CGFloat(maxY))
//    }
//    
//    if scale != .none {
//        let scaleFactor = scale.scaleFactor
//        let scaleTransformation = CGAffineTransform(scaleX: CGFloat(scaleFactor.x), y: CGFloat(scaleFactor.y))
//        
//        // Apply specified transformation
//        path.apply(scaleTransformation)
//    }
//    
//    // Find vertex so can add translation to prevent negative values for bounds of path
//    print(path.bounds)
//    
//    // Present view
//    
////    let bounds = path.bounds
////    let maxDimension = max(bounds.size.width, bounds.size.height)
////    let view = UIView()
////    view.frame = CGRect(origin: .zero, size: CGSize(width: maxDimension, height: maxDimension))
////    let graphLayer = CAShapeLayer
////    let fillColor = UIColor.gradient(of: .red, .yellow, for: bounds)
//    
////    fillColor.setFill()
////    path.fill()
//    
//   // path.fill
//
//    return path
//}
//
//// Iterate through string from innermost parentheses outward to change Equation to a recursive enum
//// Determine the degree of an equation
//
//let graphingEquation = "x^2"//"3x^1 + 5"
////print(formatExpression(graphingEquation.replacingOccurrences(of: "x", with: "(x)")))
//graph(equation: graphingEquation, forValuesOfX: -9...9)


// Learn how to use blend mode






//    var randX1 = max(a.x, b.x) + 1
//    var randX2 = min(a.x, b.x) - 1
//
//    var (controlPoint1, controlPoint2) = (CGPoint(), CGPoint())
//
//
//    controlPoint1.x = a.x + ((2 / 3) * (controlPoint.x - a.x))
//    controlPoint2.x = b.x + ((2 / 3) * (controlPoint.x - b.x))
//
//    path.addCurve(to: a, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
