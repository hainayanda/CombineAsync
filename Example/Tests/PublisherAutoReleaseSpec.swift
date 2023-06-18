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

class PublisherAutoReleaseSpec: QuickSpec {
    
    // swiftlint:disable function_body_length
    override class func spec() {
        var subject: PassthroughSubject<Int, TestError>!
        beforeEach {
            subject = .init()
        }
        it("should release the cancellable after completion") {
            var completion: Subscribers.Completion<TestError>?
            var value: Int?
            let cancellable = subject.autoReleaseSink { comp in
                completion = comp
            } receiveValue: { val in
                value = val
            }
            expect(cancellable.state).to(equal(.retained))
            subject.send(1)
            expect(cancellable.state).to(equal(.retained))
            expect(value).to(equal(1))
            subject.send(completion: .finished)
            expect(completion).to(equal(.finished))
            expect(cancellable.state).to(equal(.released))
        }
        it("should release the cancellable after error") {
            var completion: Subscribers.Completion<TestError>?
            var value: Int?
            let cancellable = subject.autoReleaseSink { comp in
                completion = comp
            } receiveValue: { val in
                value = val
            }
            expect(cancellable.state).to(equal(.retained))
            subject.send(1)
            expect(cancellable.state).to(equal(.retained))
            expect(value).to(equal(1))
            subject.send(completion: .failure(.expectedError))
            expect(completion).to(equal(.failure(.expectedError)))
            expect(cancellable.state).to(equal(.released))
        }
        it("should release the cancellable after object released") {
            var retaining: RetainingObject? = RetainingObject()
            var completion: Subscribers.Completion<TestError>?
            var value: Int?
            let cancellable = subject.autoReleaseSink(retainedTo: retaining) { comp in
                completion = comp
            } receiveValue: { val in
                value = val
            }
            expect(cancellable.state).to(equal(.retained))
            subject.send(1)
            expect(cancellable.state).to(equal(.retained))
            expect(value).to(equal(1))
            retaining = nil
            expect(completion).to(beNil())
            expect(cancellable.state).to(equal(.released))
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
            expect(value).to(equal(1))
            waitUntil { done in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: done)
            }
            expect(completion).to(beNil())
            expect(cancellable.state).to(equal(.released))
        }
    }
    // swiftlint:enable function_body_length
}

private class RetainingObject { }
