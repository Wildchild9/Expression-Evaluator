//
//  ExpressibleByIntegerLiteral.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

extension Expression: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    
    public init(integerLiteral value: Expression.IntegerLiteralType) {
        self = .n(value)
    }
}

