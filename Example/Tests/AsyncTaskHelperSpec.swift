//
//  AsyncTaskHelperSpec.swift
//  CombineAsync_Example
//
//  Created by Nayanda Haberty on 19/12/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Combine
import CombineAsync

class AsyncTaskHelperSpec: AsyncSpec {
    
    override class func spec() {
        it("should throw timeout error") {
            await expect {
                try await withCheckedThrowingContinuation(timeout: 0.1) { continuation in
                    runAfter(timeout: 0.2) {
                        continuation.resume(returning: 1)
                    }
                }
            }.to(throwError(CombineAsyncError.timeout))
        }
        it("should return the value") {
            await expect {
                try await withCheckedThrowingContinuation(timeout: 0.2) { continuation in
                    runAfter(timeout: 0.1) {
                        continuation.resume(returning: 1)
                    }
                }
            }.to(equal(1))
        }
    }
}

public func runAfter(timeout: TimeInterval, _ runner: @escaping () -> Void) {
    var timerCancellable: AnyCancellable?
    timerCancellable = Timer.publish(every: timeout, on: .main, in: .default)
        .autoconnect()
        .sink { _ in
            timerCancellable?.cancel()
            timerCancellable = nil
            runner()
        }
}
