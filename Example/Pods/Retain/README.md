# Retain

Retain is an object lifecycle helper that provides a simple way to control object retaining and observing it
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/42316a3fbf084bf7bb44869f6c8d827b)](https://app.codacy.com/gh/hainayanda/Retain/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
![build](https://github.com/hainayanda/Retain/workflows/build/badge.svg)
![test](https://github.com/hainayanda/Retain/workflows/test/badge.svg)
[![SwiftPM Compatible](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen)](https://swift.org/package-manager/)
[![Version](https://img.shields.io/cocoapods/v/Retain.svg?style=flat)](https://cocoapods.org/pods/Retain)
[![License](https://img.shields.io/cocoapods/l/Retain.svg?style=flat)](https://cocoapods.org/pods/Retain)
[![Platform](https://img.shields.io/cocoapods/p/Retain.svg?style=flat)](https://cocoapods.org/pods/Retain)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- Swift 5.5 or higher
- iOS 13.0 or higher
- MacOS 10.15 or higher
- TVOS 13.0 or higher
- WatchOS 8.0 or higher
- XCode 13 or higher

## Installation

### Cocoapods

Retain is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Retain', '~> 1.0.1'
```

### Swift Package Manager from XCode

- Add it using XCode menu **File > Swift Package > Add Package Dependency**
- Add **<https://github.com/hainayanda/Retain.git>** as Swift Package URL
- Set rules at **version**, with **Up to Next Major** option and put **1.0.1** as its version
- Click next and wait

### Swift Package Manager from Package.swift

Add as your target dependency in **Package.swift**

```swift
dependencies: [
    .package(url: "https://github.com/hainayanda/Retain.git", .upToNextMajor(from: "1.0.1"))
]
```

Use it in your target as a `Retain`

```swift
 .target(
    name: "MyModule",
    dependencies: ["Retain"]
)
```

## Author

hainayanda, hainayanda@outlook.com

## License

Retain is available under the MIT license. See the LICENSE file for more info.

## Usage

### Observe object deallocation

You can observe object deallocation very easily by using the global function `whenDeallocate(for:do:)`:

```swift
let cancellable = whenDeallocate(for: myObject) {
    print("myObject is deallocated")
}
```

It will produce Combine's `AnyCancellable` and the closure will be called whenever the object is being deallocated by `ARC`.

If you prefer to get the underlying publisher instead, use `deallocatePublisher(of:)`:

```swift
let myObjectDeallocationPublisher: AnyPublisher<Void, Never> = deallocatePublisher(of: myObject)
```

### DeallocateObservable

there's one protocol named `DeallocateObservable` that can expose the global function as a method so it can be used directly from the object itself:

```swift
class MyObject: DeallocateObservable { 
    ...
    ...
}
```

so then you can do this to the object:

```swift
// get the publisher
let myObjectDeallocationPublisher: AnyPublisher<Void, Never> = myObject.deallocatePublisher

// listen to the deallocation
let cancellable = myObject.whenDeallocate {
    print("myObject is deallocated")
}
```

### WeakSubject propertyWrapper

There's a `propertyWrapper` that enables `DeallocateObservable` behavior without implementing one named `WeakSubject`:

```swift
@WeakSubject var myObject: MyObject?
```

this `propertyWrapper` will store the object in a weak variable and can be observed like `DeallocateObservable` by accessing its `projectedValue`:

```swift
// get the publisher
let deallocationPublisher: AnyPublisher<Void, Never> = $myObject.deallocatePublisher

// listen to the deallocation
let cancellable = $myObject.whenDeallocate {
    print("current value in myObject propertyWrapper is deallocated")
}
```

It will always emit an event for as many objects assigned to this `propertyWrapper` as long the object is deallocated when still in this `propertyWrapper`.

### RetainableSubject

`RetainableSubject` is very similar to `WeakSubject`. The only difference is, we can control whether this `propertyWrapper` will retain the object strongly or weak:

```swift
@RetainableSubject var myObject: MyObject?
```

to change the state of the `propertyWrapper` retain state, just access the `projectedValue`:

```swift
// make weak
$myObject.state = .weak
$myObject.makeWeak()

// make strong
$myObject.state = .strong
$myObject.makeStrong()
```

Since `RetainableSubject` is `DeallocateObservable` too, you can do something similar with `WeakSubject`:

```swift
// get the publisher
let deallocationPublisher: AnyPublisher<Void, Never> = $myObject.deallocatePublisher

// listen to the deallocation
let cancellable = $myObject.whenDeallocate {
    print("current value in myObject propertyWrapper is deallocated")
}
```

## Contribute

You know how, just clone and do a pull request
