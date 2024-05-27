# KeyboardObserver

Provides a reactive way to observe the changes of the keyboard's frame using Swift Combine.

## Requirements

- iOS 13.0+
- Swift 5.10

## Get Started

1. Attach your view's anchor to the `keyboardAreaLayoutGuide` of your view.

```swift
chatBarView.bottomAnchor.constraint(equalTo: view.keyboardAreaLayoutGuide.topAnchor)
```

2. You can also observe the change of the keyboard

```swift
view.keyboardObserver.keyboardHeightChange
    .sink { change in
        print(change)
    }
```

## Installation

Add the below to your Package.swift file's dependencies:

```swift
.package(url: "https://github.com/DouKing/KeyboardObserver.git", branch: "main")
```

## License

KeyboardObserver is under MIT license.
