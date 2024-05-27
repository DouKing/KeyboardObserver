//===----------------------------------------------------------*- Swift -*-===//
//
// Created by wuyikai on 2024/5/27.
// Copyright © 2024 wuyikai. All rights reserved.
//
//===----------------------------------------------------------------------===//

import UIKit
import Combine
import KeyboardObserver

class MessageListViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(contentView)
        view.addSubview(chatBarView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            
            chatBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatBarView.bottomAnchor.constraint(equalTo: view.keyboardAreaLayoutGuide.topAnchor),
            chatBarView.heightAnchor.constraint(equalToConstant: 50),
        ])
        reloadData()
        setupKeyboardObserver()
    }
    
    private enum Section {
        case main
    }
    
    private typealias SectionType = Section
    private typealias ItemType = String
    
    // MARK: - Property
    
    private var bag: Set<AnyCancellable> = []
    private let cellReuseIdentifier = "cellReuseIdentifier"
    
    private lazy var dataSource: DataSource = {
        DataSource(tableView: self.contentView) {
            [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self else { return nil }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier, for: indexPath)
            cell.textLabel?.text = item
            cell.textLabel?.numberOfLines = 0
            return cell
        }
    }()

    lazy var contentView: UITableView = {
        let this = UITableView(frame: .zero, style: .grouped)
        this.translatesAutoresizingMaskIntoConstraints = false
        this.keyboardDismissMode = .interactive
        this.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
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

extension MessageListViewController {
    private class DataSource: UITableViewDiffableDataSource<SectionType, ItemType> {}
    
    private func scrollToBottom(animated: Bool = true) {
        guard let item = self.dataSource.snapshot().itemIdentifiers.last,
              let indexPath = self.dataSource.indexPath(for: item)
        else {
            return
        }
        self.contentView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    private func fixCollectionBottom() {
        let bottom = self.view.frame.height -
            self.view.safeAreaInsets.bottom -
            self.chatBarView.frame.minY
        self.contentView.contentInset.bottom = bottom
        self.contentView.verticalScrollIndicatorInsets.bottom = bottom
    }
    
    private func setupKeyboardObserver() {
        DispatchQueue.main.async {
            self.fixCollectionBottom()
        }

        self.view.keyboardObserver.keyboardHeightChange
            .sink { change in
                print(change)
            }
            .store(in: &self.bag)
        
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .extract(keyPath: \.duration)
            .sink { [weak self] duration in
                guard let self else { return }
                UIView.animate(withDuration: duration) {
                    self.fixCollectionBottom()
                    self.scrollToBottom(animated: false)
                }
            }
            .store(in: &self.bag)
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] note in
                self?.fixCollectionBottom()
            }
            .store(in: &self.bag)
    }
    
    private func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<SectionType, ItemType>()
        snapshot.appendSections([.main])
        snapshot.appendItems([
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            "Morbi et eros elementum, semper massa eu, pellentesque sapien.",
            "Aenean sollicitudin justo scelerisque tincidunt venenatis.",
            "Ut mollis magna nec interdum pellentesque.",
            "Aliquam semper nibh nec quam dapibus, a congue odio consequat.",
            "Nullam iaculis nisi in justo feugiat, at pharetra nulla dignissim.",
            "Fusce at nulla luctus, posuere mauris ut, viverra nunc.",
            "Nam feugiat urna non tortor ornare viverra.",
            "Donec vitae metus maximus, efficitur urna ac, blandit erat.",
            "Pellentesque luctus eros ac nisi ullamcorper pharetra nec vel felis.",
            "Duis vulputate magna quis urna porttitor, tempor malesuada metus volutpat.",
            "Duis aliquam urna quis metus tristique eleifend.",
            "Cras quis orci quis nisi vulputate mollis ut vitae magna.",
            "Fusce eu urna eu ipsum laoreet lobortis.",
            "Proin vitae tellus nec odio consequat varius ac non orci.",
            "Maecenas gravida arcu ut consectetur tincidunt.",
            "Quisque accumsan nisl ut ipsum rutrum, nec rutrum magna lobortis.",
            "Integer ac sem eu velit tincidunt hendrerit a in dui.",
            "Duis posuere arcu convallis tincidunt faucibus.",
        ])
        dataSource.apply(snapshot)
    }
}
