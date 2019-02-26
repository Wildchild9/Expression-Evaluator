//
//  Collection.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-25.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation


public extension Collection {
    
    /// Returns the element at the given index if it exists, otherwise returns `nil`.
    ///
    /// - Parameter index: The index of the desired element.
    ///
    /// - Returns: An optional element at the given index. Value is `nil` if the index does not exist, otherwise the element is returned.
    ///
    public subscript(safe index: Index) -> Element? {
        return startIndex <= index && index < endIndex ? self[index] : nil
    }
    
}

