//
//  DeallocateObservable.swift
//  Retain
//
//  Created by Nayanda Haberty on 14/6/23.
//

import Foundation
import Combine

public protocol DeallocateObservable: AnyObject {
    
    /// Return publisher that publish event of this object deallocation event
    /// - Returns: Publisher that publish event of this object deallocation event
    var deallocatePublisher: AnyPublisher<Void, Never> { get }

    /// Run this closure whenever this object is deallocated
    /// - Parameters:
    ///   - operation: Void closure that will be run when this object deallocated
    /// - Returns: AnyCancellable
    func whenDeallocate(do operation: @escaping () -> Void) -> AnyCancellable
}

extension DeallocateObservable {
    
    /// Return publisher that publish event of this object deallocation event
    /// - Returns: Publisher that publish event of this object deallocation event
    public var deallocatePublisher: AnyPublisher<Void, Never> {
        Retain.deallocatePublisher(of: self)
    }

    /// Run this closure whenever this object is deallocated
    /// - Parameters:
    ///   - operation: Void closure that will be run when this object deallocated
    /// - Returns: AnyCancellable
    public func whenDeallocate(do operation: @escaping () -> Void) -> AnyCancellable {
        Retain.whenDeallocate(for: self, do: operation)
    }
}
