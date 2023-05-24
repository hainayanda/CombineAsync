//
//  Helper.swift
//  CombineAsync_Example
//
//  Created by Nayanda Haberty on 24/5/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import Combine

class ResultWrapper<Success, Failure> {
    var wrapped: Result<Success, TestError> = .failure(.initialError)
}

extension Publisher {
    func sinkTest(for result: ResultWrapper<Output, TestError>) -> AnyCancellable {
        sink { completion in
            switch completion {
            case .failure(let error):
                guard let testError = error as? TestError else {
                    result.wrapped = .failure(.unexpectedError)
                    return
                }
                result.wrapped = .failure(testError)
            case .finished:
                return
            }
        } receiveValue: { output in
            result.wrapped = .success(output)
        }
    }
}

extension PassthroughSubject {
    func sendAfter(_ time: TimeInterval, input: Output) {
        DispatchQueue.global().asyncAfter(deadline: .now() + time) { [weak self] in
            self?.send(input)
        }
    }
    
    func sendAfter(_ time: TimeInterval, completion: Subscribers.Completion<Failure>) {
        DispatchQueue.global().asyncAfter(deadline: .now() + time) { [weak self] in
            self?.send(completion: completion)
        }
    }
}
