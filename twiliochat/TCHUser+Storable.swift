//
//  TCHMember+Storable.swift
//  twiliochat
//
//  Created by Robert Norris on 14.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import TwilioChatClient



public protocol ChatUser {

    var identity: String { get }
    var friendlyName: String? { get }
    var imageUrl: String? { get }
}



extension TCHUser {
    
    var storable: StoredUser {
        
        // TODO: imageURL from attributes
        
        return StoredUser(identity: self.identity, friendlyName: self.friendlyName, imageUrl: nil)
    }
}



struct StoredUser: ChatUser {
    
    enum Keys: String {
        
        case identity
        case friendlyName
        case imageUrl
    }
    
    var identity: String
    var friendlyName: String?
    var imageUrl: String?
    
    init(identity: String, friendlyName: String?, imageUrl: String?) {
        
        self.identity = identity
        self.friendlyName = friendlyName
        self.imageUrl = imageUrl
    }
    
    init(user: ChatUser) {
    
        self.init(identity: user.identity, friendlyName: user.friendlyName
            , imageUrl: user.imageUrl)
    }
    
    func toJSON() -> Data {
        
        var dictionary:Dictionary<String, Any> = [:]
        
        dictionary[Keys.identity.rawValue] = self.identity
        
        self.friendlyName.flatMap { dictionary[Keys.friendlyName.rawValue] = $0 }
        self.imageUrl.flatMap { dictionary[Keys.imageUrl.rawValue] = $0 }
        
        let d = try? JSONSerialization.data(withJSONObject: dictionary, options: .init(rawValue: 0))
        
        return d!
    }
    
    static func fromJSON(data: Data) -> StoredUser? {
        
        let d = (try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0))) as? Dictionary<String, Any>
        
        guard let identity = d?[Keys.identity.rawValue] as? String else {
            
            return nil
        }
        
        let friendlyName = d?[Keys.friendlyName.rawValue] as? String
        let imageUrl = d?[Keys.imageUrl.rawValue] as? String
        
        return StoredUser(identity: identity
            , friendlyName: friendlyName
            , imageUrl: imageUrl)
    }
    
    var displayName: String? {
        
        return self.friendlyName ?? self.identity
    }
}

extension StoredUser: Equatable {
    
    public static func ==(lhs: StoredUser, rhs: StoredUser) -> Bool {
        
        return lhs.identity == rhs.identity
    }
}

extension StoredUser: Hashable {
    
    public var hashValue: Int {
        
        return self.identity.hash
    }
}
