//
//  ActiveChannel.swift
//  twiliochat
//
//  Created by Robert Norris on 02.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation



protocol ActiveChatChannel : ChatChannel {
    
    var manager: ChannelManager? { get }
    
    func sendMessage(_: String)
    func removeMessage(atIndex: Int)
}



extension ActiveChatChannel {
    
    func sendMessage(_ body: String) {
        
        self.manager?.sendMessage(body, inChannel: self)
    }
    
    func removeMessage(atIndex index: Int) {
        
        self.manager?.removeMessage(atIndex: index, fromChannel: self)
    }
}



typealias ChannelMembershipHandler = (_ creator: StoredMember?, _ others: [StoredMember]) -> ()



class ActiveChannel : ActiveChatChannel {
    
    private(set) var channel: StoredChannel
    private(set) var messages: [StoredMessage]
    private(set) var members: Set<StoredMember> = Set<StoredMember>()
    private(set) var users: Set<StoredUser> = Set<StoredUser>()
    
    var manager: ChannelManager?
    
    init(_ storedChannel: StoredChannel
        , storedUsers: [StoredUser]
        , storedMembers: [StoredMember]
        , storedMessages: [StoredMessage] = []) {
        
        self.channel = storedChannel
        self.users = Set(storedUsers)
        self.members = Set(storedMembers)
        self.messages = storedMessages
    }
    
    var sid: String {
        
        return self.channel.sid
    }

    var friendlyName: String? {
        
        return self.channel.friendlyName
    }
    
    var imageUrl: String? {
        
        return self.channel.imageUrl
    }
    
    var createdBy: String? {
        
        return self.channel.createdBy
    }
    
    var displayName: String? {
        
        return self.friendlyName ?? self.sid
    }
    
    func membership(_ membership: ChannelMembershipHandler) {
        
        let creator = self.members.first { $0.identity == self.createdBy }
        let others = self.members.filter { $0.identity != self.createdBy }
        
        membership(creator, others)
    }
}
