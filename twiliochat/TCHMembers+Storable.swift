//
//  TCHMembers+Storable.swift
//  twiliochat
//
//  Created by Robert Norris on 15.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import TwilioChatClient



public typealias TCHMembersSuccessCompletion = (Bool, [TCHMember]) -> ()
public typealias TCHUsersSuccessCompletion = (Bool, [TCHUser]) -> ()



extension TCHMembers {
    
    func store(inChannel channel: TCHChannel
        ,storeMembers members: MembersHandler?
        , storeUsers users: UsersHandler?
        , completion: SuccessHandler?) {
        
        let group = DispatchGroup()
        
        var completed = true
        var storedUsers: [StoredUser] = []
        group.enter() // .members
        self.members { [weak self] (result, paginator) in
            
            guard result?.isSuccessful() ?? false else {
                
                completed = false
                group.leave() // .members
                return
            }
            
            group.enter() // .collectMembersFromPaginator
            self?.collectMembersFromPaginator(paginator!, accumulator: []) { (success, storeableMembers) in
                
                guard success else {
                    
                    completed = false
                    group.leave() // .collectMembersFromPaginator
                    return
                }
                
                let storedChannel = channel.storable
                let storedMembers = storeableMembers.map { $0.storable(forChannel: channel) }
                members?(storedChannel, storedMembers)
                
                storeableMembers.forEach { (member) in
                    
                    group.enter() // .userDescriptor
                    member.userDescriptor { (result, descriptor) in
                        
                        guard result?.isSuccessful() ?? false
                            , let userDescriptor = descriptor else {
                            
                            completed = false
                            group.leave() // .userDescriptor
                            return
                        }
                        
                        let storeableUser = StoredUser(identity: userDescriptor.identity
                            , friendlyName: userDescriptor.friendlyName, imageUrl: nil)
                        storedUsers.append(storeableUser)
                        
                        // Nota bene: Robert Norris - version 1.0.7 return 200 but nil when  trying to subscribe 
                        // so the StoredUser is constructed from the TCHUserDescriptor instead.
                        
                        // TODO: how does the subscribe model work and what does it givestoredUsers us?
                        
//                        group.enter() // .subscribe
//                        userDescriptor?.subscribe { (result, user) in
//                            
//                            guard result?.isSuccessful() ?? false
//                                , let storeableUser = user else {
//                                    
//                                    completed = false
//                                    group.leave() // .subscribe
//                                    return
//                            }
//                            
//                            users.append(storeableUser)
//                            group.leave() // .subscribe
//                        }
                        
                        group.leave() // .userDescriptor
                    }
                }
                
                group.leave() // .collectMembersFromPaginator
            }
            
            group.leave() // .members
        }
        
        group.notify(queue: DispatchQueue.main) {
            
            users?(storedUsers)
            completion?(completed)
        }
    }
    
    func collectMembersFromPaginator(_ paginator: TCHMemberPaginator
        , accumulator: [TCHMember]
        , completion: TCHMembersSuccessCompletion?) {
        
        var members: [TCHMember] = []
        paginator.items().forEach { (member) in
            
            members.append(member)
        }
        
        let accumulated = accumulator + members
        
        if paginator.hasNextPage() {
            
            paginator.requestNextPage { [weak self] (result, paginator) in
                
                guard result?.isSuccessful() ?? false else {
                    
                    completion?(false, accumulated)
                    return
                }
                
                self?.collectMembersFromPaginator(paginator!
                    , accumulator: accumulated
                    , completion: completion)
                
            }
        }
        else {
            
            completion?(true, accumulated)
        }
    }
}
