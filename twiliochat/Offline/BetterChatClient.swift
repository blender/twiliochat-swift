//
//  BetterChatClient.swift
//  twiliochat
//
//  Created by Tommaso Piazza on 24.07.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation
import TwilioChatClient


public protocol BetterChatClientDelegate: class {
    
    /** Called when the client connection state changes.
     
     @param client The chat client.
     @param state The current connection state of the client.
     */
    func chatClient(_ client: BetterChatClient, connectionStateUpdated state: TCHClientConnectionState)
    
    
    /** Called when the client synchronization state changes during startup.
     
     @param client The chat client.
     @param status The current synchronization status of the client.
     */
    func chatClient(_ client: BetterChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus)
    
    
    /** Called when the current user has a channel added to their channel list.
     
     @param client The chat client.
     @param channel The channel.
     */
    func chatClient(_ client: BetterChatClient, channelAdded channel: TCHChannel)
    
    
    /** Called when one of the current users channels is changed.
     
     @param client The chat client.
     @param channel The channel.
     @param updated An indication of what changed on the channel.
     */
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, updated: TCHChannelUpdate)
    
    
    /** Called when a channel the current the client is aware of changes synchronization state.
     
     @param client The chat client.
     @param channel The channel.
     @param status The current synchronization status of the channel.
     */
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, synchronizationStatusUpdated status: TCHChannelSynchronizationStatus)
    
    
    /** Called when one of the current users channels is deleted.
     
     @param client The chat client.
     @param channel The channel.
     */
    func chatClient(_ client: BetterChatClient, channelDeleted channel: TCHChannel)
    
    
    /** Called when a channel the current user is subscribed to has a new member join.
     
     @param client The chat client.
     @param channel The channel.
     @param member The member.
     */
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, memberJoined member: TCHMember)
    
    
    /** Called when a channel the current user is subscribed to has a member modified.
     
     @param client The chat client.
     @param channel The channel.
     @param member The member.
     @param updated An indication of what changed on the member.
     */
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, member: TCHMember, updated: TCHMemberUpdate)
    
    
    /** Called when a channel the current user is subscribed to has a member leave.
     
     @param client The chat client.
     @param channel The channel.
     @param member The member.
     */
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, memberLeft member: TCHMember)
    
    
    /** Called when a channel the current user is subscribed to receives a new message.
     
     @param client The chat client.
     @param channel The channel.
     @param message The message.
     */
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, messageAdded message: TCHMessage)
    
    
    /** Called when a message on a channel the current user is subscribed to is modified.
     
     @param client The chat client.
     @param channel The channel.
     @param message The message.
     @param updated An indication of what changed on the message.
     */
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, message: TCHMessage, updated: TCHMessageUpdate)
    
    
    /** Called when a message on a channel the current user is subscribed to is deleted.
     
     @param client The chat client.
     @param channel The channel.
     @param message The message.
     */
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, messageDeleted message: TCHMessage)
    
    
    /** Called when an error occurs.
     
     @param client The chat client.
     @param error The error.
     */
    func chatClient(_ client: BetterChatClient, errorReceived error: TCHError)
    
    
    /** Called when a member of a channel starts typing.
     
     @param client The chat client.
     @param channel The channel.
     @param member The member.
     */
    func chatClient(_ client: BetterChatClient, typingStartedOn channel: TCHChannel, member: TCHMember)
    
    
    /** Called when a member of a channel ends typing.
     
     @param client The chat client.
     @param channel The channel.
     @param member The member.
     */
    func chatClient(_ client: BetterChatClient, typingEndedOn channel: TCHChannel, member: TCHMember)
    
    
    /** Called as a result of TwilioChatClient's handleNotification: method being invoked.  `handleNotification:` parses the push payload and extracts the channel and message for the push notification then calls this delegate method.
     
     @param client The chat client.
     @param channelSid The channel sid for the push notification.
     @param messageIndex The index of the new message.
     */
    func chatClient(_ client: BetterChatClient, notificationNewMessageReceivedForChannelSid channelSid: String, messageIndex: UInt)
    
    
    /** Called when a processed push notification has changed the application's badge count.  You should call:
     
     [[UIApplication currentApplication] setApplicationIconBadgeNumber:badgeCount]
     
     To ensure your application's badge updates when the application is in the foreground if Twilio is managing your badge counts.  You may disregard this delegate callback otherwise.
     
     @param client The chat client.
     @param badgeCount The updated badge count.
     */
    func chatClient(_ client: BetterChatClient, notificationUpdatedBadgeCount badgeCount: UInt)
    
    
    /** Called when the current user's or that of any subscribed channel member's user is updated.
     
     @param client The chat client.
     @param user The object for changed user.
     @param updated An indication of what changed on the user.
     */
    func chatClient(_ client: BetterChatClient, user: TCHUser, updated: TCHUserUpdate)
    
    
    /** Called when the client subscribes to updates for a given user.
     
     @param client The chat client.
     @param user The object for subscribed user.
     */
    func chatClient(_ client: BetterChatClient, userSubscribed user: TCHUser)
    
    
    /** Called when the client unsubscribes from updates for a given user.
     
     @param client The chat client.
     @param user The object for unsubscribed user.
     */
    func chatClient(_ client: BetterChatClient, userUnsubscribed user: TCHUser)
}

