//
//  SequenceExtensionsSpec.swift
//  CombineAsync_Example
//
//  Created by Nayanda Haberty on 24/5/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Combine
import CombineAsync

class SequenceExtensionsAsyncSpec: AsyncSpec {
    
    override class func spec() {
        let array = [1, 2, 3, 4, 5]
        it("should map array asynchronously") {
            await expect { try await array.asyncMap(testMap(_:)) }.to(equal(["1", "2", "3", "4", "5"]))
        }
        it("should compact map array asynchronously") {
            await expect { try await array.asyncCompactMap(testCompactMap(_:)) }.to(equal(["2", "4"]))
        }
    }
}

class SequenceExtensionsSyncSpec: QuickSpec {
    
    override class func spec() {
        describe("map sequence") {
            let array = [1, 2, 3, 4, 5]
            var result: ResultWrapper<[String], TestError>!
            var cancellable: AnyCancellable?
            beforeEach {
                result = .init()
            }
            afterEach {
                result = nil
                cancellable?.cancel()
                cancellable = nil
            }
            it("should map array asynchronously") {
                cancellable = array.futureMap(testMap(_:))
                    .sinkTest(for: result)
                expect(result.wrapped).toEventually(equal(.success(["1", "2", "3", "4", "5"])))
            }
            it("should compact map array asynchronously") {
                cancellable = array.futureCompactMap(testCompactMap(_:))
                    .sinkTest(for: result)
                expect(result.wrapped).toEventually(equal(.success(["2", "4"])))
            }
        }
    }
}

private func testMap(_ input: Int) async throws -> String {
    try await Task.sleep(nanoseconds: 10_000)
    return "\(input)"
}

private func testCompactMap(_ input: Int) async throws -> String? {
    try await Task.sleep(nanoseconds: 10_000)
    return input % 2 == 0 ? "\(input)": nil
}
