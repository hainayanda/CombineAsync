//
//  PublisherSequenceSpec.swift
//  CombineAsync_Example
//
//  Created by Nayanda Haberty on 5/4/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Combine
import CombineAsync

class PublisherSequenceSpec: AsyncSpec {
    
    override class func spec() {
        let subject: Just<[Int]> = Just([1, 2, 3, 4, 5])
        it("should map output as its a sequence") {
            let mapped = await subject.mapSequence { "\($0)" }
                .waitForOutputIndefinitely()
            expect(mapped).to(equal(["1", "2", "3", "4", "5"]))
        }
        it("should compact map output as its a sequence") {
            let mapped = await subject.compactMapSequence { $0 % 2 == 0 ? $0 : nil }
                .waitForOutputIndefinitely()
            expect(mapped).to(equal([2, 4]))
        }
        it("should map output as its a sequence") {
            let mapped = try await subject.tryMapSequence { "\($0)" }
                .waitForOutputIndefinitely()
            expect(mapped).to(equal(["1", "2", "3", "4", "5"]))
        }
        it("should compact map output as its a sequence") {
            let mapped = try await subject.tryCompactMapSequence { $0 % 2 == 0 ? $0 : nil }
                .waitForOutputIndefinitely()
            expect(mapped).to(equal([2, 4]))
        }
    }
}
