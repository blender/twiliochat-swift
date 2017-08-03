//
//  TCHOfflineUsers.swift
//  twiliochat
//
//  Created by Robert Norris on 01.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation
import TwilioChatClient



class TCHOfflineUsers: TCHUsers {
    
    private var connected: Bool = false
    private var offlineUsers: [TCHUser] = []
    
    func load(fromStore store: ChatStore, completion: (() -> ())? = nil) {
        
        // TODO - support offline users?
        completion?()
    }
    
    func connect(toUsers users: TCHUsers) {
        
        self.connected = true
    }
    
    func disconnect(updatingStore store: ChatStore? = nil) {
        
        self.connected = false
    }
    
    override func subscribedUsers() -> [TCHUser]! {
        
        guard self.connected else {
            
            return offlineUsers
        }
        
        return super.subscribedUsers()
    }
    
    override func userDescriptors(for channel: TCHChannel!, completion: TCHUserDescriptorPaginatorCompletion!) {
        
        guard self.connected else {
            
            return completion(nil, nil)
        }
        
        return super.userDescriptors(for: channel, completion: completion)
    }
    
    override func userDescriptor(withIdentity identity: String!, completion: TCHUserDescriptorCompletion!) {
        
        guard self.connected else {
            
            return completion(nil, nil)
        }
        
        return super.userDescriptor(withIdentity: identity, completion: completion)
    }
    
    
    override func subscribedUser(withIdentity identity: String!, completion: TCHUserCompletion!) {
        
        guard self.connected else {
            
            return completion(nil, nil)
        }
        
        return super.subscribedUser(withIdentity: identity, completion: completion)
    }
}
