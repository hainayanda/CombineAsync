//
//  Error.swift
//  CombineAsync
//
//  Created by Nayanda Haberty on 24/5/23.
//

import Foundation

public enum PublisherToAsyncError: Error {
    case finishedButNoValue
    case timeout
    case failToProduceAnOutput
}
