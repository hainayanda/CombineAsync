# CombineAsync

CombineAsync is Combine extensions and utilities for an async task

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/d07d496defc943ad90e96fde91a55e65)](https://app.codacy.com/gh/hainayanda/CombineAsync/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
![build](https://github.com/hainayanda/CombineAsync/workflows/build/badge.svg)
![test](https://github.com/hainayanda/CombineAsync/workflows/test/badge.svg)
[![SwiftPM Compatible](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen)](https://swift.org/package-manager/)
[![Version](https://img.shields.io/cocoapods/v/CombineAsync.svg?style=flat)](https://cocoapods.org/pods/CombineAsync)
[![License](https://img.shields.io/cocoapods/l/CombineAsync.svg?style=flat)](https://cocoapods.org/pods/CombineAsync)
[![Platform](https://img.shields.io/cocoapods/p/CombineAsync.svg?style=flat)](https://cocoapods.org/pods/CombineAsync)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- Swift 5.5 or higher
- iOS 13.0 or higher
- MacOS 10.15 or higher (SPM Only)
- TVOS 13.0 or higer (SPM Only)
- XCode 13 or higher

## Installation

### Cocoapods

CombineAsync is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CombineAsync', '~> 1.0.2'
```

### Swift Package Manager from XCode

- Add it using XCode menu **File > Swift Package > Add Package Dependency**
- Add **<https://github.com/hainayanda/CombineAsync.git>** as Swift Package URL
- Set rules at **version**, with **Up to Next Major** option and put **1.0.2** as its version
- Click next and wait

### Swift Package Manager from Package.swift

Add as your target dependency in **Package.swift**

```swift
dependencies: [
    .package(url: "https://github.com/hainayanda/CombineAsync.git", .upToNextMajor(from: "1.0.2"))
]
```

Use it in your target as a `CombineAsync`

```swift
 .target(
    name: "MyModule",
    dependencies: ["CombineAsync"]
)
```

hainayanda, hainayanda@outlook.com

## License

CombineAsync is available under the MIT license. See the LICENSE file for more info.

## Usage

`CombineAsync` contains several extensions that can be used when working with `Combine` and Swift async

### Publisher to Async

You can convert any object that implements `Publisher` into Swift async with a single call:

```swift
let result = await publisher.sinkAsynchronously()

// or with timeout
let timedResult = await publisher.sinkAsynchronously(timeout: 1)
```

it will produce `PublisherToAsyncError` if an error happens in the conversion. The errors are:
- `finishedButNoValue`
- `timeout`
- `failToProduceAnOutput`

other than those errors, it will rethrow the error produced by the original `Publisher`

### Sequence of Publisher to an array of output

Similar to `Publisher` to async, any sequence of `Publisher` can be converted to async too with a single call:

```swift
let results = await arrayOfPublishers.sinkAsynchronously()

// or with timeout
let timedResults = await arrayOfPublishers.sinkAsynchronously(timeout: 1)
```

### Future from async

You can convert Swift async to a `Future` object with provided convenience init:

```swift
let future = Future { 
    try await getSomethingAsync()
}
```

### Publisher error recovery

`CombineAsync` gives you a way to recover from errors using 3 other methods:

```swift
// will ignore error and produce AnyPublisher<Output, Never>
publisher.ignoreError()

// will convert the error to output and produce AnyPublisher<Output, Never>
publisher.replaceError { error in convertErrorToOutput(error) }

// will try to convert the error to output and produce AnyPublisher<Output, Failure>
// if the output is nil, it will just pass the error
publisher.replaceErrorIfNeeded { error in convertErrorToOutputIfNeeded(error) }
```

It's similar to `replaceError`, but accepts a closure instead of just single output

### Sequence of Publisher to a single Publisher

`CombineAsync` give you a shortcut to merge a sequence of `Publisher` into a single `Publisher` that emits an array of output with a single call:

```swift
// will collect all the emitted elements from all publishers
let allElementsEmittedPublisher = arrayOfPublishers.merged()

// will collect only the first emitted element from all publishers
let firstElementsEmittedPublisher = arrayOfPublishers.mergedFirsts()
```

### Asynchronous Map

`CombineAsync` gives you the ability to map using an async mapper. it will run all the mapping parallel and collect the results while maintaining the original order:

```swift
// map
let mapped = try await arrayOfID.asyncMap { await getUser(with: $0) }

// compact map
let compactMapped = try await arrayOfID.asyncCompactMap { await getUser(with: $0) }

// with timeout
let timedMapped = try await arrayOfID.asyncMap(timeout: 10) { await getUser(with: $0) }
let timedCompactMapped = try await arrayOfID.asyncCompactMap(timeout: 10) { await getUser(with: $0) }
```

If you prefer using `Publisher` instead, change `asyncMap` to `futureMap` and `asyncCompactMap` to `futureCompactMap`:

```swift
// map
let futureMapped: AnyPublisher<[User], Error> = arrayOfID.futureMap { await getUser(with: $0) }

// compact map
let futureCompactMapped: AnyPublisher<[User], Error> = arrayOfID.futureCompactMap { await getUser(with: $0) }
```

## Contribute

You know how, just clone and do a pull request