extension BetterChatClientDelegate {

    func chatClient(_ client: BetterChatClient, connectionStateUpdated state: TCHClientConnectionState) {}
    func chatClient(_ client: BetterChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {}
    func chatClient(_ client: BetterChatClient, channelAdded channel: TCHChannel) {}
    func chatClient(_ client: BetterChatClient, channelDeleted channel: TCHChannel) {}
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, updated: TCHChannelUpdate) {}
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, synchronizationStatusUpdated status: TCHChannelSynchronizationStatus) {}
    func chatClient(_ client: BetterChatClient, channelDeleted channel: TCHChannel!) {}
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, memberJoined member: TCHMember) {}
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, member: TCHMember, updated: TCHMemberUpdate) {}
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, memberLeft member: TCHMember) {}
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, messageAdded message: TCHMessage) {}
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, message: TCHMessage, updated: TCHMessageUpdate) {}
    func chatClient(_ client: BetterChatClient, channel: TCHChannel, messageDeleted message: TCHMessage) {}
    func chatClient(_ client: BetterChatClient, errorReceived error: TCHError) {}
    func chatClient(_ client: BetterChatClient, typingStartedOn channel: TCHChannel, member: TCHMember) {}
    func chatClient(_ client: BetterChatClient, typingEndedOn channel: TCHChannel, member: TCHMember) {}
    func chatClient(_ client: BetterChatClient, notificationNewMessageReceivedForChannelSid channelSid: String, messageIndex: UInt) {}
    func chatClient(_ client: BetterChatClient, notificationUpdatedBadgeCount badgeCount: UInt) {}
    func chatClient(_ client: BetterChatClient, user: TCHUser, updated: TCHUserUpdate) {}
    func chatClient(_ client: BetterChatClient, userSubscribed user: TCHUser) {}
    func chatClient(_ client: BetterChatClient, userUnsubscribed user: TCHUser) {}
}




public class BetterChatClient: NSObject {
    
    private var twilioChatClient: TwilioChatClient?
    
    weak var delegate: BetterChatClientDelegate?
    weak var chatStore: ChatStore?
    
    typealias SharecareChatClientCompletion = (Bool, BetterChatClient?) -> ()
    
    
    class func chatClient(withToken: String?
        , properties: TwilioChatClientProperties? = nil
        , delegate: BetterChatClientDelegate
        , chatStore: ChatStore?
        , completion: @escaping SharecareChatClientCompletion) {
        
        let chatClient = BetterChatClient()
        chatClient.delegate = delegate
        chatClient.chatStore = chatStore
        
        if withToken == nil {
            
            DispatchQueue.main.async {
                
                chatClient.delegate?.chatClient(chatClient, synchronizationStatusUpdated: TCHClientSynchronizationStatus.completed)
            }
            
            completion(true, chatClient)
        }
        else {

            TwilioChatClient.chatClient(withToken: withToken, properties: properties, delegate: chatClient) { result, client in
                
                if result?.isSuccessful() ?? false {
                    
                    chatClient.twilioChatClient = client
                    completion(true, chatClient)
                }
                else {
                    
                    completion(false, nil)
                }
            }
        }
    }
    
