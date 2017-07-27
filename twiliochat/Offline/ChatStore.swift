//
//  ChatStore.swift
//  twiliochat
//
//  Created by Tommaso Piazza on 26.07.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation


protocol ChatStore: class {
    
    func storeChannels(_ storableChannels: [TCHStoredChannel])
    func addChannel(_ storableChannel: TCHStoredChannel)
    func updateChannel(_ storableChannel: TCHStoredChannel)
    func deleteChannel(_ storableChannel: TCHStoredChannel)
    func storedChannels(completion: ([TCHStoredChannel]) -> ())
    
    // TODO:
    
    //func storeMessages(_ storableMessages: [TCHStoredMessage], forChannel  channel: TCHStoredChannel)
    //func addChannel(_ storableMessage: TCHStoredMessage, forChannel  channel: TCHStoredChannel)
    //func updateChannel(_ storableMessage: TCHStoredMessage, forChannel  channel: TCHStoredChannel)
    //func deleteChannel(_ storableMessage: TCHStoredMessage, forChannel  channel: TCHStoredChannel)
    //func storedMessages(forChannel channel: TCHStoredChannel, completion: ([TCHStoredMessage]) -> ())
}



class UserDefaultChatStore: ChatStore {
    
    private static let channelsStoreKey = "channelsStore"
    
    private static let messagesStoreKey = "messagesStore"
    
    static let shared = UserDefaultChatStore()

    static private let defaults = UserDefaults.standard

    
    func storedChannels(completion: ([TCHStoredChannel]) -> ()) {
        
        guard let channelMap = UserDefaultChatStore.defaults.value(forKey: UserDefaultChatStore.channelsStoreKey) as? [String: Data] else {
            
            completion([])
            return
        }
        completion(channelMap.values.map{ TCHStoredChannel.fromJSON(data: $0)}.flatMap{$0} )
    }
    
    func deleteChannel(_ storableChannel: TCHStoredChannel) {
        
        
    }

    func updateChannel(_ storableChannel: TCHStoredChannel) {

    }

    func addChannel(_ storableChannel: TCHStoredChannel) {

        
    }
    
    func storeChannels(_ storableChannels: [TCHStoredChannel]) {
        
        self.storedChannels { existingStoredChannels in
            
            let s = Set(existingStoredChannels + storableChannels)
            
            var channelMap: [String: Data] = [:]
            
            s.forEach { channel in
                
                channelMap[channel.sid] = channel.toJSON()
            }
            
            UserDefaultChatStore.defaults.setValue(channelMap, forKey: UserDefaultChatStore.channelsStoreKey)
            UserDefaultChatStore.defaults.synchronize()
        }
    }
}
