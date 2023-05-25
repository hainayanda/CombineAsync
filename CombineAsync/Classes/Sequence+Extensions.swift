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
    
    /// Return an array of the first results of each publisher asynchronously and throw PublisherToAsyncError.timeout if its reach timeout before produce an output
    /// - Parameter timeout: timeout in second
    /// - Returns: An array containing the first results of each publisher
    public func sinkAsynchronously(timeout: TimeInterval = 0) async throws -> [Element.Output] {
        try await mergedFirsts().sinkAsynchronously(timeout: timeout)
    }
    
    /// Collects all received elements, and emits a single array of the collection when the upstream publisher finishes.
    /// - Returns: A publisher that collects all received items and returns them as an array upon completion.
    public func merged() -> AnyPublisher<[Element.Output], Element.Failure> {
        Publishers.MergeMany(self)
            .collect()
            .eraseToAnyPublisher()
    }
    
    /// Collects all first received elements, and emits a single array of the collection when the upstream publisher finishes emit a first element.
    /// - Returns: A publisher that collects all received items and returns them as an array upon completion.
    public func mergedFirsts() -> AnyPublisher<[Element.Output], Element.Failure> {
        Publishers.MergeMany(self.map { $0.first() })
            .collect()
            .eraseToAnyPublisher()
    }
}

// MARK: Map

extension Sequence {
    
    // MARK: Typealias
    
    typealias IndexedMappedFuture<Output> = Future<(index: Int, element: Output), Error>
    
    // MARK: Public methods
    
    /// Returns an array containing the results of mapping the given async closure over the sequence's elements.
    /// It will run asynchronously and throwing error if one of the element is failing in the given async closure.
    /// It will still retain the original order of the element regardless of the order of mapping time completion
    /// - Parameters:
    ///   - timeout: timeout in second
    ///   - mapper: A mapping async closure. `mapper` accepts an element of this sequence as its parameter
    ///             and returns a transformed value of the same or of a different type asynchronously.
    /// - Returns: An array containing the transformed elements of this sequence
    public func asyncMap<Mapped>(timeout: TimeInterval = 0, _ mapper: @escaping (Element) async throws -> Mapped) async throws -> [Mapped] {
        try await convertToIndexedFutures(mapper)
            .sinkAsynchronously(timeout: timeout)
            .sorted { $0.index < $1.index }
            .map { $0.element }
    }
    
    /// Returns an array containing the results of mapping the given async closure over the sequence's elements
    /// while ignoring `null` value.
    /// It will run asynchronously and throwing error if one of the element is failing in the given async closure.
    /// It will still retain the original order of the element regardless of the order of mapping time completion
    /// - Parameters:
    ///   - timeout: timeout in second
    ///   - mapper: A mapping async closure. `mapper` accepts an element of this sequence as its parameter
    ///             and returns an optional transformed value of the same or of a different type asynchronously.
    /// - Returns: An array containing the transformed elements of this sequence
    public func asyncCompactMap<Mapped>(timeout: TimeInterval = 0, _ mapper: @escaping (Element) async throws -> Mapped?) async throws -> [Mapped] {
        try await convertToIndexedFutures(mapper)
            .sinkAsynchronously(timeout: timeout)
            .sorted { $0.index < $1.index }
            .compactMap { $0.element }
        
    }
    
    /// Returns an array containing the results of mapping the given async closure over the sequence's elements.
    /// It will run asynchronously and throwing error if one of the element is failing in the given async closure.
    /// It will still retain the original order of the element regardless of the order of mapping time completion
    /// - Parameter mapper: A mapping async closure. `mapper` accepts an element of this sequence as its parameter
    ///   and returns a transformed value of the same or of a different type asynchronously.
    /// - Returns: A publisher that will produce an array containing the transformed elements of this sequence
    public func futureMap<Mapped>(_ mapper: @escaping (Element) async throws -> Mapped) -> AnyPublisher<[Mapped], Error> {
        convertToIndexedFutures(mapper)
            .merged()
            .map { pairs in
                pairs.sorted { $0.index < $1.index }
                    .map { $0.element }
            }
            .eraseToAnyPublisher()
    }
    
    /// Returns an array containing the results of mapping the given async closure over the sequence's elements
    /// while ignoring `null` value.
    /// It will run asynchronously and throwing error if one of the element is failing in the given async closure.
    /// It will still retain the original order of the element regardless of the order of mapping time completion
    /// - Parameter mapper: A mapping async closure. `mapper` accepts an element of this sequence as its parameter
    ///   and returns an optional transformed value of the same or of a different type asynchronously.
    /// - Returns: A publisher that will produce an array containing the transformed elements of this sequence
    public func futureCompactMap<Mapped>(_ mapper: @escaping (Element) async throws -> Mapped?) -> AnyPublisher<[Mapped], Error> {
        convertToIndexedFutures(mapper)
            .merged()
            .map { pairs in
                pairs.sorted { $0.index < $1.index }
                    .compactMap { $0.element }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: Internal methods
    
    func convertToIndexedFutures<Mapped>(_ mapper: @escaping (Element) async throws -> Mapped) -> [IndexedMappedFuture<Mapped>] {
        enumerated()
            .map { (index, element) in
                Future { (index: index, element: try await mapper(element)) }
            }
    }
}
