//
//  TCHMember+Storable.swift
//  twiliochat
//
//  Created by Robert Norris on 14.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

//import TwiliChatClient



public protocol ChatMember {

    var identity: String { get }
    var lastConsumedMessageIndex: Int? { get }
}



extension TCHMember {
    
    func storable(forChannel channel: TCHChannel) -> StoredMember {
    
        return StoredMember(identity: self.identity, lastConsumedMessageIndex: self.lastConsumedMessageIndex?.intValue, channel: channel.sid)
    }
}



struct StoredMember: ChatMember {
    
    enum Keys: String {
        
        case identity
        case lastConsumedMessageIndex
        case channel
    }
    
    var identity: String
    var channel: String
    var lastConsumedMessageIndex: Int?
    
    init(identity: String, lastConsumedMessageIndex: Int?, channel: String) {
        
        self.identity = identity
        self.lastConsumedMessageIndex = lastConsumedMessageIndex
        self.channel = channel
    }
    
    init(member: ChatMember, inChannel channel: ChatChannel) {
    
        self.init(identity: member.identity, lastConsumedMessageIndex: member.lastConsumedMessageIndex, channel: channel.sid)
    }
    
    func toJSON() -> Data {
        
        var dictionary:Dictionary<String, Any> = [:]
        
        dictionary[Keys.identity.rawValue] = self.identity
        dictionary[Keys.channel.rawValue] = self.channel
        
        self.lastConsumedMessageIndex.flatMap { dictionary[Keys.lastConsumedMessageIndex.rawValue] = $0 }
        
        let d = try? JSONSerialization.data(withJSONObject: dictionary, options: .init(rawValue: 0))
        
        return d!
    }
    
    static func fromJSON(data: Data) -> StoredMember? {
        
        let d = (try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0))) as? Dictionary<String, Any>
        
        guard let identity = d?[Keys.identity.rawValue] as? String
            , let channel = d?[Keys.channel.rawValue] as? String else {
            
            return nil
        }
        
        let lastConsumedMessageIndex = d?[Keys.lastConsumedMessageIndex.rawValue] as? Int
        
        return StoredMember(identity: identity
            , lastConsumedMessageIndex: lastConsumedMessageIndex
            , channel: channel)
    }
}

extension StoredMember: Equatable {
    
    public static func ==(lhs: StoredMember, rhs: StoredMember) -> Bool {
        
        return lhs.identity == rhs.identity && lhs.channel == rhs.channel
    }
}

extension StoredMember: Hashable {
    
    public var hashValue: Int {
        
        return [self.identity, self.channel].joined(separator: ".").hash
    }
}
