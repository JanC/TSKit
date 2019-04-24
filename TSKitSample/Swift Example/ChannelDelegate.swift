//
//  ChannelDelegate.swift
//  TSKitSample
//
//  Created by Dan on 4/24/19.
//  Copyright © 2019 Tequila Apps. All rights reserved.
//

import TSKit

protocol ChannelDelegate {
    func addUser(user: TSUser)
    func removeUser(user: TSUser)
    func reload()
}
