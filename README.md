# CombineAsync

CombineAsync is a collection of Combine extensions and utilities designed for asynchronous tasks.

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
- MacOS 10.15 or higher
- TVOS 13.0 or higher
- WatchOS 8.0 or higher
- Xcode 13 or higher

## Installation

### CocoaPods

You can easily install CombineAsync via [CocoaPods](https://cocoapods.org). Add the following line to your Podfile:

```ruby
pod 'CombineAsync', '~> 1.4'
```

### Swift Package Manager (Xcode)

To install using Xcode's Swift Package Manager, follow these steps:

- Go to **File > Swift Package > Add Package Dependency**
- Enter the URL: **<https://github.com/hainayanda/CombineAsync.git>**
- Choose **Up to Next Major** for the version rule and set the version to **1.4.0**.
- Click "Next" and wait for the package to be fetched.

### Swift Package Manager (Package.swift)

If you prefer using Package.swift, add CombineAsync as a dependency in your **Package.swift** file:

```swift
dependencies: [
    .package(url: "https://github.com/hainayanda/CombineAsync.git", .upToNextMajor(from: "1.4.0"))
]
```

Then, include it in your target:

```swift
 .target(
    name: "MyModule",
    dependencies: ["CombineAsync"]
)
```

## Usage

`CombineAsync` provides various extensions and utilities for working with `Combine` and Swift async. Here are some of the key features:

### Publisher to Async

Convert any object that implements `Publisher` into Swift async with a single call:

```swift
// Implicitly await with a 30-second timeout
let result = await publisher.sinkAsynchronously()

// Specify a timeout explicitly
let timedResult = await publisher.sinkAsynchronously(timeout: 1)
```

### Sequence of Publisher to an Array of Output

Convert a sequence of `Publisher` into async with a single call:

```swift
// Default timeout 30 second
let results = await arrayOfPublishers.sinkAsynchronously()

// Specify a timeout
let timedResults = await arrayOfPublishers.sinkAsynchronously(timeout: 1)

// No timeout
let timedResults = await arrayOfPublishers.sinkAsynchronously(timeout: .none)
```

### Future from Async

Convert Swift async code into a `Future` object with ease:

```swift
let future = Future { 
    try await getSomethingAsync()
}
```

### Publisher Async Sink

Execute asynchronous code inside a sink without explicitly creating a `Task`:

```swift
publisher.asyncSink { output in
    await somethingAsync(output)
}
```

### Publisher Debounce Async Sink

Execute asynchronous code inside a sink and make it run atomically:

```swift
publisher.debounceAsyncSink { output in
    await somethingAsync(output)
}
```

### Auto Release Sink

Automatically release a closure in the sink after a specified duration or when an object is released:

```swift
publisher.autoReleaseSink(retainedTo: self, timeout: 60) { _ in
    // Handle completion
} receiveValue: { 
    // Handle value reception
}
```

### Weak and Auto Release Assign

Assign without retaining the class instance by using `autoReleaseAssign` or `weakAssign` instead of assign:

```swift
// with cancellable
let cancellable = publisher.weakAssign(to: \.property, on: object)

// with auto release cancellable
publisher.autoReleaseAssign(to: \.property, on: object)
```

### Publisher error recovery

Recover from errors using three different methods:

```swift
// Ignore errors and produce AnyPublisher<Output, Never>
publisher.ignoreError()

// Convert errors to output and produce AnyPublisher<Output, Never>
publisher.replaceError { error in convertErrorToOutput(error) }

// Attempt to convert errors to output and produce AnyPublisher<Output, Failure>
publisher.replaceErrorIfNeeded { error in convertErrorToOutputIfNeeded(error) }
```

### Sequence of Publisher to a Single Publisher

Merge a sequence of `Publisher` into a single `Publisher` that emits an array of output:

```swift
// Collect all emitted elements from all publishers
let allElementsEmittedPublisher = arrayOfPublishers.merged()

// Collect only the first emitted element from all publishers
let firstElementsEmittedPublisher = arrayOfPublishers.mergedFirsts()
```

### Publisher Async Map

Map asynchronously using `CombineAsync`:

```swift
publisher.asyncMap { output in
    await convertOutputAsynchronously(output)
}
```

There are some async map method you can use:

- `asyncMap` which is equivalent with `map` but asynchronous
- `asyncTryMap` which is equivalent with `tryMap` but asynchronous
- `asyncCompactMap` which is equivalent with `compactMap` but asynchronous
- `asyncTryCompactMap` which is equivalent with `tryCompactMap` but asynchronous

### Publisher Map Sequence

Map elements of a `Publisher` with a `Sequence` as its output:

```swift
myArrayPublisher.mapSequence { element in
    // Map the element of the sequence to another type
}
```

Those line of code are equivalent with:

```swift
myArrayPublisher.map { output in
    output.map { element in
        // do map the element of the sequence to another type
    }
}
```

All of the sequence mapper that you can use are:

- `mapSequence(_:)` which  bypass `Sequence.map(_:)`
- `compactMapSequence(_:)` which  bypass `Sequence.compactMap(_:)`
- `tryMapSequence(_:)` which  bypass `Sequence.map(_:)` but with throwing mapper closure
- `tryCompactMapSequence(_:)` which  bypass `Sequence.compactMap(_:)` but with throwing mapper closure
- `asyncMapSequence(_:)` which  bypass `Sequence.asyncMap(_:)`
- `asyncCompactMapSequence(_:)` which  bypass `Sequence.asyncCompactMap(_:)`

## Contribute

Feel free to contribute by cloning the repository and creating a pull request.

## Author

Nayanda Haberty, <hainayanda@outlook.com>

## License

CombineAsync is available under the MIT license. See the LICENSE file for more info.
