//
//  WeakSubject.swift
//  Retain
//
//  Created by Nayanda Haberty on 1/6/23.
//

import Foundation
import Combine

// MARK: WeakSubject

@propertyWrapper
public final class WeakSubject<Wrapped: AnyObject>: DeallocateObservable {
    
    // MARK: wrappedValue
    
    private weak var _wrappedValue: Wrapped?
    public var wrappedValue: Wrapped? {
        get { _wrappedValue }
        set {
            self._wrappedValue = newValue
            subscribeIfNeeded(assignedObject: newValue)
        }
    }
    
    // MARK: Public properties
    
    public var projectedValue: DeallocateObservable {
        self
    }
    
    public var deallocatePublisher: AnyPublisher<Void, Never> { publisher.eraseToAnyPublisher() }
    
    // MARK: Internal properties
    
    var publisher: PassthroughSubject<Void, Never> = PassthroughSubject()
    
    // MARK: Private properties
    
    private var cancellable: AnyCancellable? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    // MARK: Init
    
    public init(wrappedValue: Wrapped? = nil) {
        self.wrappedValue = wrappedValue
    }
    
    // MARK: Public methods
    
    public func whenDeallocate(do operation: @escaping () -> Void) -> AnyCancellable {
        publisher.sink(receiveValue: operation)
    }
    
    // MARK: Private methods
    
    private func subscribeIfNeeded(assignedObject: Wrapped?) {
        guard let assignedObject else {
            cancellable = nil
            return
        }
        cancellable = Retain.deallocatePublisher(of: assignedObject)
            .sink { [unowned self] in
                self.publisher.send(())
            }
    }
    
}
