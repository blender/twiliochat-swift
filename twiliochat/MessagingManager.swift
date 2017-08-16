//
//  TCHMessagingManager.swift
//  twiliochat
//
//  Created by Robert Norris on 16.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//



protocol MessagingDelegate : ChannelDelegate {
    
    func messagingManager(_: MessagingManager, addedMessage: StoredMessage, toChannel: StoredChannel)
    func messagingManager(_: MessagingManager, deletedMessage: StoredMessage, fromChannel: StoredChannel)
    func messagingManager(_: MessagingManager, updatedMessage: StoredMessage, inChannel: StoredChannel)
}



typealias StartupHandler = ((Bool, NSError?) -> ())



protocol MessagingManager {
    
    static func sharedManager() -> MessagingManager
    
    var channelManager: ChannelManager { get }
    var delegate: MessagingDelegate? { get set }
    
    var user: StoredUser? { get }
    
    func loginWithUsername(_: String, completion: StartupHandler?)
    func logout()
    
    func startup(completion: StartupHandler?)
    func shutdown()
    
    func activateChannel(_: ChatChannel, completion: @escaping ActiveChannelHandler)
    
    func sendMessage(_: String, inChannel: ChatChannel)
    func removeMessage(atIndex: Int, fromChannel: ChatChannel)
    func advanceLastConsumedMessageIndex(_ index: Int, forChannel: ChatChannel)
}
