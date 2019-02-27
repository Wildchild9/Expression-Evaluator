//
//  Benchmarking.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-26.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

/// Benchmarks program execution.
///
/// Supports specific labeling, multiple tests, a setup closure, and printing benchmarking results.
///
/// - Parameters:
///     - label: The name of the process being benchmarked. Used for printing benchmarking results. Default value is `nil`.
///     - tests: The number of times to run the process and average the execution time over. **Must be greater than 0.** Default value is 1.
///     - print: A boolean value that indicates whether the function should print the benchmarking results. Default value is `true`.
///     - setup: A closure that is called before each benchmark is run. This is not recorded as part of the benchmark. Used to setup code that will be run within the `execute` closure. Default value is an empty closure.
///     - execute: A closure containing the code that is measured and benchmarked. **Cannot be empty.**
///
/// - Returns: A `Double` value of the average execution time of the benchmarked code. The return value is discardable and does not need to be used.
///
@_transparent @discardableResult public func measure<T>(label: T? = nil, tests: Int = 1, print: Bool = true, setup: @escaping () -> Void = { return }, execute: @escaping () -> Void) -> Double where T: StringProtocol {
    
    guard tests > 0 else { fatalError("Number of tests must be greater than 0") }
    
    var avgExecutionTime : CFAbsoluteTime = 0
    for _ in 1...tests {
        setup()
        let start = CFAbsoluteTimeGetCurrent()
        execute()
        let end = CFAbsoluteTimeGetCurrent()
        avgExecutionTime += end - start
    }
    
    avgExecutionTime /= CFAbsoluteTime(tests)
    
    if print {
        var avgTimeStr = "\(avgExecutionTime)"
        
        if let exponentRange = avgTimeStr.range(of: "(e|E)[-\\+]?\\d+", options: .regularExpression) {
            let superscriptDict: [Character : String] = ["+" : "⁺", "-" : "⁻", "0" : "⁰", "1" : "¹", "2" : "²", "3" : "³", "4" : "⁴", "5" : "⁵", "6" : "⁶", "7" : "⁷", "8" : "⁸", "9" : "⁹"]
            let n = Int(avgTimeStr[avgTimeStr[exponentRange].range(of: "[-|\\+]?\\d+", options: .regularExpression)!])!
            avgTimeStr.replaceSubrange(exponentRange, with: " × 10" + "\(n)".reduce("") { $0 + (superscriptDict[$1] ?? "") })
        }
        
        
        if let label = label {
            Swift.print(label, "▿")
            Swift.print("\tExecution time: \(avgTimeStr)s")
            Swift.print("\tNumber of tests: \(tests)\n")
        } else {
            Swift.print("Execution time: \(avgTimeStr)s")
            Swift.print("Number of tests: \(tests)\n")
        }
    }
    
    return avgExecutionTime
}
