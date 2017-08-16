import UIKit



protocol ChannelDelegate {
    
    func channelManager(_: ChannelManager, addedChannel: StoredChannel)
    func channelManager(_: ChannelManager, deletedChannel: StoredChannel)
    func channelManager(_: ChannelManager, updatedChannel: StoredChannel)
}



extension ChannelDelegate {

    func channelManager(_: ChannelManager, addedChannel: StoredChannel) { }
    func channelManager(_: ChannelManager, deletedChannel: StoredChannel) { }
    func channelManager(_: ChannelManager, updatedChannel: StoredChannel) { }
}



typealias ActiveChannelHandler = ((ActiveChannel?) -> ())



protocol ChannelManager {
 
    var delegate: ChannelDelegate? { get set }
    
    var channels: [StoredChannel] { get }
    
    func addChannel(_: StoredChannel)
    func deleteChannel(_: StoredChannel)
    func updateChannel(_: StoredChannel)
    
    func sendMessage(_: String, inChannel: ChatChannel)
    func removeMessage(atIndex: Int, fromChannel: ChatChannel)
    func advanceLastConsumedMessageIndex(_ index: Int, forChannel: ChatChannel)
    
    func activateChannel(_: ChatChannel, completion: @escaping ActiveChannelHandler)
}



class SharecareChannelManager: ChannelManager {

    private var messagingManager: MessagingManager
    var delegate: ChannelDelegate?
    
    private var channelsCollection = Set<StoredChannel>()
    private(set) var channels: [StoredChannel] = []
    
    init(messagingManager: MessagingManager) {
        
        self.messagingManager = messagingManager
    }
        
    private func sortChannels() {

        self.channels = self.channelsCollection.sorted { (storedChannel1, storedChannel2) -> Bool in
         
            let name1 = storedChannel1.friendlyName?.lowercased() ?? ""
            let name2 = storedChannel2.friendlyName?.lowercased() ?? ""
            
            return name1.compare(name2) == .orderedAscending
        }
    }
    
    func addChannel(_ channel: StoredChannel) {

        self.channelsCollection.insert(channel)
        self.sortChannels()
        
        DispatchQueue.main.async {
        
            self.delegate?.channelManager(self, addedChannel: channel)
        }
    }
    
    func deleteChannel(_ channel: StoredChannel) {

        self.channelsCollection.remove(channel)
        self.sortChannels()
        
        DispatchQueue.main.async {
            
            self.delegate?.channelManager(self, deletedChannel: channel)
        }
    }
    
    func updateChannel(_ channel: StoredChannel) {

        self.channelsCollection.remove(channel)
        self.channelsCollection.insert(channel)
        self.sortChannels()
        
        DispatchQueue.main.async {
            
            self.delegate?.channelManager(self, updatedChannel: channel)
        }
    }
    
    func sendMessage(_ body: String, inChannel channel: ChatChannel) {
        
        self.messagingManager.sendMessage(body, inChannel: channel)
    }
    
    func removeMessage(atIndex index: Int, fromChannel channel: ChatChannel) {

        self.messagingManager.removeMessage(atIndex: index, fromChannel: channel)
    }
    
    func advanceLastConsumedMessageIndex(_ index: Int, forChannel channel: ChatChannel) {
        
        self.messagingManager.advanceLastConsumedMessageIndex(index, forChannel: channel)
    }
    
    func activateChannel(_ channel: ChatChannel, completion: @escaping ActiveChannelHandler) {
        
        self.messagingManager.activateChannel(channel, completion: completion)
    }
}