    func shutdown() {
        
        self.twilioChatClient?.shutdown()
    }
}

extension BetterChatClient: TwilioChatClientDelegate {
    
    
    /** Called when the client connection state changes.
     
     @param client The chat client.
     @param state The current connection state of the client.
     */
    public func chatClient(_ client: TwilioChatClient!, connectionStateUpdated state: TCHClientConnectionState) {
        
        self.delegate?.chatClient(self, connectionStateUpdated: state)
    }
    
    
    /** Called when the client synchronization state changes during startup.
     
     @param client The chat client.
     @param status The current synchronization status of the client.
     */
    public func chatClient(_ client: TwilioChatClient!, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        
        if status == TCHClientSynchronizationStatus.completed {
            
            guard let channelList = client.channelsList() else {
                
                self.delegate?.chatClient(self, synchronizationStatusUpdated: status)
                return
            }
            
            channelList.storeUserChannelDescriptors { [weak self] newChannels in
                
                guard let strongSelf = self else { return }
                
                strongSelf.chatStore?.storeChannels(newChannels)
                
                strongSelf.delegate?.chatClient(strongSelf, synchronizationStatusUpdated: status)
            }
        }
    }
    
    
    /** Called when the current user has a channel added to their channel list.
     
     @param client The chat client.
     @param channel The channel.
     */
    public func chatClient(_ client: TwilioChatClient!, channelAdded channel: TCHChannel!) {
        
        self.chatStore?.addChannel(channel.storable)
        
        self.delegate?.chatClient(self, channelAdded: channel)
    }
    
    
    /** Called when one of the current users channels is changed.
     
     @param client The chat client.
     @param channel The channel.
     @param updated An indication of what changed on the channel.
     */
    public func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, updated: TCHChannelUpdate) {
        
        self.delegate?.chatClient(self, channel: channel, updated: updated)
    }
    
    
    /** Called when a channel the current the client is aware of changes synchronization state.
     
     @param client The chat client.
     @param channel The channel.
     @param status The current synchronization status of the channel.
     */
    public func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, synchronizationStatusUpdated status: TCHChannelSynchronizationStatus) {
        
        self.delegate?.chatClient(self, channel: channel, synchronizationStatusUpdated: status)
    }
    
    
    /** Called when one of the current users channels is deleted.
     
     @param client The chat client.
     @param channel The channel.
     */
    public func chatClient(_ client: TwilioChatClient!, channelDeleted channel: TCHChannel!) {
        
        self.chatStore?.deleteChannel(channel.storable)
        self.delegate?.chatClient(self, channelDeleted: channel)
    }
    
    
    /** Called when a channel the current user is subscribed to has a new member join.
     
     @param client The chat client.
     @param channel The channel.
     @param member The member.
     */
    public func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, memberJoined member: TCHMember!) {
        
        self.delegate?.chatClient(self, channel: channel, memberJoined: member)
    }
    
    
    /** Called when a channel the current user is subscribed to has a member modified.
     
     @param client The chat client.
     @param channel The channel.
     @param member The member.
     @param updated An indication of what changed on the member.
     */
    public func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, member: TCHMember!, updated: TCHMemberUpdate) {
        
        self.delegate?.chatClient(self, channel: channel, member: member, updated: updated)
    }
    
    
    /** Called when a channel the current user is subscribed to has a member leave.
     
     @param client The chat client.
     @param channel The channel.
     @param member The member.
     */
    public func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, memberLeft member: TCHMember!) {
    
        self.delegate?.chatClient(self, channel: channel, memberLeft: member)
    }
    
    
    /** Called when a channel the current user is subscribed to receives a new message.
     
     @param client The chat client.
     @param channel The channel.
     @param message The message.
     */
    public func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, messageAdded message: TCHMessage!) {
        
        self.delegate?.chatClient(self, channel: channel, messageAdded: message)
    }
    
    
    /** Called when a message on a channel the current user is subscribed to is modified.
     
     @param client The chat client.
     @param channel The channel.
     @param message The message.
     @param updated An indication of what changed on the message.
     */
    public func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, message: TCHMessage!, updated: TCHMessageUpdate) {
        
        self.delegate?.chatClient(self, channel: channel, message: message, updated: updated)
    }
    
    
    /** Called when a message on a channel the current user is subscribed to is deleted.
     
     @param client The chat client.
     @param channel The channel.
     @param message The message.
     */
    public func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, messageDeleted message: TCHMessage!) {
        
        self.delegate?.chatClient(self, channel: channel, messageDeleted: message)
    }
    
    
    /** Called when an error occurs.
     
     @param client The chat client.
     @param error The error.
     */
    public func chatClient(_ client: TwilioChatClient!, errorReceived error: TCHError!) {
        
        self.delegate?.chatClient(self, errorReceived: error)
    }
    
    
    /** Called when a member of a channel starts typing.
     
     @param client The chat client.
     @param channel The channel.
     @param member The member.
     */
    public func chatClient(_ client: TwilioChatClient!, typingStartedOn channel: TCHChannel!, member: TCHMember!) {
        
        self.delegate?.chatClient(self, typingStartedOn: channel, member: member)
    }
    
    
    /** Called when a member of a channel ends typing.
     
     @param client The chat client.
     @param channel The channel.
     @param member The member.
     */
    public func chatClient(_ client: TwilioChatClient!, typingEndedOn channel: TCHChannel!, member: TCHMember!) {
        
        self.delegate?.chatClient(self, typingEndedOn: channel, member: member)
    }
    
    
    /** Called as a result of TwilioChatClient's handleNotification: method being invoked.  `handleNotification:` parses the push payload and extracts the channel and message for the push notification then calls this delegate method.
     
     @param client The chat client.
     @param channelSid The channel sid for the push notification.
     @param messageIndex The index of the new message.
     */
    public func chatClient(_ client: TwilioChatClient!, notificationNewMessageReceivedForChannelSid channelSid: String!, messageIndex: UInt) {
        
        self.delegate?.chatClient(self, notificationNewMessageReceivedForChannelSid: channelSid, messageIndex: messageIndex)
    }
    
    
    /** Called when a processed push notification has changed the application's badge count.  You should call:
     
     [[UIApplication currentApplication] setApplicationIconBadgeNumber:badgeCount]
     
     To ensure your application's badge updates when the application is in the foreground if Twilio is managing your badge counts.  You may disregard this delegate callback otherwise.
     
     @param client The chat client.
     @param badgeCount The updated badge count.
     */
    public func chatClient(_ client: TwilioChatClient!, notificationUpdatedBadgeCount badgeCount: UInt) {
        
        self.delegate?.chatClient(self, notificationUpdatedBadgeCount: badgeCount)
    }
    
    
    /** Called when the current user's or that of any subscribed channel member's user is updated.
     
     @param client The chat client.
     @param user The object for changed user.
     @param updated An indication of what changed on the user.
     */
    public func chatClient(_ client: TwilioChatClient!, user: TCHUser!, updated: TCHUserUpdate) {
        
        self.delegate?.chatClient(self, user: user, updated: updated)
    }
    
    
    /** Called when the client subscribes to updates for a given user.
     
     @param client The chat client.
     @param user The object for subscribed user.
     */
    public func chatClient(_ client: TwilioChatClient!, userSubscribed user: TCHUser!) {
        
        self.delegate?.chatClient(self, userSubscribed: user)
    }
    
    
    /** Called when the client unsubscribes from updates for a given user.
     
     @param client The chat client.
     @param user The object for unsubscribed user.
     */
    public func chatClient(_ client: TwilioChatClient!, userUnsubscribed user: TCHUser!) {
        
        self.delegate?.chatClient(self, userUnsubscribed: user)
    }
    
}
