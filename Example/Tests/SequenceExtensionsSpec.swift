//
//  SequenceExtensionsSpec.swift
//  CombineAsync_Example
//
//  Created by Nayanda Haberty on 5/4/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Combine
import CombineAsync

class SequenceExtensionsSpec: AsyncSpec {
    
    // swiftlint:disable function_body_length
    override class func spec() {
        context("Failure is Never") {
            var subject1: PassthroughSubject<Int, Never>!
            var subject2: PassthroughSubject<Int, Never>!
            var subjects: [PassthroughSubject<Int, Never>]!
            beforeEach {
                subject1 = .init()
                subject2 = .init()
                subjects = [subject1, subject2]
            }
            it("should wait for all outputs") {
                subject1.sendAfter(0.1, input: 1)
                subject2.sendAfter(0.1, input: 1)
                let output = await subjects.waitForOutputsIndefinitely()
                expect(output).to(equal([1, 1]))
            }
            it("should wait for all outputs with timeout") {
                subject1.sendAfter(0.1, input: 1)
                subject2.sendAfter(0.1, input: 1)
                let output = await subjects.waitForOutputs(timeout: 0.2)
                expect(output).to(equal([1, 1]))
            }
            it("should fail for all outputs with timeout") {
                subject1.sendAfter(0.2, input: 1)
                subject2.sendAfter(0.2, input: 1)
                let output = await subjects.waitForOutputs(timeout: 0.1)
                expect(output).to(equal([nil, nil]))
            }
        }
        context("Failure is Error") {
            var subject1: PassthroughSubject<Int, TestError>!
            var subject2: PassthroughSubject<Int, TestError>!
            var subjects: [PassthroughSubject<Int, TestError>]!
            beforeEach {
                subject1 = .init()
                subject2 = .init()
                subjects = [subject1, subject2]
            }
            it("should wait for all outputs") {
                subject1.sendAfter(0.1, input: 1)
                subject2.sendAfter(0.1, input: 1)
                let output = try await subjects.waitForOutputsIndefinitely()
                expect(output).to(equal([1, 1]))
            }
            it("should wait for all outputs with timeout") {
                subject1.sendAfter(0.1, input: 1)
                subject2.sendAfter(0.1, input: 1)
                let output = try await subjects.waitForOutputs(timeout: 0.2)
                expect(output).to(equal([1, 1]))
            }
            it("should fail for all outputs with timeout") {
                let subjects = subjects!
                subject1.sendAfter(0.2, input: 1)
                subject2.sendAfter(0.2, input: 1)
                do {
                    _ = try await subjects.waitForOutputs(timeout: 0.1)
                    fail("should throw error")
                } catch {
                    expect(error as? CombineAsyncError).to(equal(CombineAsyncError.timeout))
                }
            }
            it("should throw error") {
                let subjects = subjects!
                subject1.sendAfter(0.1, completion: .failure(.expectedError))
                subject2.sendAfter(0.1, input: 1)
                do {
                    _ = try await subjects.waitForOutputs(timeout: 0.2)
                    fail("should throw error")
                } catch {
                    expect(error as? TestError).to(equal(TestError.expectedError))
                }
            }
        }
    }
    // swiftlint:enable function_body_length
}
