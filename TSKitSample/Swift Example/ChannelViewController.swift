//
//  ChannelViewController.swift
//  TSKitSample
//
//  Created by Dan on 4/24/19.
//  Copyright © 2019 Tequila Apps. All rights reserved.
//

import TSKit
import UIKit

class ChannelViewController: UIViewController {
    var users: [TSUser] = [] {
        didSet {
            table.reloadData()
            refresh.endRefreshing()
        }
    }

    var channelDelegate: ChannelDelegate?
    let refresh = UIRefreshControl()

    weak var client: TSClient?
//    var followedUserID: UInt64?

    let table = UITableView(frame: .zero)

    let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reload))

    init(client: TSClient) {
        self.client = client
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        configureTable()
        if let client = client {
            title = client.currentChannel.name
        }
        configureRefreshButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUsers()
        configureRefreshButton()
    }

    func configureTable() {
        table.register(UITableViewCell.self, forCellReuseIdentifier: "channelCell")
        table.delegate = self
        table.dataSource = self
        table.tableFooterView = UIView()
        refresh.addTarget(self, action: #selector(reload), for: .valueChanged)
        table.refreshControl = refresh
        view.addSubview(table)
        table.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.topAnchor.constraint(equalTo: view.topAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func configureRefreshButton() {
        navigationController?.navigationItem.setRightBarButtonItems( [refreshButton], animated: true)
    }

    /// fetch all the users on the current channel.
    func refreshUsers() {
        do {
            if let client = client {
                try self.users = client.listUsers(in: client.currentChannel)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

// MARK: - TableViewDelegate
extension ChannelViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
}

// MARK: - TableViewDataSource
extension ChannelViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "channelCell")

        let user = users[indexPath.item]
        guard let client = self.client else { return cell }
        cell.textLabel?.text = client.ownClientID == user.uid ? "\(user.name) (me) \(user.uid)" : "\(user.name) \(user.isMuted ? "Muted" : "") \(user.uid)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.item]
        let name = user.name

        let alert = UIAlertController(
            title: name,
            message: nil,
            preferredStyle: .alert
        )
        let muteAction = UIAlertAction(title: user.isMuted ? "UnMute \(name)" : "Mute \(name)", style: .default) { _ in
            do {
                guard let client = self.client else { return }
                try client.muteUser(user, mute: !user.isMuted)
                self.table.reloadData()
            } catch {
                print(error.localizedDescription)
            }
        }
        alert .addAction(muteAction)

        let allowWispersAction = UIAlertAction(title: "Allow Wispers", style: .default) { _ in
            self.client?.allowWisper(from: user)
        }
        alert .addAction(allowWispersAction)

        let disallowWispersAction = UIAlertAction(title: "Dissallow Wispers", style: .default) { _ in
            self.client?.allowWisper(from: user)
        }
        alert .addAction(disallowWispersAction)

        navigationController?.present(alert, animated: true, completion: nil)
    }
}

extension ChannelViewController: ChannelDelegate {
    func addUser(user: TSUser) {
        self.users.append(user)
    }

    func removeUser(user: TSUser) {
        self.users.removeAll(where: { $0 == user })
    }

    @objc func reload() {
        refreshUsers()
    }
}
