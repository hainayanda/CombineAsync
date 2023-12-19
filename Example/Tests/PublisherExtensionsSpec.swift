//
//  PublisherExtensionsSpec.swift
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

class PublisherExtensionsAsyncSpec: AsyncSpec {
    
    override class func spec() {
        describe("publisher to async") {
            context("with error") {
                var subject: PassthroughSubject<Int, TestError>!
                beforeEach {
                    subject = .init()
                }
                afterEach {
                    subject.send(completion: .finished)
                }
                it("should successfully return value") {
                    subject.sendAfter(0.1, input: 10_000)
                    await expect { try await subject.sinkAsynchronously() }.to(equal(10_000))
                }
                it("should throw expected error") {
                    subject.sendAfter(0.1, completion: .failure(.expectedError))
                    await expect { try await subject.sinkAsynchronously() }.to(throwError(TestError.expectedError))
                }
                it("should throw no value error") {
                    subject.sendAfter(0.1, completion: .finished)
                    await expect { try await subject.sinkAsynchronously() }.to(throwError(PublisherToAsyncError.finishedButNoValue))
                }
                it("should throw timeout error") {
                    subject.sendAfter(0.2, input: 10_000)
                    await expect { try await subject.sinkAsynchronously(timeout: 0.1) }.to(throwError(PublisherToAsyncError.timeout))
                }
            }
            context("without error") {
                var subject: PassthroughSubject<Int, Never>!
                beforeEach {
                    subject = .init()
                }
                afterEach {
                    subject.send(completion: .finished)
                }
                it("should successfully return value") {
                    subject.sendAfter(0.1, input: 10_000)
                    await expect { await subject.sinkAsynchronously() }.to(equal(10_000))
                }
                it("should ignore no value error") {
                    subject.sendAfter(0.1, completion: .finished)
                    await expect { await subject.sinkAsynchronously() }.to(beNil())
                }
                it("should ignore timeout error") {
                    subject.sendAfter(0.2, input: 10_000)
                    await expect { await subject.sinkAsynchronously(timeout: 0.1) }.to(beNil())
                }
            }
        }
    }
}

class PublisherExtensionsSyncSpec: QuickSpec {
    
    // swiftlint:disable function_body_length
    override class func spec() {
        describe("assign") {
            var subject: PassthroughSubject<Int, Never>!
            var object: DummyObject!
            context("weak") {
                var cancellable: AnyCancellable?
                beforeEach {
                    subject = .init()
                    object = .init()
                }
                afterEach {
                    object = nil
                    cancellable?.cancel()
                    cancellable = nil
                }
                it("should not retain the object") {
                    weak var weakRef = object
                    cancellable = subject.weakAssign(to: \.number, on: object)
                    object = nil
                    expect(weakRef).to(beNil())
                }
                it("should assign the value to the object") {
                    cancellable = subject.weakAssign(to: \.number, on: object)
                    let toAssign = Int.random(in: 0..<100)
                    subject.send(toAssign)
                    expect(object.number).toEventually(equal(toAssign))
                }
            }
            context("auto release") {
                beforeEach {
                    subject = .init()
                    object = .init()
                }
                afterEach {
                    object = nil
                }
                it("should not retain the object") {
                    weak var weakRef = object
                    subject.autoReleaseAssign(to: \.number, on: object)
                    object = nil
                    expect(weakRef).to(beNil())
                }
                it("should assign the value to the object") {
                    subject.autoReleaseAssign(to: \.number, on: object)
                    let toAssign = Int.random(in: 0..<100)
                    subject.send(toAssign)
                    expect(object.number).toEventually(equal(toAssign))
                }
            }
        }
        describe("error replacement") {
            var subject: PassthroughSubject<Int, TestError>!
            var result: ResultWrapper<Int, TestError>!
            var cancellable: AnyCancellable?
            beforeEach {
                subject = .init()
                result = .init()
            }
            afterEach {
                result = nil
                cancellable?.cancel()
                cancellable = nil
            }
            context("ignore error") {
                it("should successfully return value") {
                    subject.sendAfter(0.1, input: 10_000)
                    cancellable = subject.ignoreError()
                        .sinkTest(for: result)
                    expect(result.wrapped).toEventually(equal(.success(10_000)))
                }
                it("should ignore the error") {
                    subject.sendAfter(0.1, completion: .failure(.expectedError))
                    cancellable = subject.ignoreError()
                        .sinkTest(for: result)
                    expect(result.wrapped).toAlways(equal(.failure(.initialError)))
                }
            }
            context("recover on error") {
                it("should successfully return value") {
                    subject.sendAfter(0.1, input: 10_000)
                    cancellable = subject.replaceError { _ in -1 }
                        .sinkTest(for: result)
                    expect(result.wrapped).toEventually(equal(.success(10_000)))
                }
                it("should replace the error") {
                    subject.sendAfter(0.1, completion: .failure(.expectedError))
                    cancellable = subject.replaceError { _ in -1 }
                        .sinkTest(for: result)
                    expect(result.wrapped).toEventually(equal(.success(-1)))
                }
            }
            context("recover on error if needed") {
                it("should successfully return value") {
                    subject.sendAfter(0.1, input: 10_000)
                    cancellable = subject.replaceErrorIfNeeded { _ in -1 }
                        .sinkTest(for: result)
                    expect(result.wrapped).toEventually(equal(.success(10_000)))
                }
                it("should replace the error if needed") {
                    subject.sendAfter(0.1, completion: .failure(.expectedError))
                    cancellable = subject.replaceErrorIfNeeded { _ in -1 }
                        .sinkTest(for: result)
                    expect(result.wrapped).toEventually(equal(.success(-1)))
                }
                it("should not replace the error") {
                    subject.sendAfter(0.1, completion: .failure(.expectedError))
                    cancellable = subject.replaceErrorIfNeeded { _ in nil }
                        .sinkTest(for: result)
                    expect(result.wrapped).toEventually(equal(.failure(.expectedError)))
                }
            }
        }
    }
    // swiftlint:enable function_body_length
}

private class DummyObject {
    var number: Int = 0
}
