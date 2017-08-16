//
//  TCHChannel+Storable.swift
//  twiliochat
//
//  Created by Tommaso Piazza on 20.07.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

//import TwiliChatClient



public protocol ChatChannel {
    
    var sid: String { get }
    var friendlyName: String? { get }
    var imageUrl: String? { get }
    var createdBy: String? { get }
}



extension TCHChannel {
    
    var storable: StoredChannel {
        
        // TODO: imageURL from attributes
        
        return StoredChannel(sid: self.sid, friendlyName: self.friendlyName, imageUrl: nil, createdBy: self.createdBy)
    }
    
    func store(storeMembers members: MembersHandler?, storeUsers users: UsersHandler?, completion: SuccessHandler?) {
        
        self.members.store(inChannel: self, storeMembers: members, storeUsers: users, completion: completion)
    }
}



struct StoredChannel: ChatChannel {
    
    enum Keys: String {
        
        case sid
        case friendlyName
        case imageUrl
        case createdBy
    }
    
    var sid: String
    var friendlyName: String?
    var imageUrl: String?
    var createdBy: String?
    
    var channelManager: ChannelManager?
    
    init(sid: String, friendlyName: String?, imageUrl: String?, createdBy: String?) {
        
        self.sid = sid
        self.friendlyName = friendlyName
        self.imageUrl = imageUrl
        self.createdBy = createdBy
    }
    
    init(channel: ChatChannel) {
    
        self.init(sid: channel.sid, friendlyName: channel.friendlyName, imageUrl: channel.imageUrl, createdBy: channel.createdBy)
    }
    
    func toJSON() -> Data {
        
        var dictionary:Dictionary<String, Any> = [:]
        
        dictionary[Keys.sid.rawValue] = self.sid
        
        self.friendlyName.flatMap { dictionary[Keys.friendlyName.rawValue] = $0 }
        self.imageUrl.flatMap { dictionary[Keys.imageUrl.rawValue] = $0 }
        self.createdBy.flatMap { dictionary[Keys.createdBy.rawValue] = $0 }
        
        let d = try? JSONSerialization.data(withJSONObject: dictionary, options: .init(rawValue: 0))
        
        return d!
    }
    
    static func fromJSON(data: Data) -> StoredChannel? {
        
        let d = (try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0))) as? Dictionary<String, Any>
        
        guard let sid = d?[Keys.sid.rawValue] as? String else {
            
            return nil
        }
        
        let friendlyName = d?[Keys.friendlyName.rawValue] as? String
        let imageUrl = d?[Keys.imageUrl.rawValue] as? String
        let createdBy = d?[Keys.createdBy.rawValue] as? String
        
        return StoredChannel(sid: sid
            , friendlyName: friendlyName
            , imageUrl: imageUrl
            , createdBy: createdBy)
    }
    
    var displayName: String? {
        
        return self.friendlyName ?? self.sid
    }
}

extension StoredChannel: Equatable {
    
    public static func ==(lhs: StoredChannel, rhs: StoredChannel) -> Bool {
        
        return lhs.sid == rhs.sid
    }
}

extension StoredChannel: Hashable {
    
    public var hashValue: Int {
        
        return self.sid.hash
    }
}
