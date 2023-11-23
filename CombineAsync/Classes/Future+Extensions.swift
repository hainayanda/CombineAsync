//
//  Future+Extensions.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 24/5/23.
//

import Foundation
import Combine

extension Future where Failure == Error {
    
    /// Create a future object with generic error from asynchronous closure
    /// - Parameter asyncClosure: closure that run asynchronous code that produce an output
    @inlinable public convenience init(priority: TaskPriority? = nil, _ asyncClosure: @Sendable @escaping () async throws -> Output) {
        self.init { promise in
            Task(priority: priority) {
                do {
                    let result = try await asyncClosure()
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}

extension Future where Failure == Never {
    
    /// Create a future object with generic error from asynchronous closure
    /// - Parameter asyncClosure: closure that run asynchronous code that produce an output
    @inlinable public convenience init(priority: TaskPriority? = nil, _ asyncClosure: @Sendable @escaping () async -> Output) {
        self.init { promise in
            Task(priority: priority) {
                let result = await asyncClosure()
                promise(.success(result))
            }
        }
    }
}
