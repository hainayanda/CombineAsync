//
//  RetainableSubject.swift
//  Retain
//
//  Created by Nayanda Haberty on 1/6/23.
//

import Foundation
import Combine

// MARK: RetainControllable

public protocol RetainControllable: AnyObject, DeallocateObservable {
    var state: RetainState { get set }
}

extension RetainControllable {
    public func makeWeak() {
        state = .weak
    }
    
    public func makeStrong() {
        state = .strong
    }
}

// MARK: RetainState

public enum RetainState {
    case strong
    case `weak`
}

// MARK: RetainableSubject

@propertyWrapper
public final class RetainableSubject<Wrapped: AnyObject>: RetainControllable {
    
    // MARK: wrappedValue
    
    @WeakSubject private var weakWrappedValue: Wrapped?
    private var strongWrappedValue: Wrapped?
    public var wrappedValue: Wrapped? {
        get { weakWrappedValue }
        set {
            weakWrappedValue = newValue
            guard state == .strong else { return }
            strongWrappedValue = newValue
        }
    }
    
    // MARK: Public properties
    
    public var state: RetainState {
        didSet {
            switch state {
            case .strong:
                strongWrappedValue = weakWrappedValue
            case .weak:
                strongWrappedValue = nil
            }
        }
    }
    
    public var projectedValue: RetainControllable { self }
    
    public var deallocatePublisher: AnyPublisher<Void, Never> { $weakWrappedValue.deallocatePublisher }
    
    // MARK: Init
    
    public init(wrappedValue: Wrapped? = nil, state: RetainState = .strong) {
        self.state = state
        self.wrappedValue = wrappedValue
    }
    
    // MARK: Public method
    
    public func whenDeallocate(do operation: @escaping () -> Void) -> AnyCancellable {
        $weakWrappedValue.whenDeallocate(do: operation)
    }
}
