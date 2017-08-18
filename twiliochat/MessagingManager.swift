//
//  MessagingManager.swift
//  twiliochat
//
//  Created by Robert Norris on 16.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//



protocol MessagingDelegate: class {
    
    func messagingManager(_ messagingManager: MessagingManager, addedChannel: ChatChannel)
    func messagingManager(_ messagingManager: MessagingManager, deletedChannel: ChatChannel)
    func messagingManager(_ messagingManager: MessagingManager, updatedChannel: ChatChannel)
    
    func messagingManager(_ messagingManager: MessagingManager, addedMessage: ChatMessage, toChannel: ChatChannel)
    func messagingManager(_ messagingManager: MessagingManager, deletedMessage: ChatMessage, fromChannel: ChatChannel)
    func messagingManager(_ messagingManager: MessagingManager, updatedMessage: ChatMessage, inChannel: ChatChannel)
    
    func messagingManager(_ messagingManager: MessagingManager, memberStartedTyping: ChatMember, inChannel: ChatChannel)
    func messagingManager(_ messagingManager: MessagingManager, memberStoppedTyping: ChatMember, inChannel: ChatChannel)
}



extension MessagingDelegate {
    
    func messagingManager(_ messagingManager: MessagingManager, addedChannel: ChatChannel) {}
    func messagingManager(_ messagingManager: MessagingManager, deletedChannel: ChatChannel) {}
    func messagingManager(_ messagingManager: MessagingManager, updatedChannel: ChatChannel) {}
    
    func messagingManager(_ messagingManager: MessagingManager, addedMessage: ChatMessage, toChannel: ChatChannel) {}
    func messagingManager(_ messagingManager: MessagingManager, deletedMessage: ChatMessage, fromChannel: ChatChannel) {}
    func messagingManager(_ messagingManager: MessagingManager, updatedMessage: ChatMessage, inChannel: ChatChannel) {}
    
    func messagingManager(_ messagingManager: MessagingManager, memberStartedTyping: ChatMember, inChannel: ChatChannel) {}
    func messagingManager(_ messagingManager: MessagingManager, memberStoppedTyping: ChatMember, inChannel: ChatChannel) {}
}



typealias StartupHandler = ((Bool, NSError?) -> ())
typealias ActiveChannelHandler = ((ActiveChannel?) -> ())


protocol MessagingManager {
    
    static func sharedManager() -> MessagingManager
    
    weak var delegate: MessagingDelegate? { get set }
    
    var user: StoredUser? { get }
    var channels: [StoredChannel] { get }
    var activeChannels: Set<ActiveChannel> { get }
    
    func loginWithUsername(_: String, completion: StartupHandler?)
    func logout()
    
    func startup(completion: StartupHandler?)
    func shutdown()
    
    func activateChannel(_: ChatChannel, completion: @escaping ActiveChannelHandler)
    func deactivateChannel(_ channel: ActiveChannel)
    
    func sendMessage(_: String, inChannel: ChatChannel)
    func removeMessage(atIndex: Int, fromChannel: ChatChannel)
    func advanceLastConsumedMessageIndex(_ index: Int, forChannel: ChatChannel)
    
    func typingInChannel(_ channel: ChatChannel)
    
    func addChannel(_ channel: ChatChannel)
    func deleteChannel(_ channel: ChatChannel)
    func updateChannel(_ channel: ChatChannel)
}
