//
//  ChatStore.swift
//  twiliochat
//
//  Created by Tommaso Piazza on 26.07.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation


typealias ChannelsHandler = (([StoredChannel]) -> ())
typealias MessagesHandler = ((StoredChannel, [StoredMessage]) -> ())
typealias UsersHandler = (([StoredUser]) -> ())
typealias MembersHandler = ((StoredChannel, [StoredMember]) -> ())

protocol ChatStore: class {
    
    func storeChannels(_ channels: [StoredChannel])
    func storedChannels(completion: ([StoredChannel]) -> ())
    func addChannel(_ channel: StoredChannel)
    func updateChannel(_ channel: StoredChannel)
    func deleteChannel(_ channel: StoredChannel)
    
    func storeMessages(forChannel channel: StoredChannel, messages: [StoredMessage])
    func storedMessages(forChannel channel:StoredChannel, completion: ([StoredMessage]) -> ())
    func addMessage(_ message: StoredMessage, toChannel  channel: StoredChannel)
    func updateMessage(_ message: StoredMessage, inChannel  channel: StoredChannel)
    func deleteMessage(_ message: StoredMessage, fromChannel  channel: StoredChannel)
    
    func storeUsers(_ users: [StoredUser])
    func storedUsers(completion: ([StoredUser]) -> ())
    func addUser(_ user: StoredUser)
    func updateUser(_ user: StoredUser)
    func deleteUser(_ user: StoredUser)    

    func storeMembers(forChannel channel: StoredChannel, members: [StoredMember])
    func storedMembers(forChannel channel: StoredChannel, completion: ([StoredMember]) -> ())
    func addMember(_ member: StoredMember, toChannel channel: StoredChannel)
    func updateMember(_ member: StoredMember, inChannel channel: StoredChannel)
    func deleteMember(_ member: StoredMember, fromChannel channel: StoredChannel)
}



class UserDefaultChatStore: ChatStore {
    
    private static let channelsStoreKey = "channelsStore"
    private static let messagesStoreKey = "messagesStore"
    private static let usersStoreKey = "usersStore"
    private static let membersStoreKey = "membersStore"
    
    static let shared: ChatStore = UserDefaultChatStore()
    
    static private let defaults = UserDefaults.standard
    
    func storeChannels(_ channels: [StoredChannel]) {
        
        print("\(String(describing: type(of: self))).\(#function) - count: \(channels.count)")
        
        self.storedChannels { storedChannels in
            
            // Nota bene: Robert Norris - the order is important as conversion from Array to Set uses insert 
            // rather than update i.e. the first StoredChannel wins rather than the last.
            let s = Set(channels + storedChannels)
            
            var channelMap: [String: Data] = [:]
            
            s.forEach { channel in
                
                channelMap[String(describing: channel.hashValue)] = channel.toJSON()
            }
            
            UserDefaultChatStore.defaults.setValue(channelMap, forKey: UserDefaultChatStore.channelsStoreKey)
            let synchronized = UserDefaultChatStore.defaults.synchronize()
            precondition(synchronized, "\(String(describing: type(of: self))).\(#function) failed!")
        }
    }
    
    func storedChannels(completion: ([StoredChannel]) -> ()) {
        
        guard let channelMap = UserDefaultChatStore.defaults.value(forKey: UserDefaultChatStore.channelsStoreKey) as? [String: Data] else {
            
            completion([])
            return
        }
        
        let channels: [StoredChannel] = channelMap.values.map { StoredChannel.fromJSON(data: $0)}.flatMap{$0}
        
        completion(channels)
    }
    
    func addChannel(_ channel: StoredChannel) {
        
        self.storeChannels([channel])
    }

    func updateChannel(_ channel: StoredChannel) {
     
        self.storedChannels { (storedChannels) in
            
            var all = Set(storedChannels)
            all.update(with: channel)
            
            self.storeChannels(Array(all))
        }
    }

    func deleteChannel(_ channel: StoredChannel) {
        
        self.storedChannels { (storedChannels) in
            
            var all = Set(storedChannels)
            all.remove(channel)
            
            self.storeChannels(Array(all))
        }
    }

    func storeMessages(forChannel channel: StoredChannel, messages: [StoredMessage]) {
     
        print("\(String(describing: type(of: self))).\(#function) - channel: \(channel.friendlyName!) sid: \(channel.sid) count: \(messages.count)")
        
        self.storedMessages(forChannel: channel) { storedMessages in
            
            // Nota bene: Robert Norris - the order is important as conversion from Array to Set uses insert
            // rather than update i.e. the first StoredMessage wins rather than the last.
            let s = Set(messages + storedMessages)
            
            var messageMap = UserDefaultChatStore.defaults.value(forKey: UserDefaultChatStore.messagesStoreKey) as? [String: Data] ?? [:]
            
            s.forEach { message in
                
                messageMap[String(describing: message.hashValue)] = message.toJSON()
            }
            
            UserDefaultChatStore.defaults.setValue(messageMap, forKey: UserDefaultChatStore.messagesStoreKey)
            let synchronized = UserDefaultChatStore.defaults.synchronize()
            precondition(synchronized, "\(String(describing: type(of: self))).\(#function) failed!")
        }
    }
    
