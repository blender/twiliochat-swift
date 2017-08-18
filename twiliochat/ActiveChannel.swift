//
//  ActiveChannel.swift
//  twiliochat
//
//  Created by Robert Norris on 02.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation



protocol ActiveChatChannelDelegate: class {
    
    func activeChatChannel(_ channel: ActiveChatChannel, addedMessage: ChatMessage)
    func activeChatChannel(_ channel: ActiveChatChannel, deletedMessage: ChatMessage)
    func activeChatChannel(_ channel: ActiveChatChannel, updatedMessage: ChatMessage)
    
    func activeChatChannel(_ channel: ActiveChatChannel, addedMember: ChatMember)
    func activeChatChannel(_ channel: ActiveChatChannel, deletedMember: ChatMember)
    func activeChatChannel(_ channel: ActiveChatChannel, updatedMember: ChatMember)
    
    func activeChatChannel(_ channel: ActiveChatChannel, memberStartedTyping: ChatMember)
    func activeChatChannel(_ channel: ActiveChatChannel, memberStoppedTyping: ChatMember)
}



extension ActiveChatChannelDelegate {
    
    func activeChatChannel(_ channel: ActiveChatChannel, addedMessage: ChatMessage) {}
    func activeChatChannel(_ channel: ActiveChatChannel, deletedMessage: ChatMessage) {}
    func activeChatChannel(_ channel: ActiveChatChannel, updatedMessage: ChatMessage) {}
    
    func activeChatChannel(_ channel: ActiveChatChannel, addedMember: ChatMember) {}
    func activeChatChannel(_ channel: ActiveChatChannel, deletedMember: ChatMember) {}
    func activeChatChannel(_ channel: ActiveChatChannel, updatedMember: ChatMember) {}
    
    func activeChatChannel(_ channel: ActiveChatChannel, memberStartedTyping: ChatMember) {}
    func activeChatChannel(_ channel: ActiveChatChannel, memberStoppedTyping: ChatMember) {}
}



protocol ActiveChatChannel: ChatChannel {
    
    var creator: StoredMember? { get }
    var others: [StoredMember] { get }
    
    var messagingManager: MessagingManager { get }
    
    weak var delegate: ActiveChatChannelDelegate? { get set }
    
    func sendMessage(_ message: String)
    func removeMessage(atIndex: Int)
    func advanceLastConsumedMessageIndex(_ index: Int)
    
    func typing()
    
    func getUnreadMessageCountForMember(_ member: ChatMember) -> Int?
    func getMembersWithConsumptionHorizonBeyondMessageIndex(_ index: Int) -> [ChatMember]
    
    func getMemberCountWithConsumptionHorizonBeyondMessageIndex(_ index: Int) -> Int
    func didAnyMemberConsumeMessageWithIndex(_ index: Int) -> Bool
    func didAllMembersConsumeMessageWithIndex(_ index: Int) -> Bool
}



extension ActiveChatChannel {
    
    func sendMessage(_ body: String) {
        
        self.messagingManager.sendMessage(body, inChannel: self)
    }
    
    func removeMessage(atIndex index: Int) {
        
        self.messagingManager.removeMessage(atIndex: index, fromChannel: self)
    }
    
    func advanceLastConsumedMessageIndex(_ index: Int) {
        
        self.messagingManager.advanceLastConsumedMessageIndex(index, forChannel: self)
    }
    
    func typing() {
        
        self.messagingManager.typingInChannel(self)
    }
}



typealias ChannelMembershipHandler = (_ creator: StoredMember?, _ others: [StoredMember]) -> ()



enum MessageOrder {
    
    case ascendingOrderOfIndex
    case descendingOrderOfIndex
    case ascendingOrderOfTimestamp
    case descendingOrderOfTimestamp
}



class ActiveChannel: ActiveChatChannel {
    
    weak var delegate: ActiveChatChannelDelegate?
    
    let messageOrder: MessageOrder = .descendingOrderOfTimestamp // TODO: allow this to be changed
    
    fileprivate(set) var channel: StoredChannel
    fileprivate(set) var messages: [StoredMessage]
    fileprivate(set) var members: Set<StoredMember> = Set<StoredMember>()
    fileprivate(set) var users: Set<StoredUser> = Set<StoredUser>()
    
    private(set) var creator: StoredMember? = nil
    private(set) var others: [StoredMember] = []
    
    private(set) var messagingManager: MessagingManager
    
