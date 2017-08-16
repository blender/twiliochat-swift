//
//  TCHChannels+Storable.swift
//  twiliochat
//
//  Created by Robert Norris on 09.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

//import TwiliChatClient


typealias TCHChannelsSuccessCompletion = (Bool, [TCHChannel]) -> ()
typealias TCHMessagesSuccessCompletion = (Bool, [TCHMessage]) -> ()

typealias SuccessHandler = ((Bool) -> ())


extension TCHChannels {
    
    func store(storeChannels channels: ChannelsHandler?
        , storeMessages messages: MessagesHandler?
        , storeMembers members: MembersHandler?
        , storeUsers users: UsersHandler?
        , completion: SuccessHandler?) {
        
        let group = DispatchGroup()
        
        var completed = true
        group.enter() // .userChannelDescriptors
        self.userChannelDescriptors { [weak self] result, paginator in
            
            guard result?.isSuccessful() ?? false else {
        
                completed = false
                group.leave() // .userChannelDescriptors
                return
            }
            
            group.enter() // .collectChannelsFromPaginator
            self?.collectChannelsFromPaginator(paginator!, accumulator: []) { (success, storeableChannels) in

                guard success else {
                
                    completed = false
                    group.leave() // .collectChannelsFromPaginator
                    return
                }
                
                // TODO: partial results?
                
                let storedChannels = storeableChannels.map { $0.storable }
                channels?(storedChannels)
                
                storeableChannels.forEach { (storeableChannel) in

                    group.enter() // .collectMessagesFromChannel
                    self?.collectMessagesFromChannel(storeableChannel) { (sucess, storeableMessages) in

                        guard success else {
                    
                            completed = false
                            group.leave() // .collectMessagesFromChannel
                            return
                        }
                        
                        let storedChannel = storeableChannel.storable
                        let storedMessages = storeableMessages.map { $0.storable(forChannel: storeableChannel) }
                        messages?(storedChannel, storedMessages)

                        group.enter() // .members.store
                        storeableChannel.store(storeMembers: members, storeUsers: users) { (success) in
                         
                            guard success else {
                                
                                completed = false
                                group.leave() // .members.store
                                return
                            }
                            
                            group.leave() // .members.store
                        }
                        
                        group.leave() // .collectMessagesFromChannel
                    }
                }
                
                group.leave() // .collectChannelsFromPaginator
            }
            
            group.leave() // .userChannelDescriptors
        }
        
        group.notify(queue: DispatchQueue.main) {
            
            completion?(completed)
        }
    }
    
    func collectMessagesFromChannel(_ channel: TCHChannel
        , completion: TCHMessagesSuccessCompletion?) {
        
        channel.messages.getLastWithCount(100) { result, messages in
            
            guard result?.isSuccessful() ?? false
                , let storableMessages = messages else {
        
                completion?(false, [])
                return
            }
            
            completion?(true, storableMessages)
        }
    }
    
    func collectUsersFrommembers(_ members: [TCHMember]
        , completion: TCHUsersSuccessCompletion?) {
    
        let group = DispatchGroup()
        
        var completed = true
        var users: [TCHUser] = []
        members.forEach { (member) in

            group.enter() // .userDescriptor
            member.userDescriptor { (result, userDescriptor) in
                
                guard result?.isSuccessful() ?? false else {
            
                    group.leave() // .userDescriptor
                    completed = false
                    return
                }
            
                group.enter() // .subscribe
                userDescriptor?.subscribe { (result, user) in
                    
                    guard result?.isSuccessful() ?? false
                        , let storeableUser = user else {
                
                        group.leave() // .subscribe
                        completed = false
                        return
                    }
                    
                    users.append(storeableUser)
                    group.leave() // .subscribe
                }
                
                group.leave() // .userDescriptor
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
        
            completion?(completed, users)
        }
    }
    
    func collectChannelsFromPaginator(_ paginator: TCHChannelDescriptorPaginator
        , accumulator: [TCHChannel]
        , completion: TCHChannelsSuccessCompletion?) {
        
        let group = DispatchGroup()
        
        var channels: [TCHChannel] = []
        paginator.items().forEach { (channelDescriptor) in
            
            group.enter() // .channel
            channelDescriptor.channel { result, channel in
                
                guard result?.isSuccessful() ?? false
                    , let storeableChannel = channel else {
                        
                        group.leave() // .channel
                        return
                }
                
                channels.append(storeableChannel)
                group.leave() // .channel
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            
            let accumulated = accumulator + channels
            
            if paginator.hasNextPage() {
                
                paginator.requestNextPage { [weak self] result, paginator in
                    
                    guard result?.isSuccessful() ?? false else {
                        
                        completion?(false, accumulated)
                        return
                    }
                    
                    self?.collectChannelsFromPaginator(paginator!
                        , accumulator: accumulated
                        , completion: completion)
                }
            }
            else {
                
                completion?(true, accumulated)
            }
        }
    }
}
