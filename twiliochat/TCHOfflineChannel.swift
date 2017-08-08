//
//  TCHOfflineChannel.swift
//  twiliochat
//
//  Created by Robert Norris on 02.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation
import TwilioChatClient

class TCHOfflineChannel : TCHChannel {
    
//    private var connected: Bool = false
    private var storedChannel: TCHStoredChannel!
    var offlineMessages: TCHOfflineMessages!
    
    init(_ storedChannel: TCHStoredChannel, storedMessages: [TCHStoredMessage] = []) {
        
        super.init()
        
        self.storedChannel = storedChannel
        self.offlineMessages = TCHOfflineMessages(storedMessages)
    }

//    func load(offlineChatClient client: TwilioOfflineChatClient, completion: (() -> ())? = nil) {
//        
//        self.offlineMessages.load(fromStore: client.store, inChannel: self) {
//        
//            self.delegate?.chatClient?(client, channel: self, synchronizationStatusUpdated: self.synchronizationStatus)
//            completion?()
//        }
//    }
    
    func save(toStore store: ChatStore) {
        
        self.offlineMessages.save(toStore: store, forChannel: self)
    }
    
//    func connect(toChannel channel: TCHChannel) {
//        
//        self.offlineMessages.connect(toMessages: channel.messages, inChannel: channel)
//        
//        self.connected = true
//    }
//    
//    func disconnect() {
//        
//        self.offlineMessages.disconnect()
//        self.connected = false
//    }
    
    //weak open var delegate: TCHChannelDelegate!
    
    override var sid: String! {
        
        return self.storedChannel.sid
    }
    
    override var friendlyName: String! {
        
        return self.storedChannel.friendlyName
    }
    
    override var uniqueName: String! {
        
        return self.storedChannel.uniqueName
    }
    
    override var messages: TCHMessages! {
        
        return self.offlineMessages
    }
    
    override var members: TCHMembers! {
        
        return nil
        //return self.storedChannel.members
    }
    
    override var synchronizationStatus: TCHChannelSynchronizationStatus {
        
        return .all
    }
    
    override var status: TCHChannelStatus {
        
        return self.storedChannel.status ?? .unknown
    }
    
    override var type: TCHChannelType {
        
        return .public
        //return self.storedChannel.
    }
    
    override var dateCreated: String! {
        
        return nil
        //return self.storedChannel.
    }
    
    override var dateCreatedAsDate: Date! {
        
        return nil
    }
    
    override var createdBy: String! {
        
        return nil
    }
    
    override var dateUpdated: String! {
        
        return nil
    }
    
    override var dateUpdatedAsDate: Date! {
        
        return nil
    }
    
    override func attributes() -> [String : Any]! {
        
        return nil
    }
    
    override func setAttributes(_ attributes: [String : Any]!, completion: TCHCompletion!) {
        
        completion(nil)
    }
    
    override func setFriendlyName(_ friendlyName: String!, completion: TCHCompletion!) {
        
        completion(nil)
    }
    
    override func setUniqueName(_ uniqueName: String!, completion: TCHCompletion!) {
        
        completion(nil)
    }
    
    override func join(completion: TCHCompletion!) {
        
        completion(nil)
    }
    
    override func declineInvitation(completion: TCHCompletion!) {
        
        completion(nil)
    }
    
    override func leave(completion: TCHCompletion!) {
        
        completion(nil)
    }
    
    override func destroy(completion: TCHCompletion!) {
        
        completion(nil)
    }
    
    override func typing() {
        
    }
    
    override func member(withIdentity identity: String!) -> TCHMember! {
        
        return nil
    }
    
    override func getUnconsumedMessagesCount(completion: TCHCountCompletion!) {
        
        completion(nil, 0)
    }
    
    override func getMessagesCount(completion: TCHCountCompletion!) {
        
        completion(nil, 0)
    }
    
    override func getMembersCount(completion: TCHCountCompletion!) {
        
        completion(nil, 0)
    }
}
