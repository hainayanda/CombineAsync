//
//  PublisherAsyncSpec.swift
//  CombineAsync_Example
//
//  Created by Nayanda Haberty on 29/9/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Combine
import CombineAsync

class PublisherAsyncSpec: QuickSpec {
    
    override class func spec() {
        var subject: PassthroughSubject<Int, TestError>!
        var cancellable: AnyCancellable?
        beforeEach {
            cancellable = nil
            subject = .init()
        }
        it("should sink asynchronously") {
            var sinkOutput: Int?
            var input: Int = .random(in: -100..<100)
            waitUntil { done in
                cancellable = subject.asyncSink { _ in } receiveValue: { output in
                    try await Task.sleep(nanoseconds: 10_000)
                    sinkOutput = output
                    done()
                }
                subject.send(input)
            }
            cancellable?.cancel()
            expect(sinkOutput).to(equal(input))
        }
        
    }
}

class AsyncPublisherAsyncSpec: AsyncSpec {
    
    override class func spec() {
        var subject: CurrentValueSubject<Int, TestError>!
        var value: Int!
        beforeEach {
            value = .random(in: -100..<100) * 2
            subject = .init(value)
        }
        it("should async map successfully") {
            let output = try await subject.asyncMap(testMap).sinkAsynchronously()
            expect(output).to(equal("\(value!)"))
        }
        it("should async try map successfully") {
            let output = try await subject.asyncTryMap(testTryMap).sinkAsynchronously()
            expect(output).to(equal("\(value!)"))
        }
        it("should async compact map successfully") {
            let output = try await subject.asyncCompactMap(testCompactMap).sinkAsynchronously()
            expect(output).to(equal("\(value!)"))
        }
        it("should async try compact map successfully") {
            let output = try await subject.asyncTryCompactMap(testTryCompactMap).sinkAsynchronously()
            expect(output).to(equal("\(value!)"))
        }
    }
}

private func testTryMap(_ input: Int) async throws -> String {
    try await Task.sleep(nanoseconds: 10_000)
    return "\(input)"
}

private func testMap(_ input: Int) async -> String {
    do {
        try await Task.sleep(nanoseconds: 10_000)
    } catch { }
    return "\(input)"
}

private func testTryCompactMap(_ input: Int) async throws -> String? {
    try await Task.sleep(nanoseconds: 10_000)
    return input % 2 == 0 ? "\(input)": nil
}

private func testCompactMap(_ input: Int) async -> String? {
    do {
        try await Task.sleep(nanoseconds: 10_000)
    } catch { }
    return input % 2 == 0 ? "\(input)": nil
}