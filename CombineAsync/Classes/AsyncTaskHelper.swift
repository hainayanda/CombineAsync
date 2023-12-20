//
//  AsyncTaskHelper.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 19/12/23.
//

import Foundation
import Combine

actor Flag: ExpressibleByBooleanLiteral {
    typealias BooleanLiteralType = Bool
    
    var wrapped: Bool
    
    init(booleanLiteral: Bool) {
        self.wrapped = booleanLiteral
    }
    
    func runIfMatchThenToggle(condition: Bool, runner: () -> Void) {
        guard wrapped == condition else { return }
        wrapped.toggle()
        runner()
    }
}

/// Atomic CheckedContinuation that will make sure the resume will only called once
public final class AtomicContinuation<T, E>: Sendable where E: Error {
    
    let continuation: CheckedContinuation<T, E>
    let isValid: Flag = true
    
    public init(continuation: CheckedContinuation<T, E>) {
        self.continuation = continuation
    }

    /// Resume the task awaiting the continuation by having it return normally
    /// from its suspension point.
    ///
    /// - Parameter value: The value to return from the continuation.
    ///
    /// A continuation will only take effect once. If resume is called after the first once, it will be ignored
    ///
    /// After `resume` enqueues the task, control immediately returns to
    /// the caller. The task continues executing when its executor is
    /// able to reschedule it.
    public func resume(returning value: T) {
        Task {
            await isValid.runIfMatchThenToggle(condition: true) {
                continuation.resume(returning: value)
            }
        }
    }

    /// Resume the task awaiting the continuation by having it throw an error
    /// from its suspension point.
    ///
    /// - Parameter error: The error to throw from the continuation.
    ///
    /// A continuation will only take effect once. If resume is called after the first once, it will be ignored
    ///
    /// After `resume` enqueues the task, control immediately returns to
    /// the caller. The task continues executing when its executor is
    /// able to reschedule it.
    public func resume(throwing error: E) {
        Task {
            await isValid.runIfMatchThenToggle(condition: true) {
                continuation.resume(throwing: error)
            }
        }
    }
}

/// Invokes the passed in closure with a checked continuation for the current task.
///
/// The body of the closure executes synchronously on the calling task, and once it returns
/// the calling task is suspended. It is possible to immediately resume the task, or escape the
/// continuation in order to complete it afterwards, which will them resume suspended task.
///
/// If `resume(throwing:)` is called on the continuation, this function throws that error.
///
/// You can invoke the continuation's `resume` more than once, it will only execute once.
///
/// It will automatically throwing `CombineAsyncError.timeout` if resume is not called until timeout
///
/// - Parameters:
///   - body: A closure that takes a `AtomicContinuation` parameter.
/// - Returns: The value continuation is resumed with.
@inlinable public func withCheckedThrowingContinuation<T>(timeout: TimeInterval, _ body: (AtomicContinuation<T, Error>) -> Void) async throws -> T {
    guard timeout != 0 else { throw CombineAsyncError.timeout }
    guard timeout > 0 else {
        return try await withCheckedThrowingContinuation { body(.init(continuation: $0)) }
    }
    return try await withCheckedThrowingContinuation { continuation in
        let atomicContinuation = AtomicContinuation(continuation: continuation)
        var timerCancellable: AnyCancellable?
        timerCancellable = Timer.publish(every: timeout, on: .main, in: .default)
            .autoconnect()
            .sink { _ in
                timerCancellable?.cancel()
                timerCancellable = nil
                atomicContinuation.resume(throwing: CombineAsyncError.timeout)
            }
        body(atomicContinuation)
    }
}
