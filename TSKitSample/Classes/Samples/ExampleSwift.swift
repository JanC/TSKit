//
//  ExampleSwift.swift
//  TSKitSample
//
//  Created by Jan Chaloupecky on 08.12.17.
//  Copyright © 2017 Tequila Apps. All rights reserved.
//

import Foundation

import TSKit

class SampleViewController: UIViewController {

    
    override func viewDidLoad() {
        
    // Connection options
    let options = TSClientOptions(host: "localhost",
                                  port: 9986,
                                  nickName: "Jan",
                                  password: nil,
                                  receiveOnly: true) // no transmission will be made. This also does not trigger the microphone permissions
    
    let client = TSClient(options: options)
    
    // set the delegate to respond to server events
    client.delegate = self
    
    // You can optionally supply a initial channel to join upon connection
    client.connect(initialChannels: ["MyChannel"], completion: nil)
    }
}

extension SampleViewController: TSClientDelegate {
    
    func client(_ client: TSClient, user: TSUser, talkStatusChanged talking: Bool) {
        print("\(user.name) is talking \(talking)")
    }
    
    func client(_ client: TSClient, didReceivedChannel channel: TSChannel) {
        print("New channel created: \(channel.name)")
    }
    func client(_ client: TSClient, didDeleteChannel channelId: UInt) {
        print("Channel removed: \(channelId)")
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
        }
    }
    
    func client(_ client: TSClient, onConnectionError error: Error) {
       // we were disconnected
    }
}


