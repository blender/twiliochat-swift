import UIKit

class ChannelManager: NSObject {
    static let sharedManager = ChannelManager()
    
    static let defaultChannelUniqueName = "general"
    static let defaultChannelName = "General Channel"
    
    static let defaults = UserDefaults.standard
    
    weak var delegate: MenuViewController?
    
//    var channelsList: TCHChannels?
    var channels: NSMutableOrderedSet?
    var generalChannel: TCHChannel!
    
    override init() {
        super.init()
        channels = NSMutableOrderedSet()
    }
    
    // MARK: - General channel
    
//    func joinGeneralChatRoomWithCompletion(completion: @escaping (Bool) -> Void) {
//        
//        let uniqueName = ChannelManager.defaultChannelUniqueName
//        if let channelsList = self.channelsList {
//            channelsList.channel(withSidOrUniqueName: uniqueName) { result, channel in
//                self.generalChannel = channel
//                
//                if self.generalChannel != nil {
//                    self.joinGeneralChatRoomWithUniqueName(name: nil, completion: completion)
//                } else {
//                    self.createGeneralChatRoomWithCompletion { succeeded in
//                        if (succeeded) {
//                            self.joinGeneralChatRoomWithUniqueName(name: uniqueName, completion: completion)
//                            return
//                        }
//                        
//                        completion(false)
//                    }
//                }
//            }
//        }
//    }
    
    func joinGeneralChatRoomWithUniqueName(name: String?, completion: @escaping (Bool) -> Void) {
        generalChannel.join { result in
            if ((result?.isSuccessful())! && name != nil) {
                self.setGeneralChatRoomUniqueNameWithCompletion(completion: completion)
                return
            }
            completion((result?.isSuccessful())!)
        }
    }
    
//    func createGeneralChatRoomWithCompletion(completion: @escaping (Bool) -> Void) {
//        let channelName = ChannelManager.defaultChannelName
//        let options:[NSObject : AnyObject] = [
//            TCHChannelOptionFriendlyName as NSObject: channelName as AnyObject,
//            TCHChannelOptionType as NSObject: TCHChannelType.public.rawValue as AnyObject
//        ]
//        channelsList!.createChannel(options: options) { result, channel in
//            if (result?.isSuccessful())! {
//                self.generalChannel = channel
//            }
//            completion((result?.isSuccessful())!)
//        }
//    }
    
    func setGeneralChatRoomUniqueNameWithCompletion(completion:@escaping (Bool) -> Void) {
        generalChannel.setUniqueName(ChannelManager.defaultChannelUniqueName) { result in
            completion((result?.isSuccessful())!)
        }
    }
    
    // MARK: - Populate channels
    
    func populateChannels() {
        
        UserDefaultChatStore.shared.storedChannels { storedChannels in
            
            channels = NSMutableOrderedSet(set: Set<TCHStoredChannel>(storedChannels))
        }
        
        self.sortChannels()
        
        if self.delegate != nil {
            self.delegate!.reloadChannelList()
        }
    }
    
    func sortChannels() {
        
        channels?.sort(comparator: { (c1, c2) -> ComparisonResult in
            
            guard let sc1 = c1 as? TCHStoredChannel, let sc2 = c2 as? TCHStoredChannel else {
                
                fatalError()
            }
            
            return sc1.friendlyName.compare(sc2.friendlyName)
        })
    }
    
    // MARK: - Create channel
    
    func createChannelWithName(name: String, completion: @escaping (Bool, TCHChannel?) -> Void) {
//        if (name == ChannelManager.defaultChannelName) {
//            completion(false, nil)
//            return
//        }
//        
//        let channelOptions:[NSObject : AnyObject] = [
//            TCHChannelOptionFriendlyName as NSObject: name as AnyObject,
//            TCHChannelOptionType as NSObject: TCHChannelType.public.rawValue as AnyObject
//        ]
//        UIApplication.shared.isNetworkActivityIndicatorVisible = true;
//        self.channelsList?.createChannel(options: channelOptions) { result, channel in
//            UIApplication.shared.isNetworkActivityIndicatorVisible = false;
//            completion((result?.isSuccessful())!, channel)
//        }
    }
    
//    func storeChannels() {
//        
//        channelsList?.userChannelDescriptors { result, paginator in
//            
//            let d = paginator!.items().map { $0.storable.toJSON() }
//            var p = ChannelManager.getStoredChannels().map { $0.toJSON() }
//            p.append(contentsOf: d)
//            let s = Set(p)
//            
//            ChannelManager.setStoredChannels(data: Array(s), key: "privateChannels")
//        }
//    }
    
}

// MARK: - SharecareChatClientDelegate
extension ChannelManager : BetterChatClientDelegate {
    
    func chatClient(_ client: BetterChatClient, channelAdded channel: TCHChannel) {
        
        DispatchQueue.main.async {
            if self.channels != nil {
                self.channels!.add(channel)
                self.sortChannels()
            }
            self.delegate?.chatClient(client, channelAdded: channel)
        }
    }
    
    func chatClient(_ client: BetterChatClient, channelChanged channel: TCHChannel) {
        self.delegate?.chatClient(client, channelChanged: channel)
    }
    
    func chatClient(_ client: BetterChatClient, channelDeleted channel: TCHChannel) {
        DispatchQueue.main.async {
            if self.channels != nil {
                self.channels?.remove(channel)
            }
            self.delegate?.chatClient(client, channelDeleted: channel)
        }
        
    }
    
    func chatClient(_ client: BetterChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        
    }
}



