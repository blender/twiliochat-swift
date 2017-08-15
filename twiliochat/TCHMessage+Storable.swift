//
//  TCHMessage+Storable.swift
//  twiliochat
//
//  Created by Robert Norris on 02.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation



public protocol ChatMessage {
    
    var sid: String { get }
    var index: Int { get }
    var author: String? { get }
    var body: String? { get }
    var timestamp: Date { get }
    var dateUpdated: Date? { get }
    var lastUpdatedBy: String? { get }
}



extension TCHMessage {
    
    func storable(forChannel channel: TCHChannel) -> StoredMessage {
        
        return StoredMessage(sid: self.sid, index: self.index.intValue
            , author: self.author, body: self.body, timestamp: self.timestampAsDate
            , dateUpdated: self.dateUpdatedAsDate
            , lastUpdatedBy: self.lastUpdatedBy, channel: channel.sid)
    }
}



struct StoredMessage: ChatMessage {
    
    enum Keys: String {
        
        case sid
        case index
        case author
        case body
        case timestamp
        case dateUpdated
        case lastUpdatedBy
        case channel
    }
    
    var sid: String
    var index: Int
    var channel: String
    var author: String?
    var body: String?
    var timestamp: Date
    var dateUpdated: Date?
    var lastUpdatedBy: String?
    
    init(sid: String, index: Int, author: String?, body: String?, timestamp: Date, dateUpdated: Date?, lastUpdatedBy: String?, channel: String) {
        
        self.sid = sid
        self.index = index
        self.author = author
        self.body = body
        self.timestamp = timestamp
        self.dateUpdated = dateUpdated
        self.lastUpdatedBy = lastUpdatedBy
        self.channel = channel
    }
    
    init(message: ChatMessage, inChannel channel: ChatChannel) {
        
        self.init(sid: message.sid, index: message.index, author: message.author, body: message.body, timestamp: message.timestamp
            , dateUpdated: message.dateUpdated, lastUpdatedBy: message.lastUpdatedBy, channel: channel.sid)
    }
    
    func toJSON() -> Data {
        
        var dictionary:Dictionary<String, Any> = [:]
        
        dictionary[Keys.sid.rawValue] = self.sid
        dictionary[Keys.index.rawValue] = self.index
        dictionary[Keys.channel.rawValue] = self.channel
        dictionary[Keys.timestamp.rawValue] = self.timestamp.timeIntervalSince1970
        
        self.author.flatMap { dictionary[Keys.author.rawValue] = $0 }
        self.body.flatMap { dictionary[Keys.body.rawValue] = $0 }
        self.dateUpdated.flatMap { dictionary[Keys.dateUpdated.rawValue] = $0.timeIntervalSince1970 }
        self.lastUpdatedBy.flatMap { dictionary[Keys.lastUpdatedBy.rawValue] = $0 }
        
        let d = try? JSONSerialization.data(withJSONObject: dictionary, options: .init(rawValue: 0))
        
        return d!
    }
    
    static func fromJSON(data: Data) -> StoredMessage? {
        
        let d = (try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0))) as? Dictionary<String, Any>
        
        let _timestamp = (d?[Keys.timestamp.rawValue] as? TimeInterval).flatMap { Date(timeIntervalSince1970: $0) }
        
        guard let sid = d?[Keys.sid.rawValue] as? String
            , let index = d?[Keys.index.rawValue] as? Int
            , let channel = d?[Keys.channel.rawValue] as? String
            , let timestamp = _timestamp else {
                
            return nil
        }
        
        let author = d?[Keys.author.rawValue] as? String
        let body = d?[Keys.body.rawValue] as? String
        let dateUpdated = (d?[Keys.dateUpdated.rawValue] as? TimeInterval).flatMap { Date(timeIntervalSince1970: $0) }
        let lastUpdatedBy = d?[Keys.lastUpdatedBy.rawValue] as? String
        
        return StoredMessage(sid: sid, index: index
            , author: author, body: body, timestamp: timestamp
            , dateUpdated: dateUpdated
            , lastUpdatedBy: lastUpdatedBy, channel: channel)
    }
}



extension StoredMessage: Equatable {
    
    public static func ==(lhs: StoredMessage, rhs: StoredMessage) -> Bool {
        
        return lhs.sid == rhs.sid && lhs.channel == rhs.channel
    }
}



extension StoredMessage: Hashable {
    
    public var hashValue: Int {
        
        return [self.sid, self.channel].joined(separator: ".").hash
    }
}
