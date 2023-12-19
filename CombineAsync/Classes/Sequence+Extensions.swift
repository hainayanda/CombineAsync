//
//  Sequence+Extensions.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 24/5/23.
//

import Foundation
import Combine

// MARK: Sequence of Publisher

extension Sequence where Element: Publisher {
    
    // MARK: Public methods
    
    /// Return an array of the first results of each publisher asynchronously and throw CombineAsyncError.timeout if its reach timeout before produce an output
    /// - Parameter timeout: timeout in second
    /// - Returns: An array containing the first results of each publisher
    @inlinable public func sinkAsynchronously(timeout: TimeInterval) async throws -> [Element.Output] {
        try await mergedFirsts().sinkAsynchronously(timeout: timeout)
    }
    
    /// Collects all received elements, and emits a single array of the collection when the upstream publisher finishes.
    /// - Returns: A publisher that collects all received items and returns them as an array upon completion.
    @inlinable public func merged() -> AnyPublisher<[Element.Output], Element.Failure> {
        Publishers.MergeMany(self)
            .collect()
            .eraseToAnyPublisher()
    }
    
    /// Collects all first received elements, and emits a single array of the collection when the upstream publisher finishes emit a first element.
    /// - Returns: A publisher that collects all received items and returns them as an array upon completion.
    @inlinable public func mergedFirsts() -> AnyPublisher<[Element.Output], Element.Failure> {
        Publishers.MergeMany(self.map { $0.first() })
            .collect()
            .eraseToAnyPublisher()
    }
}
