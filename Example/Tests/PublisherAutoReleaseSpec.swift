//
//  PublisherAutoReleaseSpec.swift
//  CombineAsync_Example
//
//  Created by Nayanda Haberty on 18/6/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Combine
import CombineAsync

class PublisherAutoReleaseSpec: AsyncSpec {
    
    // swiftlint:disable function_body_length
    override class func spec() {
        var subject: PassthroughSubject<Int, TestError>!
        beforeEach {
            subject = .init()
        }
        it("should release the cancellable after completion") {
            var completion: Subscribers.Completion<TestError>?
            var value: Int?
            weak var cancellable = subject.autoReleaseSink { comp in
                completion = comp
            } receiveValue: { val in
                value = val
            }
            expect(cancellable).toNot(beNil())
            subject.send(1)
            expect(cancellable).toNot(beNil())
            await expect(value).toEventually(equal(1))
            subject.send(completion: .finished)
            await expect(completion).toEventually(equal(.finished))
            expect(cancellable).to(beNil())
        }
        it("should release the cancellable after error") {
            var completion: Subscribers.Completion<TestError>?
            var value: Int?
            weak var cancellable = subject.autoReleaseSink { comp in
                completion = comp
            } receiveValue: { val in
                value = val
            }
            expect(cancellable).toNot(beNil())
            subject.send(1)
            expect(cancellable).toNot(beNil())
            await expect(value).toEventually(equal(1))
            subject.send(completion: .failure(.expectedError))
            await expect(completion).toEventually(equal(.failure(.expectedError)))
            expect(cancellable).to(beNil())
        }
        it("should release the cancellable after object released") {
            var retaining: RetainingObject? = RetainingObject()
            var completion: Subscribers.Completion<TestError>?
            var value: Int?
            let cancellable = subject.autoReleaseSink(retainedTo: retaining!) { comp in
                completion = comp
            } receiveValue: { val in
                value = val
            }
            expect(cancellable.state).to(equal(.retained))
            subject.send(1)
            expect(cancellable.state).to(equal(.retained))
            await expect(value).toEventually(equal(1))
            retaining = nil
            expect(completion).to(beNil())
            await expect(cancellable.state).toEventually(equal(.released))
        }
        it("should release the cancellable after timeout") {
            var completion: Subscribers.Completion<TestError>?
            var value: Int?
            let cancellable = subject.autoReleaseSink(timeout: 0.5) { comp in
                completion = comp
            } receiveValue: { val in
                value = val
            }
            expect(cancellable.state).to(equal(.retained))
            subject.send(1)
            expect(cancellable.state).to(equal(.retained))
            await expect(value).toEventually(equal(1))
            try await Task.sleep(nanoseconds: 600_000_000)
            expect(completion).to(equal(.finished))
            expect(cancellable.state).to(equal(.released))
        }
    }
    // swiftlint:enable function_body_length
}

private class RetainingObject { }
