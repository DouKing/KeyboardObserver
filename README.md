# KeyboardObserver

Provides a reactive way to observe the changes of the keyboard's frame using Swift Combine.

![demo](./Example/demo.gif)

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

3. You can invalidate the observer at any time.

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    view.keyboardObserver.validate()
}

override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    view.keyboardObserver.invalidate()
}
```

## Installation

Add the below line to your Package.swift file as a dependency:

```swift
.package(url: "https://github.com/DouKing/KeyboardObserver.git", .upToNextMajor(from: "1.0"))
```

Normally you'll want to depend on the `KeyboardObserver` target:

```swift
.product(name: "KeyboardObserver", package: "KeyboardObserver")
```

## License

KeyboardObserver is under MIT license.
