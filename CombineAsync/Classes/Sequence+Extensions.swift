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
    @inlinable public func waitForOutputs(timeout: TimeInterval) async throws -> [Element.Output] {
        try await withThrowingTaskGroup(of: Element.Output.self, returning: [Element.Output].self) { group in
            for publisher in self {
                group.addTask {
                    try await publisher.waitForOutput(timeout: timeout)
                }
            }
            return try await group.reduce(into: []) { partialResult, element in
                partialResult.append(element)
            }
        }
    }
    
    /// Return an array of the first results of each publisher asynchronously
    /// - Returns: An array containing the first results of each publisher
    @inlinable public func waitForOutputsIndefinitely() async throws -> [Element.Output] {
        try await withThrowingTaskGroup(of: Element.Output.self, returning: [Element.Output].self) { group in
            for publisher in self {
                group.addTask {
                    try await publisher.waitForOutputIndefinitely()
                }
            }
            return try await group.reduce(into: []) { partialResult, element in
                partialResult.append(element)
            }
        }
    }
}

extension Sequence where Element: Publisher, Element.Failure == Never {
    
    /// Return an array of the first results of each publisher asynchronously and return nil if its reach timeout before produce an output
    /// - Parameter timeout: timeout in second
    /// - Returns: An array containing the first results of each publisher
    @inlinable public func waitForOutputs(timeout: TimeInterval) async -> [Element.Output?] {
        return await withTaskGroup(of: Optional<Element.Output>.self, returning: [Element.Output?].self) { group in
            for publisher in self {
                group.addTask {
                    await publisher.waitForOutput(timeout: timeout)
                }
            }
            return await group.reduce(into: []) { partialResult, element in
                partialResult.append(element)
            }
        }
    }
    
    /// Return an array of the first results of each publisher asynchronously
    /// - Returns: An array containing the first results of each publisher
    @inlinable public func waitForOutputsIndefinitely() async -> [Element.Output?] {
        return await withTaskGroup(of: Optional<Element.Output>.self, returning: [Element.Output?].self) { group in
            for publisher in self {
                group.addTask {
                    await publisher.waitForOutputIndefinitely()
                }
            }
            return await group.reduce(into: []) { partialResult, element in
                partialResult.append(element)
            }
        }
    }
}
