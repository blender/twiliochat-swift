//
//  TCHMessage+Storable.swift
//  twiliochat
//
//  Created by Robert Norris on 02.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation



extension TCHMessage {
    
    func storable(forChannel channel: TCHChannel) -> TCHStoredMessage {
        
        return TCHStoredMessage(sid: self.sid, index: self.index, author: self.author, body: self.body, timestamp: self.timestamp
//            , timestampAsDate: self.timestampAsDate
            , dateUpdated: self.dateUpdated
//            , dateUpdatedAsDate: self.dateUpdatedAsDate
            , lastUpdatedBy: self.lastUpdatedBy, channel: channel.sid)
    }
}



struct TCHStoredMessage {
    
    enum Keys: String {
        
        case sid
        case index
        case author
        case body
        case timestamp
        case timestampAsDate
        case dateUpdated
        case dateUpdatedAsDate
        case lastUpdatedBy
        case channel
    }
    
    var sid: String!
    var channel: String!
    var index: NSNumber?
    var author: String?
    var body: String?
    var timestamp: String?
//    var timestampAsDate: Date!
    var dateUpdated: String?
//    var dateUpdatedAsDate: Date!
    var lastUpdatedBy: String?
    
    init(sid: String!, index: NSNumber?, author: String?, body: String?, timestamp: String?, dateUpdated: String?, lastUpdatedBy: String?, channel: String!) {
        
        self.sid = sid
        self.index = index
        self.body = body
        self.timestamp = timestamp
        self.dateUpdated = dateUpdated
        self.lastUpdatedBy = lastUpdatedBy
        self.channel = channel
    }
    
    init(message: TCHMessage, inChannel channel: TCHChannel) {
        
        self.init(sid: message.sid, index: message.index, author: message.author, body: message.body, timestamp: message.timestamp
            , dateUpdated: message.dateUpdated, lastUpdatedBy: message.lastUpdatedBy, channel: channel.sid)
    }
    
    func toJSON() -> Data {
        
        var dictionary:Dictionary<String, Any> = [:]
        
        dictionary[Keys.sid.rawValue] = self.sid as String
        dictionary[Keys.channel.rawValue] = self.channel as String
        
        self.index.flatMap { dictionary[Keys.index.rawValue] = $0 }
        self.author.flatMap { dictionary[Keys.author.rawValue] = $0 }
        self.body.flatMap { dictionary[Keys.body.rawValue] = $0 }
        self.timestamp.flatMap { dictionary[Keys.timestamp.rawValue] = $0 }
        self.dateUpdated.flatMap { dictionary[Keys.dateUpdated.rawValue] = $0 }
        self.lastUpdatedBy.flatMap { dictionary[Keys.lastUpdatedBy.rawValue] = $0 }
        
        let d = try? JSONSerialization.data(withJSONObject: dictionary, options: .init(rawValue: 0))
        
        return d!
    }
    
    static func fromJSON(data: Data) -> TCHStoredMessage? {
        
        let d = (try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0))) as? Dictionary<String, Any>
        
        guard let sid = d?[Keys.sid.rawValue] as? String
            , let channel = d?[Keys.channel.rawValue] as? String else {
                
            return nil
        }
        
        let index = d?[Keys.index.rawValue] as? NSNumber
        let author = d?[Keys.author.rawValue] as? String
        let body = d?[Keys.body.rawValue] as? String
        let timestamp = d?[Keys.timestamp.rawValue] as? String
            //, let timestampAsDate = d?[Keys.timestampAsDate.rawValue] as? Date
        let dateUpdated = d?[Keys.dateUpdated.rawValue] as? String
            //, let dateUpdatedAsDate = d?[Keys.dateUpdatedAsDate.rawValue] as? Date
        let lastUpdatedBy = d?[Keys.lastUpdatedBy.rawValue] as? String
        
        return TCHStoredMessage(sid: sid, index: index, author: author, body: body, timestamp: timestamp
//            , timestampAsDate: timestampAsDate
            , dateUpdated: dateUpdated
//            , dateUpdatedAsDate: dateUpdatedAsDate
            , lastUpdatedBy: lastUpdatedBy, channel: channel)
    }
}

extension TCHStoredMessage: Equatable {
    
    public static func ==(lhs: TCHStoredMessage, rhs: TCHStoredMessage) -> Bool {
        
        return lhs.sid == rhs.sid && lhs.channel == rhs.channel
    }
}

extension TCHStoredMessage: Hashable {
    
    public var hashValue: Int {
        
        return self.sid.hash ^ self.channel.hash
    }
}
