//
//  main.swift
//  Expression Evaluator
//
//  Created by Noah Wilder on 2019-02-19.
//  Copyright © 2019 Noah Wilder. All rights reserved.
//

import Foundation

// Operators ^, *, /, +, -

//TODO: Use custom Fraction type with big integer as numerator and denominator



/////////////////
let equation1 = "3 + (7 ^ 2 * (49 - 21) / (6 + 1) - (4 * (2 + 5))) - 2 * (7 * 5) ^ 2"
equation1.solve()

/////////////////
let equation2 = "5(4) + 320(435) - (329 + 23)(329 + 329)"
equation2.solve()

/////////////////
print(String.separatorLine)



