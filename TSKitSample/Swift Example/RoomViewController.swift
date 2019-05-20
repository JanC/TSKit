//
//  RoomViewController.swift
//  TSKitSample
//
//  Created by Dan on 4/24/19.
//  Copyright © 2019 Tequila Apps. All rights reserved.
//

import UIKit
import TSKit

class RoomViewController: UIViewController {

    var channels: [TSChannel] = [] {
        didSet {
            table.reloadData()
        }
    }

    @IBOutlet weak var table: UITableView!

    let options = TSClientOptions(host: "localhost",
                                  port: 9986,
                                  nickName: "{Your Name Here}", // nickname must not be empty string
                                  password: nil,
                                  receiveOnly: true)

    lazy var client: TSClient = TSClient(options: options)

    @IBAction func connectAction(_ sender: Any) {
        // You can optionally supply a initial channel to join upon connections
        client.connect(initialChannels: ["MyChannel"], completion: nil)
    }

    @IBAction func disconnectAction(_ sender: Any) {
        client.disconnect()
        channels = []
        table.reloadData()
    }

    override func viewDidLoad() {

        // set the delegate to respond to server events
        client.delegate = self
        configureTable()

    }

    func configureTable() {
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.delegate = self
        table.dataSource = self
        table.tableFooterView = UIView()
    }

}

extension RoomViewController: TSClientDelegate {

    func client(_ client: TSClient, user: TSUser, talkStatusChanged talking: Bool) {
        print("\(user.name) is talking \(talking)")
    }

    func client(_ client: TSClient, didReceivedChannel channel: TSChannel) {
        print("New channel created: \(channel.name)")
        channels.append(channel)
    }

    func client(_ client: TSClient, didDeleteChannel channelId: UInt) {
        if let index = channels.firstIndex(where: { $0.uid == channelId }) {
            channels.remove(at: index)
            print("Channel removed: \(channelId)")
        }
    }

    func client(_ client: TSClient, connectStatusChanged status: TSConnectionStatus) {
        switch status {
        case .disconnected:
            print("Connection disocnnected")
            break;
        case .connecting:
            print("Connection connecting")
            break;
        case .connected:
            print("Connection connected")
            break;
        case .establishing:
            print("Connection establishing")
            break;
        case .established:
            print("Connection established")
            break;
        @unknown default:
            fatalError()
        }
    }

    func client(_ client: TSClient, onConnectionError error: Error) {
        // we were disconnected
        print("⛔️ \(error.localizedDescription)")
    }

}

// MARK: - TableViewDelegate
extension RoomViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let channel = channels[indexPath.item]
        cell.textLabel?.text = "\(channel.uid) \(channel.name)"
        cell.detailTextLabel?.text = (channel.topic ?? "") + (channel.channelDescription ?? "")
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channel = channels[indexPath.item]

        let destination = ChannelViewController(client: self.client)
        destination.client?.delegate = self

        let alert = UIAlertController(
            title: "Channel Actions",
            message: nil,
            preferredStyle: .alert
        )

        let joinChannelAction = UIAlertAction(title:"Join", style: .default) { _ in
            self.client.move(to: channel, authCallback: { auth in
                print(auth)
            }) { (sucsess, error) in
                if !sucsess {
                    print("Unable to move to channel because of error: \(error.localizedDescription)")
                    return
                }
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
        alert.addAction(joinChannelAction)

        let addToWisperListAction = UIAlertAction(title: "Add users of channel to WisperList", style: .default) { _ in
            let users = try! self.client.listUsers(in: channel)
            // Optionally you could just wisper to individual `TSUsers` or to an individual `TSChannel`
            self.client.wisperConnect(users, channels: [channel])
            self.navigationController?.pushViewController(destination, animated: true)
        }

        alert.addAction(addToWisperListAction)

        self.navigationController?.present(alert, animated: true, completion: nil)
    }
}

// MARK: - TableViewDataSource
extension RoomViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
}


