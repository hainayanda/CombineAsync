//
//  CombineAsyncError.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 24/5/23.
//

import Foundation

public typealias PublisherToAsyncError = CombineAsyncError

public enum CombineAsyncError: Error, CustomStringConvertible {
    case finishedButNoValue
    case timeout
    
    @inlinable public var description: String {
        switch self {
        case .finishedButNoValue:
            return "Publisher finished with no value"
        case .timeout:
            return "Publisher failed to emit value in certain timeout"
        }
    }
}
