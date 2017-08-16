//
//  TCHStorables.swift
//  twiliochat
//
//  Created by Robert Norris on 16.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import TwilioChatClient



extension TCHChannel {
    
    var storable: StoredChannel {
        
        // TODO: imageURL from attributes
        
        return StoredChannel(sid: self.sid, friendlyName: self.friendlyName, imageUrl: nil, createdBy: self.createdBy)
    }
    
    func store(storeMembers members: MembersHandler?, storeUsers users: UsersHandler?, completion: SuccessHandler?) {
        
        self.members.store(inChannel: self, storeMembers: members, storeUsers: users, completion: completion)
    }
}



extension TCHMember {
    
    func storable(forChannel channel: TCHChannel) -> StoredMember {
        
        return StoredMember(identity: self.identity, lastConsumedMessageIndex: self.lastConsumedMessageIndex?.intValue, channel: channel.sid)
    }
}



extension TCHMessage {
    
    func storable(forChannel channel: TCHChannel) -> StoredMessage {
        
        return StoredMessage(sid: self.sid, index: self.index.intValue
            , author: self.author, body: self.body, timestamp: self.timestampAsDate
            , dateUpdated: self.dateUpdatedAsDate
            , lastUpdatedBy: self.lastUpdatedBy, channel: channel.sid)
    }
}



extension TCHUser {
    
    var storable: StoredUser {
        
        // TODO: imageURL from attributes
        
        return StoredUser(identity: self.identity, friendlyName: self.friendlyName, imageUrl: nil)
    }
}
