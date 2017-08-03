//
//  TCHOfflineMessages.swift
//  twiliochat
//
//  Created by Robert Norris on 02.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation
import TwilioChatClient



class TCHOfflineMessages: TCHMessages {
    
    private var connected: Bool = false
    private var channel: TCHChannel?
    private var offlineMessages: [TCHOfflineMessage] = []
    
    func load(fromStore store: ChatStore, inChannel channel: TCHChannel, completion: (() -> ())? = nil) {
        
        let loadGroup = DispatchGroup()
        
        loadGroup.enter()
        store.storedMessages(forChannel: channel) { storedMessages in
            
            let offlineMessages = storedMessages.map { (storedMessage) -> TCHOfflineMessage in
                
                return TCHOfflineMessage(storedMessage)
            }
            
            self.offlineMessages = offlineMessages
            
            loadGroup.leave()
        }
    }
    
    func connect(toMessages messagesList: TCHMessages, inChannel channel: TCHChannel) {
        
        self.channel = channel
        messagesList.getLastWithCount(100) { (result, messages) in

            guard let lastMessages = messages else {
                
                return
            }
            
            let offlineMessages = lastMessages.map { (message) -> TCHOfflineMessage in
                
                return TCHOfflineMessage(message.storable(forChannel: channel))
            }
            
            self.offlineMessages = offlineMessages
            self.connected = true
        }
    }
    
    func disconnect(updatingStore store: ChatStore? = nil) {
        
        self.connected = false
        
        guard let channel = self.channel else {
            
            return
        }
        
        store?.storeMessages(forChannel: channel, messages: self.offlineMessages)
    }

    override var lastConsumedMessageIndex: NSNumber! {
        
        return nil
    }
    
    override func createMessage(withBody body: String!) -> TCHMessage! {
        
        return nil
    }
    
    override func send(_ message: TCHMessage!, completion: TCHCompletion!) {
        
        completion(nil)
    }
    
    override func remove(_ message: TCHMessage!, completion: TCHCompletion!) {
        
        completion(nil)
    }
    
    override func getLastWithCount(_ count: UInt, completion: TCHMessagesCompletion!) {
        
        completion(TCHOfflineResult(), self.offlineMessages)
    }
    
    override func getBefore(_ index: UInt, withCount count: UInt, completion: TCHMessagesCompletion!) {
        
        completion(nil, nil)
    }
    
    override func getAfter(_ index: UInt, withCount count: UInt, completion: TCHMessagesCompletion!) {
        
        completion(nil, nil)
    }
    
    override func message(withIndex index: NSNumber!, completion: TCHMessageCompletion!) {
        
        completion(nil, nil)
    }
    
    override func message(forConsumptionIndex index: NSNumber!, completion: TCHMessageCompletion!) {
        
        completion(nil, nil)
    }
    
    override func setLastConsumedMessageIndex(_ index: NSNumber!) {
        
    }
    
    override func advanceLastConsumedMessageIndex(_ index: NSNumber!) {
        
    }
    
    override func setAllMessagesConsumed() {
        
    }
    
    override func setNoMessagesConsumed() {
        
    }
}
