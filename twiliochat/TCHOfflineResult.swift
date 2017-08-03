//
//  TCHOfflineResult.swift
//  twiliochat
//
//  Created by Robert Norris on 03.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation




class TCHOfflineResult : TCHResult {
    
    override var error: TCHError! {
        
        return nil
    }
    
    override var resultCode: Int {
        
        return 0
    }
    
    override var resultText: String! {
        
        return nil
    }
    
    override func isSuccessful() -> Bool {
        
        return true
    }

}
