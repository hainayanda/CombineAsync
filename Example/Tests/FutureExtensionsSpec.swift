//
//  FutureExtensionsSpec.swift
//  CombineAsync_Tests
//
//  Created by Nayanda Haberty on 24/5/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Combine
import CombineAsync

class FutureExtensionsSpec: QuickSpec {
    override class func spec() {
        describe("async to future") {
            context("should create working Future object from async") {
                var result: ResultWrapper<Int, TestError>!
                var cancellable: AnyCancellable?
                beforeEach {
                    result = .init()
                }
                afterEach {
                    cancellable?.cancel()
                    cancellable = nil
                }
                it("should emit a value") {
                    cancellable = Future { try await asyncInt() }
                        .sinkTest(for: result)
                    
                    expect(result.wrapped).toEventually(equal(.success(10_000)))
                }
                it("should emit an error") {
                    cancellable = Future { try await asyncInt(error: true) }
                        .sinkTest(for: result)
                    
                    expect(result.wrapped).toEventually(equal(.failure(.expectedError)))
                }
            }
        }
    }
}

// MARK: Helper function

private func asyncInt(error: Bool = false) async throws -> Int {
    try await Task.sleep(nanoseconds: 10_000)
    guard error else { return 10_000 }
    throw TestError.expectedError
}
