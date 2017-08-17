//
//  TCHChannelManager.swift
//  twiliochat
//
//  Created by Robert Norris on 16.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//



class TCHChannelManager: ChannelManager {

    weak var delegate: ChannelDelegate?
    
    init(messagingManager: MessagingManager) {
        
        self.messagingManager = messagingManager
    }
    
//    func addChannel(_ channel: ChatChannel) {
//
//        self.messagingManager.addChannel(channel)
//    }
//    
//    func deleteChannel(_ channel: ChatChannel) {
//
//        self.messagingManager.deleteChannel(channel)
//    }
//    
//    func updateChannel(_ channel: ChatChannel) {
//
//        self.messagingManager.updateChannel(channel)
//    }

    func sendMessage(_ body: String, inChannel channel: ChatChannel) {
        
        self.messagingManager.sendMessage(body, inChannel: channel)
    }
    
    func removeMessage(atIndex index: Int, fromChannel channel: ChatChannel) {

        self.messagingManager.removeMessage(atIndex: index, fromChannel: channel)
    }
    
    func advanceLastConsumedMessageIndex(_ index: Int, forChannel channel: ChatChannel) {
        
        self.messagingManager.advanceLastConsumedMessageIndex(index, forChannel: channel)
    }
    
    func activateChannel(_ channel: ChatChannel, completion: @escaping ActiveChannelHandler) {
        
        self.messagingManager.activateChannel(channel, completion: completion)
    }
    
    func deactivateChannel(_ channel: ActiveChannel) {
        
        self.messagingManager.deactivateChannel(channel)
    }
}



extension TCHChannelManager: TCHChannelDelegate {
    
    func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, messageAdded message: TCHMessage!) {
        
    }
    
    
    /** Called when a message on a channel the current user is subscribed to is modified.
     
     @param client The chat client.
     @param channel The channel.
     @param message The message.
     @param updated An indication of what changed on the message.
     */
    optional public func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, message: TCHMessage!, updated: TCHMessageUpdate)
    
    
    /** Called when a message on a channel the current user is subscribed to is deleted.
     
     @param client The chat client.
     @param channel The channel.
     @param message The message.
     */
    optional public func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, messageDeleted message: TCHMessage!)

}
