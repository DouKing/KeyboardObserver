//===----------------------------------------------------------*- Swift -*-===//
//
// Created by wuyikai on 2024/4/2.
// Copyright © 2024 wuyikai. All rights reserved.
//
//===----------------------------------------------------------------------===//

import UIKit
import Combine

/// Provides a reactive way of observing keyboard frame changes
public protocol KeyboardObserverable {
    /// Represents the keyboard change with the current visiable height
    /// and the delta from the previous height
    typealias KeyboardHeightChange = (visiableHeight: CGFloat, delta: CGFloat)
    
    /// A publisher that emits values when keyboard's frame changes.
    var keyboardHeightChange: AnyPublisher<KeyboardHeightChange, Never> { get }
}

// MARK: - KeyboardObserver

public class KeyboardObserver: KeyboardObserverable {
    /// Init a keyboard observer to observe the keyboard's visiable height on the given view.
    /// It will calculate the intersection height of the keyboard and the given view.
    /// - Parameter view: The given view
    public init(view: UIView) {
        self.view = view
        view.addGestureRecognizer(self.panGesture)
        self.keyboardHeightConstraint = Self.installKeyboardGuide(self.keyboardAreaGuide, on: view)
        
        self.cancellable = self.keyboardHeightChange.sink { [weak self] change in
            self?.keyboardHeightConstraint.constant = change.visiableHeight
            self?.view?.layoutIfNeeded()
        }
    }

    private static func installKeyboardGuide(
        _ guide: UILayoutGuide, on view: UIView
    ) -> NSLayoutConstraint {
        view.addLayoutGuide(guide)
        
        let height = guide.heightAnchor.constraint(equalToConstant: 0)
        height.priority = .defaultLow
        height.isActive = true
        guide.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        guide.topAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        return height
    }
    
    private weak var view: UIView?
    private let keyboardHeightConstraint: NSLayoutConstraint
    public let keyboardAreaGuide = UILayoutGuide()
    fileprivate var cancellable: AnyCancellable?
    
    private let panGesture: KeyboardPanGestureRecognizer = {
        let pan = KeyboardPanGestureRecognizer()
        pan.delegate = pan
        pan.maximumNumberOfTouches = 1
        return pan
    }()
    
    public lazy var keyboardHeightChange: AnyPublisher<KeyboardHeightChange, Never> = {
        let willChangeFrame = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .extract(keyPath: \.frame)
        
        let didPan = self.panGesture.combine
            .combineLatest(willChangeFrame)
            .flatMap { [weak self] (gestureRecognizer, keyboardFrame) in
                guard let view = self?.view,
                      case .changed = gestureRecognizer.state,
                      keyboardFrame.origin.y < UIScreen.main.bounds.height
                else { return Empty<CGRect, Never>().eraseToAnyPublisher() }
                
                let origin = view.convert(gestureRecognizer.location(in: view),
                                          to: UIScreen.main.coordinateSpace)
                var fixedFrame = keyboardFrame
                fixedFrame.origin.y = max(origin.y, UIScreen.main.bounds.height - keyboardFrame.height)
                
                return Just(fixedFrame).eraseToAnyPublisher()
            }
        
        let initialChange: KeyboardHeightChange = (0, 0)
        let visiableHeightChange = Publishers.Merge(willChangeFrame, didPan)
            .compactMap { [weak self] keyboardFrame -> CGFloat? in
                guard let self, let view = self.view else { return nil }
                let convertedFrame = view.convert(keyboardFrame, from: UIScreen.main.coordinateSpace)
                let keyboardHeight = max(view.frame.intersection(convertedFrame).height,
                                         view.safeAreaInsets.bottom)
                let visiableHeight = keyboardHeight - view.safeAreaInsets.bottom
                return visiableHeight
            }
            .removeDuplicates()
            .scan(initialChange) { state, currentRealHeight in
                (currentRealHeight, currentRealHeight - state.visiableHeight)
            }
            .filter { $0.delta != 0 }
        
        return visiableHeightChange.share().eraseToAnyPublisher()
    }()
}

/// A wrappered type for the user info of the ketboard notification.
public struct KeyboardInfo {
    public let frame: CGRect
    public let duration: Double
    public let animation: UIView.AnimationCurve
}

extension NotificationCenter.Publisher {
    /// Extract the user info of the keyboard
    public func extract() -> AnyPublisher<KeyboardInfo, Never> {
        self.compactMap(convertKeyboardNotification(_:))
            .eraseToAnyPublisher()
    }
    
    /// Extract the user info of the keyboard using the given keypath
    public func extract<T>(keyPath: KeyPath<KeyboardInfo, T>) -> AnyPublisher<T, Never> {
        self.compactMap(convertKeyboardNotification(_:))
            .map(keyPath)
            .eraseToAnyPublisher()
    }
}

extension UIView {
    private struct Keys {
        static var keyboardObserver = withUnsafePointer(to: "keyboardObserver") { $0 }
    }
    
    /// A custom UILayoutGuide that represents the keyboard's area.
    public var keyboardAreaLayoutGuide: UILayoutGuide {
        return self.keyboardObserver.keyboardAreaGuide
    }
    
    /// A keyboard observer for observering the keyboard height on itself
    public var keyboardObserver: KeyboardObserver {
        let pointer = Keys.keyboardObserver
        let observer: KeyboardObserver
        if let value = objc_getAssociatedObject(self, pointer) as? KeyboardObserver {
            observer = value
        } else {
            observer = KeyboardObserver(view: self)
            objc_setAssociatedObject(self, pointer, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return observer
    }
}

// MARK: -

private func convertKeyboardNotification(
    _ note: Notification
) -> KeyboardInfo? {
    guard let userInfo = note.userInfo else { return nil }
    
    // Extract the final frame of the keyboard
    let frameKey = UIResponder.keyboardFrameEndUserInfoKey
    guard let keyboardFrame = userInfo[frameKey] as? CGRect else {
        return nil
    }

    // Extract the duration of the keyboard animation
    let durationKey = UIResponder.keyboardAnimationDurationUserInfoKey
    let duration = userInfo[durationKey] as? Double ?? 0.225
    
    // Extract the curve of the iOS keyboard animation
    let curveKey = UIResponder.keyboardAnimationCurveUserInfoKey
    let curveValue = userInfo[curveKey] as? Int ?? 7
    let curve = UIView.AnimationCurve(rawValue: curveValue) ?? .easeInOut
    
    return KeyboardInfo(frame: keyboardFrame, duration: duration, animation: curve)
}

/// Inner pan gesture for interactive keyboard dismiss mode
private class KeyboardPanGestureRecognizer: UIPanGestureRecognizer, UIGestureRecognizerDelegate {
    var combine: AnyPublisher<UIPanGestureRecognizer, Never> {
        subject.eraseToAnyPublisher()
    }
    
    let subject: PassthroughSubject<UIPanGestureRecognizer, Never>
    
    override init(target: Any?, action: Selector?) {
        self.subject = .init()
        super.init(target: nil, action: nil)
        self.addTarget(self, action: #selector(handlePan(_:)))
    }
    
    @objc func handlePan(_ gesture: KeyboardPanGestureRecognizer) {
        self.subject.send(gesture)
    }
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        let point = touch.location(in: gestureRecognizer.view)
        var view = gestureRecognizer.view?.hitTest(point, with: nil)
        while let candidate = view {
            if let scrollView = candidate as? UIScrollView,
               case .interactive = scrollView.keyboardDismissMode {
                return true
            }
            view = candidate.superview
        }
        return false
    }
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        gestureRecognizer === self
    }
}
