//
//  Either.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-03-05.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation


public enum Either<A, B> {
    case left(A)
    case right(B)
}
