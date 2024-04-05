//
//  Publisher+Sequence.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 1/10/23.
//

import Foundation
import Combine

extension Publisher where Output: Sequence {
    
    /// Map the Output element to another element
    /// - Parameter transformSequence: Closure that accept each element from output and return the transformation result
    /// - Returns: AnyPublisher of Array of new element with same Failure type
    @inlinable public func mapSequence<T>(_ transformSequence: @escaping (Output.Element) -> T) -> AnyPublisher<[T], Self.Failure> {
        map { $0.map(transformSequence) }
            .eraseToAnyPublisher()
    }
    
    /// Compact map the Output element to another element.
    /// It will ignore the nil output from the closure result
    /// - Parameter transformSequence: Closure that accept each element from output and return the transformation optional result
    /// - Returns: AnyPublisher of Array of new element with same Failure type
    @inlinable public func compactMapSequence<T>(_ transformSequence: @escaping (Output.Element) -> T?) -> AnyPublisher<[T], Self.Failure> {
        map { $0.compactMap(transformSequence) }
            .eraseToAnyPublisher()
    }
    
    /// Try map the Output element to another element
    /// - Parameter transformSequence: Throwing closure that accept each element from output and return the transformation result
    /// - Returns: AnyPublisher of Array of new element with same Error as Failure  type
    @inlinable public func tryMapSequence<T>(_ transformSequence: @escaping (Output.Element) throws -> T) -> AnyPublisher<[T], Error> {
        mapError { $0 }
            .tryMap { try $0.map(transformSequence) }
            .eraseToAnyPublisher()
    }
    
    /// Try compact map the Output element to another element.
    /// - Parameter transformSequence: Throwing closure that accept each element from output and return the transformation optional result
    /// - Returns: AnyPublisher of Array of new element with same Error as Failure  type
    @inlinable public func tryCompactMapSequence<T>(_ transformSequence: @escaping (Output.Element) throws -> T?) -> AnyPublisher<[T], Error> {
        mapError { $0 }
            .tryMap { try $0.compactMap(transformSequence) }
            .eraseToAnyPublisher()
    }
}
