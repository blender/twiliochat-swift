//
//  TCHChannel+Storable.swift
//  twiliochat
//
//  Created by Tommaso Piazza on 20.07.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation


//public protocol ChatChannel {
//    
//    var sid: String! { get }
//    var friendlyName: String! { get }
//    var uniqueName: String! { get }
//}

//public protocol ChatChannelWithDelegate: ChatChannel {
//    
//    weak var optionalDelegate: TCHChannelDelegate? { get }
//}


//extension TCHChannel: ChatChannelWithDelegate {
//    
//    public weak var optionalDelegate: TCHChannelDelegate? {
//        
//        guard let delegate = self.delegate else { return nil }
//        
//        return delegate
//    }
//}

extension TCHChannel {
    
    var storable: TCHStoredChannel {
        
        return TCHStoredChannel(channel: self)
    }
}

//extension TCHChannelDescriptor {
//    
//    var storable: TCHStoredChannel {
//        
//        return TCHStoredChannel(sid: self.sid
//            , friendlyName: self.friendlyName
//            , uniqueName: self.uniqueName)
//    }
//}


struct TCHStoredChannel/*: ChatChannel*/ {
    
    enum Keys: String {
        
        case sid
        case friendlyName
        case uniqueName
        case status
    }
    
    var sid: String!
    var friendlyName: String?
    var uniqueName: String?
    var status: TCHChannelStatus?

    init(sid: String!, friendlyName: String?, uniqueName: String?, status: TCHChannelStatus?) {
        
        self.sid = sid
        self.friendlyName = friendlyName
        self.uniqueName = uniqueName
        self.status = status
    }
    
    init(channel: TCHChannel) {
    
        self.init(sid: channel.sid, friendlyName: channel.friendlyName, uniqueName: channel.uniqueName, status: channel.status)
    }
    
    func toJSON() -> Data {
        
        var dictionary:Dictionary<String, Any> = [:]
        
        dictionary[Keys.sid.rawValue] = self.sid as String
        
        self.friendlyName.flatMap { dictionary[Keys.friendlyName.rawValue] = $0 }
        self.uniqueName.flatMap { dictionary[Keys.uniqueName.rawValue] = $0 }
        self.status.flatMap { dictionary[Keys.status.rawValue] = $0.rawValue }
        
        let d = try? JSONSerialization.data(withJSONObject: dictionary, options: .init(rawValue: 0))
        
        return d!
    }
    
    static func fromJSON(data: Data) -> TCHStoredChannel? {
        
        let d = (try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0))) as? Dictionary<String, Any>
        
        guard let sid = d?[Keys.sid.rawValue] as? String else {
            
            return nil
        }
        
        let friendlyName = d?[Keys.friendlyName.rawValue] as? String
        let uniqueName = d?[Keys.uniqueName.rawValue] as? String
        let status = TCHChannelStatus(rawValue: (d?[Keys.status.rawValue] as? Int) ?? -1)
        
        return TCHStoredChannel(sid: sid
            , friendlyName: friendlyName
            , uniqueName: uniqueName
            , status: status)
    }
}

extension TCHStoredChannel: Equatable {
    
    public static func ==(lhs: TCHStoredChannel, rhs: TCHStoredChannel) -> Bool {
        
        return lhs.sid == rhs.sid
    }
}

extension TCHStoredChannel: Hashable {
    
    public var hashValue: Int {
        
        return self.sid.hash
    }
}
