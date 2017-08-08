//
//  TCHOfflineChannels.swift
//  twiliochat
//
//  Created by Robert Norris on 01.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation
import TwilioChatClient



class TCHOfflineChannels: TCHChannels {

    private var connected: Bool = false
    private(set) var offlineChannels: [TCHOfflineChannel]!
    
    init(_ offlineChannels: [TCHOfflineChannel] = []) {
        
        self.offlineChannels = offlineChannels
    }
    
    func load(offlineChatClient client: TwilioOfflineChatClient, completion: (() -> ())? = nil) {
     
        let loadGroup = DispatchGroup()
        
        loadGroup.enter()
        client.store.storedChannels { storedChannels in

            self.offlineChannels = storedChannels.map { (storedChannel) -> TCHOfflineChannel in
                
                let offlineChannel = TCHOfflineChannel(storedChannel)
                
                loadGroup.enter()
                client.store.storedMessages(forChannel: offlineChannel) { storedMessages in
                
                    offlineChannel.offlineMessages = TCHOfflineMessages(storedMessages)
                    loadGroup.leave()
                }
                return offlineChannel
            }
            
            loadGroup.leave()
        }
        
        loadGroup.notify(queue: DispatchQueue.main) {
            
            completion?()
        }
    }
    
    func save(toStore store: ChatStore) {

        store.storeChannels(self.offlineChannels)
        
        self.offlineChannels.forEach { (channel) in
            
            channel.save(toStore: store)
        }
    }
    
    func updateSynchronizationStatus(forClient client: TwilioChatClient) {
        
        self.offlineChannels.forEach { (offlineChannel) in
            
            offlineChannel.delegate?.chatClient?(client, channel: offlineChannel, synchronizationStatusUpdated: offlineChannel.synchronizationStatus)
        }
    }
    
//    func connect(toChannels channels: TCHChannels) {
//        
//        let offlineChannels = channels.subscribedChannels().map { (channel) -> TCHOfflineChannel in
//            
//            let offlineChannel = TCHOfflineChannel(channel.storable)
//            offlineChannel.connect(toChannel: channel)
//            return offlineChannel
//        }
//        
//        self.offlineChannels = offlineChannels
//        self.connected = true
//    }
    
//    func disconnect() {
//
//        self.offlineChannels.forEach { (offlineChannel) in
//            
//            offlineChannel.disconnect()
//        }
//        
//        self.offlineChannels = []
//        self.connected = false
//    }
    
    override func subscribedChannels() -> [TCHChannel]! {

        return self.offlineChannels
    }
    
    // Providing this offline would require a offline paginator, one that maybe only ever provides
    // a single page with all results from the offline store. Filter for TCHChannelType.type is .private
    override func userChannelDescriptors(completion: TCHChannelDescriptorPaginatorCompletion!) {
        
        return completion(nil, nil)
    }

    // Providing this offline would require a offline paginator, one that maybe only ever provides
    // a single page with all results from the offline store. Filter for TCHChannelType.type is .public
    override func publicChannelDescriptors(completion: TCHChannelDescriptorPaginatorCompletion!) {
        
        return completion(nil, nil)
    }
    
    override func createChannel(options: [AnyHashable : Any]! = [:], completion: TCHChannelCompletion!) {
        
        return completion(nil, nil)
    }
    
    // After this call, the channel will be a subscribed channel.
    // Rather than mimic the online client, it may be more useful to subscribe after load. This would be a change in
    // behaviour however.
    override func channel(withSidOrUniqueName sidOrUniqueName: String!, completion: TCHChannelCompletion!) {
        
        return completion(nil, nil)
    }
}
