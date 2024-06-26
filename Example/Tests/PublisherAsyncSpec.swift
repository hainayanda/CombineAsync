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

private class Wrapper<Wrapped> {
    var value: Wrapped
    
    init(value: Wrapped) {
        self.value = value
    }
}

class PublisherAsyncSpec: AsyncSpec {
    
    override class func spec() {
        var subject: PassthroughSubject<Int, TestError>!
        var cancellable: AnyCancellable?
        beforeEach {
            cancellable = nil
            subject = .init()
        }
        it("should sink asynchronously") {
            let sinkOutput: Wrapper<Int?> = .init(value: nil)
            let input: Int = .random(in: -100..<100)
            await waitUntil { done in
                cancellable = subject.asyncSink { _ in } receiveValue: { output in
                    try await Task.sleep(nanoseconds: 10_000)
                    sinkOutput.value = output
                    done()
                }
                subject.send(input)
            }
            cancellable?.cancel()
            expect(sinkOutput.value).to(equal(input))
        }
        it("should sink asynchronously with debounce behavior") {
            let sinkOutputs: Wrapper<[Int]> = .init(value: [])
            cancellable = subject.debounceAsyncSink { _ in } receiveValue: { output in
                try? await Task.sleep(nanoseconds: 1_000)
                sinkOutputs.value.append(output)
            }
            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(4)
            subject.send(5)
            await expect(sinkOutputs.value).toEventually(equal([1, 5]))
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
            let output = try await subject.asyncMap(testMap).waitForOutputIndefinitely()
            expect(output).to(equal("\(value!)"))
        }
        it("should async try map successfully") {
            let output = try await subject.asyncTryMap(testTryMap).waitForOutputIndefinitely()
            expect(output).to(equal("\(value!)"))
        }
        it("should async compact map successfully") {
            let output = try await subject.asyncCompactMap(testCompactMap).waitForOutputIndefinitely()
            expect(output).to(equal("\(value!)"))
        }
        it("should async try compact map successfully") {
            let output = try await subject.asyncTryCompactMap(testTryCompactMap).waitForOutputIndefinitely()
            expect(output).to(equal("\(value!)"))
        }
    }
}

@Sendable private func testTryMap(_ input: Int) async throws -> String {
    try await Task.sleep(nanoseconds: 10_000)
    return "\(input)"
}

@Sendable private func testMap(_ input: Int) async -> String {
    do {
        try await Task.sleep(nanoseconds: 10_000)
    } catch { }
    return "\(input)"
}

@Sendable private func testTryCompactMap(_ input: Int) async throws -> String? {
    try await Task.sleep(nanoseconds: 10_000)
    return input % 2 == 0 ? "\(input)": nil
}

@Sendable private func testCompactMap(_ input: Int) async -> String? {
    do {
        try await Task.sleep(nanoseconds: 10_000)
    } catch { }
    return input % 2 == 0 ? "\(input)": nil
}
