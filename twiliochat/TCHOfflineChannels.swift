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
    private var offlineChannels: [TCHOfflineChannel] = []
    
    func load(fromStore store: ChatStore, completion: (() -> ())? = nil) {
     
        let loadGroup = DispatchGroup()
        
        loadGroup.enter()
        store.storedChannels { storedChannels in

            let offlineChannels = storedChannels.map { (storedChannel) -> TCHOfflineChannel in
                
                loadGroup.enter()
                return TCHOfflineChannel(storedChannel)
            }
            
            offlineChannels.forEach { (offlineChannel) in

                offlineChannel.load(fromStore: store) {
                    
                    loadGroup.leave()
                }
            }
            
            self.offlineChannels = offlineChannels
            
            loadGroup.leave()
        }
        
        loadGroup.notify(queue: DispatchQueue.main) {
            
            completion?()
        }
    }
    
    func connect(toChannels channels: TCHChannels) {
        
        let offlineChannels = channels.subscribedChannels().map { (channel) -> TCHOfflineChannel in
            
            let offlineChannel = TCHOfflineChannel(channel.storable)
            offlineChannel.connect(toChannel: channel)
            return offlineChannel
        }
        
        self.offlineChannels = offlineChannels
        self.connected = true
    }
    
    func disconnect(updatingStore store: ChatStore? = nil) {

        store?.storeChannels(self.offlineChannels)
        
        self.offlineChannels.forEach { (channel) in
            
            channel.disconnect(updatingStore: store)
        }
        
        self.connected = false
    }
    
    override func subscribedChannels() -> [TCHChannel]! {
        
        guard self.connected else {
        
            return self.offlineChannels
        }
        
        return super.subscribedChannels()
    }
    
    override func userChannelDescriptors(completion: TCHChannelDescriptorPaginatorCompletion!) {
        
        guard self.connected else {
        
            return completion(nil, nil)
        }
        
        super.userChannelDescriptors(completion: completion)
    }
    
    override func publicChannelDescriptors(completion: TCHChannelDescriptorPaginatorCompletion!) {
        
        guard self.connected else {
        
            return completion(nil, nil)
        }
        
        super.publicChannelDescriptors(completion: completion)
    }
    
    override func createChannel(options: [AnyHashable : Any]! = [:], completion: TCHChannelCompletion!) {
        
        guard self.connected else {
            
            return completion(nil, nil)
        }
        
        super.createChannel(options: options, completion: completion)
    }
    
    override func channel(withSidOrUniqueName sidOrUniqueName: String!, completion: TCHChannelCompletion!) {
        
        guard self.connected else {
            
            return completion(nil, nil)
        }
        
        super.channel(withSidOrUniqueName: sidOrUniqueName, completion: completion)
    }
}
