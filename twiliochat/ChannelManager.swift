//
//  ChannelManager.swift
//  twiliochat
//
//  Created by Robert Norris on 16.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//



//protocol ChannelDelegate: class {
//    
//    func messagingManager(_ channelManager: ChannelManager, addedMessage: ChatMessage, toChannel: ChatChannel)
//    func messagingManager(_ channelManager: ChannelManager, deletedMessage: ChatMessage, fromChannel: ChatChannel)
//    func messagingManager(_ channelManager: ChannelManager, updatedMessage: ChatMessage, inChannel: ChatChannel)
//    
//    func channelManager(_ channelManager: ChannelManager, memberStartedTyping: ChatMember, inChannel: ChatChannel)
//    func channelManager(_ channelManager: ChannelManager, memberStoppedTyping: ChatMember, inChannel: ChatChannel)
//}
//
//
//
//extension ChannelDelegate {
//
//    func messagingManager(_ channelManager: ChannelManager, addedMessage: ChatMessage, toChannel: ChatChannel) {}
//    func messagingManager(_ channelManager: ChannelManager, deletedMessage: ChatMessage, fromChannel: ChatChannel) {}
//    func messagingManager(_ channelManager: ChannelManager, updatedMessage: ChatMessage, inChannel: ChatChannel) {}
//    
//    func channelManager(_ channelManager: ChannelManager, memberStartedTyping: ChatMember, inChannel: ChatChannel) {}
//    func channelManager(_ channelManager: ChannelManager, memberStoppedTyping: ChatMember, inChannel: ChatChannel) {}
//}







protocol ChannelManager {
 
    weak var delegate: ChannelDelegate? { get set }
            
    func sendMessage(_: String, inChannel: ChatChannel)
    func removeMessage(atIndex: Int, fromChannel: ChatChannel)
    
    func activateChannel(_ channel: ChatChannel, completion: @escaping ActiveChannelHandler)
    func deactivateChannel(_ channel: ActiveChannel)
    
    func advanceLastConsumedMessageIndex(_ index: Int, forChannel: ChatChannel)
    
//    func addChannel(_ channel: ChatChannel)
//    func deleteChannel(_ channel: ChatChannel)
//    func updateChannel(_ channel: ChatChannel)
}
