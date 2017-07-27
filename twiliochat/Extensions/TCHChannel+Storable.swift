//
//  TCHChannel+Storable.swift
//  twiliochat
//
//  Created by Tommaso Piazza on 20.07.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation


public protocol ChatChannel {
    
    var sid: String! { get }
    var friendlyName: String! { get }
    var uniqueName: String! { get }
}

public protocol ChatChannelWithDelegate: ChatChannel {
    
    weak var optionalDelegate: TCHChannelDelegate? { get }
}


extension TCHChannel: ChatChannelWithDelegate {
    
    public weak var optionalDelegate: TCHChannelDelegate? {
        
        guard let delegate = self.delegate else { return nil }
            
        return delegate
    }
 }

extension TCHChannel {
    
    var storable: TCHStoredChannel {
        
        return TCHStoredChannel(sid: self.sid
            , friendlyName: self.friendlyName
            , uniqueName: self.uniqueName)
    }
}

extension TCHChannelDescriptor {
    
    var storable: TCHStoredChannel {
        
        return TCHStoredChannel(sid: self.sid
            , friendlyName: self.friendlyName
            , uniqueName: self.uniqueName)
    }
}


struct TCHStoredChannel: ChatChannel {
    
    enum Keys: String {
        
        case sid
        case friendlyName
        case uniqueName
    }
    
    var sid: String!
    var friendlyName: String!
    var uniqueName: String!
    
    func toJSON() -> Data {
        
        var dictionary:Dictionary<String, Any> = [:]
        
        dictionary[Keys.sid.rawValue] = self.sid as String
        dictionary[Keys.friendlyName.rawValue] = self.friendlyName as String
        dictionary[Keys.uniqueName.rawValue] = self.uniqueName as String
        
        let d = try? JSONSerialization.data(withJSONObject: dictionary, options: .init(rawValue: 0))
        
        return d!
    }
    
    static func fromJSON(data: Data) -> TCHStoredChannel? {
    
        let d = (try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0))) as? Dictionary<String, Any>
        
        guard let sid = d?[Keys.sid.rawValue] as? String
            , let friendlyName = d?[Keys.friendlyName.rawValue] as? String
            , let uniqueName = d?[Keys.uniqueName.rawValue] as? String else {
                return nil
        }
        
        return TCHStoredChannel(sid: sid
            , friendlyName: friendlyName
            , uniqueName: uniqueName)
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
