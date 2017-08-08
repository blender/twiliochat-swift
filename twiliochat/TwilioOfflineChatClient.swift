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
    
    init(delegate: TwilioChatClientDelegate!) {
        
        super.init()
        
        super.delegate = delegate
        
        self.load() {
        
            self.delegate?.chatClient?(self, synchronizationStatusUpdated: self.synchronizationStatus)
        }
    }
    
    func load(completion: (() -> ())? = nil) {
        
        self.offlineChannels.load(offlineChatClient: self) {
            
            completion?()
        }
    }
    
    func save() {
        
        self.offlineChannels.save(toStore: self.store)
    }
    
    typealias OfflineChannelsHandler = (([TCHOfflineChannel]) -> ())
    
    func collectOfflineChannelsFromPaginator(_ paginator: TCHChannelDescriptorPaginator
        , accumulator: [TCHOfflineChannel]
        , onLastPage: @escaping OfflineChannelsHandler) {
        
        let group = DispatchGroup()
        
        var offlineChannels: [TCHOfflineChannel] = []
        paginator.items().forEach { (channelDescriptor) in
            
            group.enter() // .channel
            channelDescriptor.channel { result, channel in
                
                guard result?.isSuccessful() ?? false else { return }
                
                let storedChannel = channel!.storable
            
                group.enter() // .getLastWithCount
                channel!.messages.getLastWithCount(100) { result, messages in
                    
                    let storedMessages: [TCHStoredMessage] = messages!.map { (message) in
                     
                        return message.storable(forChannel: channel!)
                    }
                
                    let offlineChannel = TCHOfflineChannel(storedChannel, storedMessages: storedMessages)
                    offlineChannels.append(offlineChannel)
                    
                    group.leave() // .getLastWithCount
                }
                
                group.leave() // .channel
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            
            let newAcc = accumulator + offlineChannels

            if paginator.hasNextPage() {
                
                paginator.requestNextPage { [weak self] result, paginator in
                    
                    guard result?.isSuccessful() ?? false else {
                        
                        onLastPage(newAcc)
                        return
                    }
                    
                    self?.collectOfflineChannelsFromPaginator(paginator!, accumulator: newAcc, onLastPage: onLastPage)
                }
            }
            else {
                
                onLastPage(newAcc)
            }
        }
    }
    
    func connect(toClient client: TwilioChatClient) {
        
        self.client = client
        
        client.channelsList().userChannelDescriptors { [weak self] result, paginator in
            
            guard result?.isSuccessful() ?? false else {
                
                return
            }
            
            self?.collectOfflineChannelsFromPaginator(paginator!, accumulator: []) { [weak self] offlineChannels in

                guard let selfie = self else { return }
                
                selfie.offlineChannels = TCHOfflineChannels(offlineChannels)
                
                selfie.save()

                selfie.offlineChannels.offlineChannels.forEach { (offlineChannel) in
                    
                    offlineChannel.delegate?.chatClient?(selfie, channel: offlineChannel, synchronizationStatusUpdated: offlineChannel.synchronizationStatus)
                }
                
                selfie.delegate?.chatClient?(selfie, synchronizationStatusUpdated: selfie.synchronizationStatus)
            }
        }
    }
    
    func disconnect() {
        
        guard let client = self.client else {
            
            return
        }
        
        self.save()
        
        client.shutdown()
        self.client = nil
        
        self.delegate?.chatClient?(self, synchronizationStatusUpdated: self.synchronizationStatus)
    }

    var isConnectedToClient: Bool {
        
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
            
            return nil
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
        self.disconnect()
    }
}
