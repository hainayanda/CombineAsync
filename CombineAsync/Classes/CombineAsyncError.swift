//
//  CombineAsyncError.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 24/5/23.
//

import Foundation

public typealias PublisherToAsyncError = CombineAsyncError

public enum CombineAsyncError: Error {
    case finishedButNoValue
    case timeout
    case failToProduceAnOutput
}
