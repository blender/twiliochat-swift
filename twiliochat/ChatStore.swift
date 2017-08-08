//
//  ChatStore.swift
//  twiliochat
//
//  Created by Tommaso Piazza on 26.07.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation



protocol ChatStore: class {
    
    func storeChannels(_ channels: [TCHChannel])
    func storedChannels(completion: ([TCHStoredChannel]) -> ())
    func addChannel(_ channel: TCHChannel)
    func updateChannel(_ channel: TCHChannel)
    func deleteChannel(_ channel: TCHChannel)
    
    func storeMessages(forChannel channel: TCHChannel, messages: [TCHMessage])
    func storedMessages(forChannel channel: TCHChannel, completion: ([TCHStoredMessage]) -> ())
    func addMessage(_ message: TCHMessage, forChannel  channel: TCHChannel)
    func updateMessage(_ message: TCHMessage, forChannel  channel: TCHChannel)
    func deleteMessage(_ message: TCHMessage, forChannel  channel: TCHChannel)
}



class UserDefaultChatStore: ChatStore {
    
    private static let channelsStoreKey = "channelsStore"
    
    private static let messagesStoreKey = "messagesStore"
    
    static let shared = UserDefaultChatStore()
    
    static private let defaults = UserDefaults.standard
    
    func storeChannels(_ channels: [TCHChannel]) {
        
        let storableChannels = channels.map { (channel) -> TCHStoredChannel in
            return channel.storable
        }

        self.storedChannels { existingStoredChannels in
            
            let s = Set(existingStoredChannels + storableChannels)
            
            var channelMap: [String: Data] = [:]
            
            s.forEach { channel in
                
                channelMap[String(describing: channel.hashValue)] = channel.toJSON()
            }
            
            UserDefaultChatStore.defaults.setValue(channelMap, forKey: UserDefaultChatStore.channelsStoreKey)
            let synchronized = UserDefaultChatStore.defaults.synchronize()
            print("\(String(describing: type(of: self))).\(#function) - synchronized: \(synchronized)")
        }
    }
    
    func storedChannels(completion: ([TCHStoredChannel]) -> ()) {
        
        guard let channelMap = UserDefaultChatStore.defaults.value(forKey: UserDefaultChatStore.channelsStoreKey) as? [String: Data] else {
            
            completion([])
            return
        }
        completion(channelMap.values.map{ TCHStoredChannel.fromJSON(data: $0)}.flatMap{$0} )
    }
    
    func addChannel(_ channel: TCHChannel) {
        
        self.storeChannels([channel])
    }

    func updateChannel(_ channel: TCHChannel) {
        
    }

    func deleteChannel(_ channel: TCHChannel) {
        
        
    }

    func storeMessages(forChannel channel: TCHChannel, messages: [TCHMessage]) {
     
        print("\(String(describing: type(of: self))).\(#function) - channel: \(channel.friendlyName!) sid: \(channel.sid!)")
        
        let storableMessages = messages.map { (message) -> TCHStoredMessage in
            return message.storable(forChannel: channel)
        }
        
        self.storedMessages(forChannel: channel) { existingStoredMessages in
            
            let s = Set(existingStoredMessages + storableMessages)
            
            var messageMap = UserDefaultChatStore.defaults.value(forKey: UserDefaultChatStore.messagesStoreKey) as? [String: Data] ?? [:]
            
            s.forEach { message in
                
                //print("\(String(describing: type(of: self))).\(#function) - key: \(message.hashValue) sid: \(message.sid!), channel: \(message.channel!)")
                messageMap[String(describing: message.hashValue)] = message.toJSON()
            }
            
            //print("\(String(describing: type(of: self))).\(#function) - count: \(messageMap.count) keys: \(Array(messageMap.keys))")
            
            UserDefaultChatStore.defaults.setValue(messageMap, forKey: UserDefaultChatStore.messagesStoreKey)
            let synchronized = UserDefaultChatStore.defaults.synchronize()
            print("\(String(describing: type(of: self))).\(#function) - synchronized: \(synchronized)")
        }
    }
    
    func storedMessages(forChannel channel: TCHChannel, completion: ([TCHStoredMessage]) -> ()) {
        
        print("\(String(describing: type(of: self))).\(#function) - channel: \(channel.friendlyName!) sid: \(channel.sid!)")
        
        guard let messageMap = UserDefaultChatStore.defaults.value(forKey: UserDefaultChatStore.messagesStoreKey) as? [String: Data] else {
            
            completion([])
            return
        }
        
//        print("\(String(describing: type(of: self))).\(#function) - count: \(messageMap.count) keys: \(Array(messageMap.keys))")
//        
//        messageMap.forEach { item in
//            
//            let storedMessage = TCHStoredMessage.fromJSON(data: item.value)
//            if storedMessage?.channel == channel.sid {
//                print("\(String(describing: type(of: self))).\(#function) - key: \(item.key) sid: \(storedMessage!.sid!), channel: \(storedMessage!.channel!)")
//            }
//        }
        
        let messages: [TCHStoredMessage] = messageMap.values.map { TCHStoredMessage.fromJSON(data: $0)}.flatMap{$0}.filter { (message) -> Bool in
            return message.channel == channel.sid
        }
        
        completion(messages)
    }
    
    func addMessage(_ message: TCHMessage, forChannel  channel: TCHChannel) {
        
        self.storeMessages(forChannel: channel, messages: [message])
    }
    
    func updateMessage(_ message: TCHMessage, forChannel  channel: TCHChannel) {
        
    }
    
    func deleteMessage(_ message: TCHMessage, forChannel  channel: TCHChannel) {
        
    }
}
