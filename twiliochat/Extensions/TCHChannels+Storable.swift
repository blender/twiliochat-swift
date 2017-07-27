//
//  TCHChannels+Storable.com
//  twiliochat
//
//  Created by Tommaso Piazza on 26.07.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import Foundation
import TwilioChatClient


extension TCHChannels {
    
    typealias StoredChannelsHandler = (([TCHStoredChannel]) -> ())
    
    func storeUserChannelDescriptors(with store: @escaping StoredChannelsHandler) {
        
        self.userChannelDescriptors { [weak self] result, paginator in
            
            guard result?.isSuccessful() ?? false else {
                
                store([])
                return
            }

            let arrayOfStorableChannels = paginator!.items().map { $0.storable }
            
            self?.collectStorableChannelsFromPaginator(paginator!, accumulator: arrayOfStorableChannels, onLastPage: store)
        }
    }
    
    func collectStorableChannelsFromPaginator(_ paginator: TCHChannelDescriptorPaginator
        , accumulator: [TCHStoredChannel]
        , onLastPage: @escaping StoredChannelsHandler) {
        
        if paginator.hasNextPage() {
            
            paginator.requestNextPage { [weak self] result, paginator in
                
                guard result?.isSuccessful() ?? false else {
                    
                    self?.collectStorableChannelsFromPaginator(paginator!, accumulator: accumulator, onLastPage: onLastPage)
                    return
                }
                
                let arr = paginator!.items().map { $0.storable }
                
                let newAcc = accumulator + arr
                
                self?.collectStorableChannelsFromPaginator(paginator!, accumulator: newAcc, onLastPage: onLastPage)
            }
        }
        else {
            
            onLastPage(accumulator)
        }
    }
    
}
