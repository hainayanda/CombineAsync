//
//  AsyncTaskHelper.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 19/12/23.
//

import Foundation
import Combine

/// Atomic CheckedContinuation that will make sure the resume will only called once
public final class SingleCallContinuation<T, E> where E: Error {
    
    let continuation: CheckedContinuation<T, E>
    var isValid: Bool = true
    let semaphore: DispatchSemaphore = .init(value: 1)
    let onContinuationCalled: (() -> Void)?
    
    public init(continuation: CheckedContinuation<T, E>, onContinuationCalled: (() -> Void)? = nil) {
        self.continuation = continuation
        self.onContinuationCalled = onContinuationCalled
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
        runIfValid {
            continuation.resume(returning: value)
            onContinuationCalled?()
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
        runIfValid {
            continuation.resume(throwing: error)
            onContinuationCalled?()
        }
    }
    
    func runIfValid(_ task: () -> Void) {
        semaphore.wait()
        defer { semaphore.signal() }
        guard isValid else { return }
        isValid = false
        task()
    }
}

public extension SingleCallContinuation where T == Void {
    @inlinable func resume() {
        self.resume(returning: Void())
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
///   - onTimeout: A closure that will be called in event of timeout
/// - Returns: The value continuation is resumed with.
@inlinable public func withCheckedThrowingContinuation<T>(
    function: String = #function, timeout: TimeInterval,
    _ body: (SingleCallContinuation<T, Error>) -> Void,
    onTimeout: (() -> Void)? = nil) async throws -> T {
        guard timeout > 0 else {
            onTimeout?()
            throw CombineAsyncError.timeout
        }
        return try await withCheckedThrowingContinuation(function: function) { continuation in
            var timerCancellable: AnyCancellable?
            let atomicContinuation = SingleCallContinuation(continuation: continuation) {
                timerCancellable?.cancel()
                timerCancellable = nil
            }
            timerCancellable = Timer.publish(every: timeout, on: .main, in: .default)
                .autoconnect()
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    onTimeout?()
                    atomicContinuation.resume(throwing: CombineAsyncError.timeout)
                }
            body(atomicContinuation)
        }
    }