    init(messagingManager: MessagingManager
        , storedChannel: StoredChannel
        , storedUsers: [StoredUser]
        , storedMembers: [StoredMember]
        , storedMessages: [StoredMessage] = []) {
        
        self.messagingManager = messagingManager
        
        self.channel = storedChannel
        self.users = Set(storedUsers)
        self.members = Set(storedMembers)
        self.messages = storedMessages.sortedInDescendingOrderOfTimestamp
        
        self.creator = self.members.first { $0.identity == self.createdBy }
        self.others = self.members.filter { $0.identity != self.createdBy }
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
    
    var displayName: String {
        
        return self.friendlyName ?? self.sid
    }
    
    var latestMessage: StoredMessage? {
        
        switch self.messageOrder {
        case .ascendingOrderOfIndex
        , .ascendingOrderOfTimestamp:
            
            return self.messages.last
            
        default:
            
            return self.messages.first
        }
    }
    
    func getUnreadMessageCountForMember(_ member: ChatMember) -> Int? {
        
        guard let latestMessageIndex = self.latestMessage?.index else {
            
            return nil
        }
        
        guard let lastConsumedMessageIndex = member.lastConsumedMessageIndex else {
            
            return latestMessageIndex
        }
        
        return latestMessageIndex - lastConsumedMessageIndex
    }
    
    func getMembersWithConsumptionHorizonBeyondMessageIndex(_ index: Int) -> [ChatMember] {
        
        return self.members.filter { $0.lastConsumedMessageIndex.flatMap { $0 > index } ?? false }
    }
    
    func getMemberCountWithConsumptionHorizonBeyondMessageIndex(_ index: Int) -> Int {
        
        return self.getMembersWithConsumptionHorizonBeyondMessageIndex(index).count
    }
    
    func didAnyMemberConsumeMessageWithIndex(_ index: Int) -> Bool {
        
        return self.getMemberCountWithConsumptionHorizonBeyondMessageIndex(index) > 0
    }
    
    func didAllMembersConsumeMessageWithIndex(_ index: Int) -> Bool {
        
        return self.getMemberCountWithConsumptionHorizonBeyondMessageIndex(index) == self.members.count
    }
}



extension ActiveChannel: MessagingDelegate {
    
    func messagingManager(_ messagingManager: MessagingManager, deletedChannel channel: ChatChannel) {
        
        // TODO: if this channel then bail!
    }
    
    func messagingManager(_ messagingManager: MessagingManager, updatedChannel channel: ChatChannel) {
        
        guard channel.sid == self.channel.sid else {
            
            return
        }
        
        let storableChannel = StoredChannel(channel: channel)
        self.channel = storableChannel
    }
    
    func messagingManager(_ messagingManager: MessagingManager, addedMessage message: ChatMessage, toChannel channel: ChatChannel) {
        
        guard channel.sid == self.channel.sid else {
            
            return
        }
        
        let storableMessage = StoredMessage(message: message, inChannel: channel)
        
        let storableMessages = Set([storableMessage] + self.messages)
        self.messages = storableMessages.sortedInDescendingOrderOfTimestamp
        
        self.delegate?.activeChatChannel(self, addedMessage: message)
    }
    
    func messagingManager(_ messagingManager: MessagingManager, deletedMessage message: ChatMessage, fromChannel channel: ChatChannel) {
        
        guard channel.sid == self.channel.sid else {
            
            return
        }
        
        let storableMessage = StoredMessage(message: message, inChannel: channel)
        
        var storableMessages = Set(self.messages)
        storableMessages.remove(storableMessage)
        self.messages = storableMessages.sortedInDescendingOrderOfTimestamp
        
        self.delegate?.activeChatChannel(self, deletedMessage: message)
    }
    
    func messagingManager(_ messagingManager: MessagingManager, updatedMessage message: ChatMessage, inChannel channel: ChatChannel) {
        
        guard channel.sid == self.channel.sid else {
            
            return
        }
        
        let storableMessage = StoredMessage(message: message, inChannel: channel)
        
        var storableMessages = Set(self.messages)
        storableMessages.update(with: storableMessage)
        self.messages = storableMessages.sortedInDescendingOrderOfTimestamp
        
        self.delegate?.activeChatChannel(self, updatedMessage: message)
    }
    
    func messagingManager(_ messagingManager: MessagingManager, addedMember member: ChatMember, toChannel channel: ChatChannel) {
        
        guard channel.sid == self.channel.sid else {
            
            return
        }
        
        let storableMember = StoredMember(member: member, inChannel: channel)
        
        let storableMembers = Set([storableMember] + self.members)
        self.members = storableMembers
        
        self.delegate?.activeChatChannel(self, addedMember: member)
    }
    
    func messagingManager(_ messagingManager: MessagingManager, deletedMember member: ChatMember, fromChannel channel: ChatChannel) {
        
        guard channel.sid == self.channel.sid else {
            
            return
        }
        
        let storableMember = StoredMember(member: member, inChannel: channel)
        
        var storableMembers = Set(self.members)
        storableMembers.remove(storableMember)
        self.members = storableMembers
        
        self.delegate?.activeChatChannel(self, deletedMember: member)
    }
    
    func messagingManager(_ messagingManager: MessagingManager, updatedMember member: ChatMember, inChannel channel: ChatChannel) {
        
        guard channel.sid == self.channel.sid else {
            
            return
        }
        
        let storableMember = StoredMember(member: member, inChannel: channel)
        
        var storableMembers = Set(self.members)
        storableMembers.update(with: storableMember)
        self.members = storableMembers
        
        self.delegate?.activeChatChannel(self, updatedMember: member)
    }
    
    func messagingManager(_ messagingManager: MessagingManager, memberStartedTyping member: ChatMember, inChannel channel: ChatChannel) {
        
        self.delegate?.activeChatChannel(self, memberStartedTyping: member)
    }
    
    func messagingManager(_ messagingManager: MessagingManager, memberStoppedTyping member: ChatMember, inChannel channel: ChatChannel) {
        
        self.delegate?.activeChatChannel(self, memberStoppedTyping: member)
    }
}



extension ActiveChannel: Equatable {
    
    public static func ==(lhs: ActiveChannel, rhs: ActiveChannel) -> Bool {
        
        return lhs.sid == rhs.sid
    }
}



extension ActiveChannel: Hashable {
    
    public var hashValue: Int {
        
        return self.sid.hash
    }
}


