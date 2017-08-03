//
//  TwilioOfflineChatClient.swift
//  twiliochat
//
//  Created by Robert Norris on 01.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation

import TwilioChatClient

class TwilioOfflineChatClient: TwilioChatClient {
    
    private var client: TwilioChatClient?
    private(set) var store: ChatStore = UserDefaultChatStore()
    private lazy var offlineChannels: TCHOfflineChannels = {
        
        return TCHOfflineChannels()
    }()
    private lazy var offlineUsers: TCHOfflineUsers = {
        
        return TCHOfflineUsers()
    }()
    
    init(delegate: TwilioChatClientDelegate!) {
        
        super.init()
        
        super.delegate = delegate
        
        self.load(fromStore: self.store) {
            
            self.delegate?.chatClient?(self, synchronizationStatusUpdated: self.synchronizationStatus)
        }
    }
    
    func load(fromStore store: ChatStore, completion: (() -> ())? = nil) {
        
        let loadGroup = DispatchGroup()
        
        loadGroup.enter()
        self.offlineUsers.load(fromStore: store) {
            
            loadGroup.leave()
        }
        
        loadGroup.enter()
        self.offlineChannels.load(fromStore: store) {
            
            loadGroup.leave()
        }
        
        loadGroup.notify(queue: DispatchQueue.main) {
         
            completion?()
        }
    }
    
    func connect(toClient client: TwilioChatClient) {
        
        self.client = client

        self.offlineUsers.connect(toUsers: client.users())
        self.offlineChannels.connect(toChannels: client.channelsList())
        
        self.delegate?.chatClient?(self, synchronizationStatusUpdated: self.synchronizationStatus)
    }
    
    func disconnect() {
        
        guard let client = self.client else {
            
            return
        }
        
        self.offlineUsers.disconnect(updatingStore: self.store)
        self.offlineChannels.disconnect(updatingStore: self.store)
        
        client.shutdown()
        self.client = nil
        
        self.delegate?.chatClient?(self, synchronizationStatusUpdated: self.synchronizationStatus)
    }

    var isConnected: Bool {
        
        return self.client != nil
    }
    
    override var connectionState: TCHClientConnectionState {

        guard let client = self.client else {
            
            return .disconnected
        }
        
        return client.connectionState
    }
    
    override var synchronizationStatus: TCHClientSynchronizationStatus {

        guard let client = self.client else {
            
            return .completed
        }
        
        return client.synchronizationStatus
    }
    
    override func updateToken(_ token: String!, completion: TCHCompletion!) {

        guard let client = self.client else {
            
            return completion(nil)
        }
        
        return client.updateToken(token, completion: completion)
    }
    
    override func channelsList() -> TCHChannels! {
        
        guard let client = self.client else {
        
            return self.offlineChannels
        }
        
        return client.channelsList()
    }
    
    override func users() -> TCHUsers! {
    
        guard let client = self.client else {
            
            return self.offlineUsers
        }
        
        return client.users()
    }

    override func register(withNotificationToken token: Data!, completion: TCHCompletion!) {
        
        guard let client = self.client else {
            
            return completion(nil)
        }
        
        return client.register(withNotificationToken: token, completion: completion)
    }
    
    override func deregister(withNotificationToken token: Data!, completion: TCHCompletion!) {
        
        guard let client = self.client else {
            
            return completion(nil)
        }
        
        return client.deregister(withNotificationToken: token, completion: completion)
    }
    
    override func handleNotification(_ notification: [AnyHashable : Any]!, completion: TCHCompletion!) {
        
        guard let client = self.client else {
            
            return completion(nil)
        }
        
        return client.handleNotification(notification, completion: completion)
    }
    
    override func isReachabilityEnabled() -> Bool {
        
        guard let client = self.client else {
            
            return false
        }
        
        return client.isReachabilityEnabled()
    }
    
    override func shutdown() {
        
        guard let client = self.client else {
            
            return
        }
        
        client.shutdown()
        self.client = nil
    }
}
