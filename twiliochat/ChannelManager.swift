import UIKit

class ChannelManager: NSObject {
    static let sharedManager = ChannelManager()
    
    static let defaultChannelUniqueName = "general"
    static let defaultChannelName = "General Channel"
    
    weak var delegate:MenuViewController?
    
    var channelsList:TCHChannels?
    var channels:NSMutableOrderedSet?
    var currentChannel:TCHChannel?
    var connected = false
    
    override init() {
        super.init()
        channels = NSMutableOrderedSet()
    }
    
    // MARK: - General channel
    
    func joinFirstChannelWithCompletion(completion: @escaping (Bool) -> Void) {
        
        guard let firstChannel = self.channelsList?.subscribedChannels().first else {
            
            return completion(false)
        }
        
        guard firstChannel.status != .joined else {
            
            self.currentChannel = firstChannel
            return completion(true)
        }
        
        firstChannel.join { result in
            
            let success = result?.isSuccessful() ?? false
            self.currentChannel = success ? firstChannel : nil
            completion(success)
        }
    }
    
//    func joinGeneralChatRoomWithCompletion(completion: @escaping (Bool) -> Void) {
//        
//        guard self.connected else { return completion(false) }
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
    
//    func joinGeneralChatRoomWithUniqueName(name: String?, completion: @escaping (Bool) -> Void) {
//        
//        guard self.connected else { return completion(false) }
//        
//        generalChannel.join { result in
//            if ((result?.isSuccessful())! && name != nil) {
//                self.setGeneralChatRoomUniqueNameWithCompletion(completion: completion)
//                return
//            }
//            completion((result?.isSuccessful())!)
//        }
//    }
    
//    func createGeneralChatRoomWithCompletion(completion: @escaping (Bool) -> Void) {
//        
//        guard self.connected else { return completion(false) }
//        
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
    
//    func setGeneralChatRoomUniqueNameWithCompletion(completion:@escaping (Bool) -> Void) {
//        
//        guard self.connected else { return completion(false) }
//        
//        generalChannel.setUniqueName(ChannelManager.defaultChannelUniqueName) { result in
//            completion((result?.isSuccessful())!)
//        }
//    }
    
    // MARK: - Populate channels
    
    func populateChannels() {
        channels = NSMutableOrderedSet()
        
        if self.connected {
        
            let loadGroup = DispatchGroup()
            
            loadGroup.enter()
            channelsList?.userChannelDescriptors { result, paginator in
                
                paginator!.items().forEach { (channelDescriptor) in
                    
                    channelDescriptor.channel { result, channel in
                    
                        guard (result?.isSuccessful() ?? false) else { return }
                        
                        self.channels?.add(channel!)
                    }
                }
                
                loadGroup.leave()
            }
            
            loadGroup.enter()
            channelsList?.publicChannelDescriptors { result, paginator in

                paginator!.items().forEach { (channelDescriptor) in
                    
                    channelDescriptor.channel { result, channel in
                        
                        guard (result?.isSuccessful() ?? false) else { return }
                        
                        self.channels?.add(channel!)
                    }
                }

                loadGroup.leave()
            }
            
            loadGroup.notify(queue: DispatchQueue.main) {
                
                self.sortChannels()

                if self.delegate != nil {
                    self.delegate!.reloadChannelList()
                }
            }

        } else {
            
            // Nota bene: Robert Norris - using subscribed channels is a short cut to avoid
            // offline paginator implementation. This may be reviewed.
            
            channelsList?.subscribedChannels().forEach { (channel) in
                self.channels?.add(channel)
                self.sortChannels()
            }
            
            if self.delegate != nil {
                self.delegate!.reloadChannelList()
            }
        }
    }
    
    func sortChannels() {
        let descriptor = NSSortDescriptor(key: "friendlyName", ascending: true) { id1, id2 in
            
            let first = (id1 as? String)?.lowercased() ?? ""
            let second = (id2 as? String)?.lowercased() ?? ""
            
            return first.compare(second)
        }
        channels!.sort(using: [descriptor])
    }
    
    // MARK: - Create channel
    
    func createChannelWithName(name: String, completion: @escaping (Bool, TCHChannel?) -> Void) {
        
        guard self.connected else { return completion(false, nil) }
        
        if (name == ChannelManager.defaultChannelName) {
            completion(false, nil)
            return
        }
        
        let channelOptions:[NSObject : AnyObject] = [
            TCHChannelOptionFriendlyName as NSObject: name as AnyObject,
            TCHChannelOptionType as NSObject: TCHChannelType.public.rawValue as AnyObject
        ]
        UIApplication.shared.isNetworkActivityIndicatorVisible = true;
        self.channelsList?.createChannel(options: channelOptions) { result, channel in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false;
            completion((result?.isSuccessful())!, channel)
        }
    }
}

// MARK: - TwilioChatClientDelegate
extension ChannelManager : TwilioChatClientDelegate {
    // TODO should be called when a channel is added when the client is active
    // the ChannelManager has a reference to the channelsList of the client which needs to be updated
    func chatClient(_ client: TwilioChatClient!, channelAdded channel: TCHChannel!) {
        DispatchQueue.main.async {
            if self.channels != nil {
                self.channels!.add(channel)
                self.sortChannels()
            }
            self.delegate?.chatClient(client, channelAdded: channel)
        }
    }
    
    // TODO this is also dealt with in MenuViewController and MessagingManager
    func chatClient(_ client: TwilioChatClient!, channelChanged channel: TCHChannel!) {
        self.delegate?.chatClient(client, channelChanged: channel)
    }
    
    func chatClient(_ client: TwilioChatClient!, channelDeleted channel: TCHChannel!) {
        DispatchQueue.main.async {
            if self.channels != nil {
                self.channels?.remove(channel)
            }
            self.delegate?.chatClient(client, channelDeleted: channel)
        }
        
    }
    
    func chatClient(_ client: TwilioChatClient!, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
    }
}
