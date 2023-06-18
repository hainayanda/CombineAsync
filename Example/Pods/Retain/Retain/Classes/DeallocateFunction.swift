//
//  DeallocateFunction.swift
//  Retain
//
//  Created by Nayanda Haberty on 1/6/23.
//

import Foundation
import Combine

private var retainDeallocateKey: String = "retainDeallocateKey"

/// Return publisher that publish event of the given object deallocation event
/// - Parameter object: Object
/// - Returns: Publisher that publish event of the given object deallocation event
public func deallocatePublisher<D: AnyObject>(of object: D) -> AnyPublisher<Void, Never> {
    guard let holder = objc_getAssociatedObject(object, &retainDeallocateKey) as? DeallocatePublisherHolder else {
        let newHolder = DeallocatePublisherHolder()
        objc_setAssociatedObject(object, &retainDeallocateKey, newHolder, .OBJC_ASSOCIATION_RETAIN)
        return newHolder.publisher.eraseToAnyPublisher()
    }
    return holder.publisher.eraseToAnyPublisher()
}

/// Run the given closure whenever the given object is deallocated
/// - Parameters:
///   - object: Object
///   - operation: Void closure that will be run when the given object deallocated
/// - Returns: AnyCancellable
public func whenDeallocate<D: AnyObject>(for object: D, do operation: @escaping () -> Void) -> AnyCancellable {
    return deallocatePublisher(of: object).sink(receiveValue: operation)
}

// MARK: DeallocatePublisherHolder

private class DeallocatePublisherHolder {
    let publisher: PassthroughSubject<Void, Never> = PassthroughSubject()
    
    deinit {
        publisher.send(())
        publisher.send(completion: .finished)
    }
}
