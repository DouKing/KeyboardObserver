//===----------------------------------------------------------*- Swift -*-===//
//
// Created by wuyikai on 2024/5/25.
// Copyright © 2024 wuyikai. All rights reserved.
//
//===----------------------------------------------------------------------===//

import UIKit
import KeyboardObserver

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(contentView)
        view.addSubview(chatBarView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            
            chatBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatBarView.topAnchor.constraint(equalTo: contentView.bottomAnchor),
            chatBarView.bottomAnchor.constraint(equalTo: view.keyboardAreaLayoutGuide.topAnchor),
            chatBarView.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.keyboardObserver.validate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.keyboardObserver.invalidate()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        chatBarView.resignFirstResponder()
    }

    lazy var contentView: UIView = {
        let this = UIView()
        this.translatesAutoresizingMaskIntoConstraints = false
        this.layer.borderColor = UIColor.lightGray.cgColor
        this.layer.borderWidth = 2
        return this
    }()
    
    lazy var chatBarView: UITextField = {
        let this = UITextField()
        this.translatesAutoresizingMaskIntoConstraints = false
        this.backgroundColor = .cyan
        this.placeholder = "Type messages..."
        return this
    }()
}
