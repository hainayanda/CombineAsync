//
//  TestError.swift
//  CombineAsync_Tests
//
//  Created by Nayanda Haberty on 24/5/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation

enum TestError: Error {
    case expectedError
    case unexpectedError
    case initialError
}