    func storedMessages(forChannel channel: StoredChannel, completion: ([StoredMessage]) -> ()) {
        
        guard let messageMap = UserDefaultChatStore.defaults.value(forKey: UserDefaultChatStore.messagesStoreKey) as? [String: Data] else {
            
            completion([])
            return
        }
                
        let messages: [StoredMessage] = messageMap.values.map { StoredMessage.fromJSON(data: $0)}.flatMap{$0}.filter { (message) -> Bool in
            return message.channel == channel.sid
        }
        
        completion(messages)
    }
    
    func addMessage(_ message: StoredMessage, toChannel  channel: StoredChannel) {
        
        self.storeMessages(forChannel: channel, messages: [message])
    }
    
    func updateMessage(_ message: StoredMessage, inChannel  channel: StoredChannel) {
        
        self.storedMessages(forChannel: channel) { (storedMessages) in
            
            var all = Set(storedMessages)
            all.update(with: message)
            
            self.storeMessages(forChannel: channel, messages: Array(all))
        }
    }
    
    func deleteMessage(_ message: StoredMessage, fromChannel  channel: StoredChannel) {
     
        self.storedMessages(forChannel: channel) { (storedMessages) in
            
            var all = Set(storedMessages)
            all.remove(message)
            
            self.storeMessages(forChannel: channel, messages: Array(all))
        }

    }
    
    func storeUsers(_ users: [StoredUser]) {
        
        print("\(String(describing: type(of: self))).\(#function) - count: \(users.count)")
        
        self.storedUsers { storedUsers in
            
            // Nota bene: Robert Norris - the order is important as conversion from Array to Set uses insert
            // rather than update i.e. the first StoredUser wins rather than the last.
            let s = Set(users + storedUsers)
            
            var userMap: [String: Data] = [:]
            
            s.forEach { user in
                
                userMap[String(describing: user.hashValue)] = user.toJSON()
            }
            
            UserDefaultChatStore.defaults.setValue(userMap, forKey: UserDefaultChatStore.usersStoreKey)
            let synchronized = UserDefaultChatStore.defaults.synchronize()
            precondition(synchronized, "\(String(describing: type(of: self))).\(#function) failed!")
        }
    }
    
    func storedUsers(completion: ([StoredUser]) -> ()) {
        
        guard let userMap = UserDefaultChatStore.defaults.value(forKey: UserDefaultChatStore.usersStoreKey) as? [String: Data] else {
            
            completion([])
            return
        }
        
        let users: [StoredUser] = userMap.values.map { StoredUser.fromJSON(data: $0)}.flatMap{$0}
        
        completion(users)
    }
    
    func addUser(_ user: StoredUser) {
        
        self.storeUsers([user])
    }
    
    func updateUser(_ user: StoredUser) {
        
        self.storedUsers { (storedUsers) in
            
            var all = Set(storedUsers)
            all.update(with: user)
            
            self.storeUsers(Array(all))
        }
    }
    
    func deleteUser(_ user: StoredUser) {
    
        self.storedUsers { (storedUsers) in
            
            var all = Set(storedUsers)
            all.remove(user)
            
            self.storeUsers(Array(all))
        }
    }
    
    func storeMembers(forChannel channel: StoredChannel, members: [StoredMember]) {
        
        print("\(String(describing: type(of: self))).\(#function) - count: \(members.count)")
        
        self.storedMembers(forChannel: channel) { storedMembers in
            
            // Nota bene: Robert Norris - the order is important as conversion from Array to Set uses insert
            // rather than update i.e. the first StoredMember wins rather than the last.
            let s = Set(members + storedMembers)
            
            var memberMap: [String: Data] = [:]
            
            s.forEach { member in
                
                memberMap[String(describing: member.hashValue)] = member.toJSON()
            }
            
            UserDefaultChatStore.defaults.setValue(memberMap, forKey: UserDefaultChatStore.membersStoreKey)
            let synchronized = UserDefaultChatStore.defaults.synchronize()
            precondition(synchronized, "\(String(describing: type(of: self))).\(#function) failed!")
        }
    }
    
    func storedMembers(forChannel channel: StoredChannel, completion: ([StoredMember]) -> ()) {
        
        guard let memberMap = UserDefaultChatStore.defaults.value(forKey: UserDefaultChatStore.membersStoreKey) as? [String: Data] else {
            
            completion([])
            return
        }
        
        let members: [StoredMember] = memberMap.values.map { StoredMember.fromJSON(data: $0)}.flatMap{$0}
        
        completion(members)
    }
    
    func addMember(_ member: StoredMember, toChannel channel: StoredChannel) {
     
        self.storeMembers(forChannel: channel, members: [member])
    }
    
    func updateMember(_ member: StoredMember, inChannel channel: StoredChannel) {
        
        self.storedMembers(forChannel: channel) { (storedMembers) in
            
            var all = Set(storedMembers)
            all.update(with: member)
            
            self.storeMembers(forChannel: channel, members: Array(all))
        }
    }
    
    func deleteMember(_ member: StoredMember, fromChannel channel: StoredChannel) {
        
        self.storedMembers(forChannel: channel) { (storedMembers) in
            
            var all = Set(storedMembers)
            all.remove(member)
            
            self.storeMembers(forChannel: channel, members: Array(all))
        }
    }

}
