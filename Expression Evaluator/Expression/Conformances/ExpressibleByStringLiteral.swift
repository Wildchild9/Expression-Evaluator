//
//  ExpressibleByStringLiteral.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-11.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

extension Expression: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: Expression.StringLiteralType) {
        self.init(value)
    }
    
    public typealias ExtendedGraphemeClusterLiteralType = String
    
    public init(extendedGraphemeClusterLiteral value: Expression.ExtendedGraphemeClusterLiteralType) {
        self.init(value)
    }
    
    public typealias UnicodeScalarLiteralType = String
    
    public init(unicodeScalarLiteral value: Expression.UnicodeScalarLiteralType) {
        self.init(value)
    }
    
    
}
