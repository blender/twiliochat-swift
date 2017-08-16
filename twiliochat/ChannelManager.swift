//
//  ChannelManager.swift
//  twiliochat
//
//  Created by Robert Norris on 16.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//



protocol ChannelDelegate {
    
    func channelManager(_ channelManager: ChannelManager, addedChannel: StoredChannel)
    func channelManager(_ channelManager: ChannelManager, deletedChannel: StoredChannel)
    func channelManager(_ channelManager: ChannelManager, updatedChannel: StoredChannel)
    
    func channelManager(_ channelManager: ChannelManager, memberStartedTyping: StoredMember, inChannel: StoredChannel)
    func channelManager(_ channelManager: ChannelManager, memberStoppedTyping: StoredMember, inChannel: StoredChannel)
}



extension ChannelDelegate {

    func channelManager(_ channelManager: ChannelManager, addedChannel: StoredChannel) { }
    func channelManager(_ channelManager: ChannelManager, deletedChannel: StoredChannel) { }
    func channelManager(_ channelManager: ChannelManager, updatedChannel: StoredChannel) { }
    
    func channelManager(_ channelManager: ChannelManager, memberStartedTyping: StoredMember, inChannel: StoredChannel) { }
    func channelManager(_ channelManager: ChannelManager, memberStoppedTyping: StoredMember, inChannel: StoredChannel) { }
}



typealias ActiveChannelHandler = ((ActiveChannel?) -> ())



protocol ChannelManager {
 
    var delegate: ChannelDelegate? { get set }
    
    var channels: [StoredChannel] { get }
    
    func addChannel(_: StoredChannel)
    func deleteChannel(_: StoredChannel)
    func updateChannel(_: StoredChannel)
    
    func member(_ member: StoredMember, startedTypingInChannel: StoredChannel)
    func member(_ member: StoredMember, stoppedTypingInChannel: StoredChannel)
    
    func sendMessage(_: String, inChannel: ChatChannel)
    func removeMessage(atIndex: Int, fromChannel: ChatChannel)
    
    func activateChannel(_: ChatChannel, completion: @escaping ActiveChannelHandler)
    
    func advanceLastConsumedMessageIndex(_ index: Int, forChannel: ChatChannel)
}
