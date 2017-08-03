//
//  TCHOfflineMessage.swift
//  twiliochat
//
//  Created by Robert Norris on 02.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation
import TwilioChatClient

class TCHOfflineMessage : TCHMessage {
    
    private var storedMessage: TCHStoredMessage!
    
    init(_ storedMessage: TCHStoredMessage) {
        
        super.init()
        
        self.storedMessage = storedMessage
    }
        
    override var sid: String! {
        
        return self.storedMessage.sid
    }
    
    override var index: NSNumber! {
        
        return self.storedMessage.index
    }
    
    override var author: String! {
        
        return self.storedMessage.author
    }
    
    override var body: String! {
        
        return self.storedMessage.body
    }
    
    override var timestamp: String! {
        
        return self.storedMessage.timestamp
    }
    
    override var timestampAsDate: Date! {
        
        return Date()
        //return self.storedMessage.timestampAsDate
    }
    
    override var dateUpdated: String! {
        
        return self.storedMessage.dateUpdated
    }
    
    override var dateUpdatedAsDate: Date! {
        
        return Date()
        //return self.storedMessage.dateUpdatedAsDate
    }
    
    override var lastUpdatedBy: String! {
        
        return self.storedMessage.lastUpdatedBy
    }
    
    override func updateBody(_ body: String!, completion: TCHCompletion!) {
        
        completion(nil)
    }
    
    override func attributes() -> [String : Any]! {
        
        return nil
    }
    
    override func setAttributes(_ attributes: [String : Any]!, completion: TCHCompletion!) {
        
        completion(nil)
    }
}
