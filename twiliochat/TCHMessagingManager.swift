//
//  TCHMessagingManager.swift
//  twiliochat
//
//  Created by Robert Norris on 16.08.17.
//  Copyright © 2017 Twilio. All rights reserved.
//

import TwilioChatClient
import TwilioAccessManager



class TCHMessagingManager: NSObject {
    
    static let _sharedManager = TCHMessagingManager()
    
    weak var delegate: MessagingDelegate?
    
    fileprivate var startup: StartupHandler?
    fileprivate var client: TwilioOfflineChatClient!
    fileprivate var reachability: Reachability!
    fileprivate var isReachable: Bool!
    fileprivate var requestTokenWithCompletionActive = false
    fileprivate var chatStore: ChatStore!
    
    fileprivate(set) var channels: [StoredChannel] = []
    fileprivate(set) var activeChannels: Set<ActiveChannel> = Set()
    
    var connected = false
    
    var rootViewControllerName: String?
    
    init(fromChatStore chatStore: ChatStore = UserDefaultChatStore.shared) {
        
        super.init()
        
        #if DEBUG
            chatStore.storedUsers { storedUsers in
                
                storedUsers.forEach { storedUser in
                    
                    print("\(String(describing: type(of: self))).\(#function) - sid: \(storedUser.identity), friendlyName: \(storedUser.friendlyName ?? "nil")")
                }
            }
            
            chatStore.storedChannels { storedChannels in
                
                storedChannels.forEach { storedChannel in
                    
                    print("\(String(describing: type(of: self))).\(#function) - sid: \(storedChannel.sid), friendlyName: \(storedChannel.friendlyName ?? "nil")")
                    
                    chatStore.storedMessages(forChannel: storedChannel) { storedMessages in
                        
                        storedMessages.forEach { storedMessage in
                            
                            print("\(String(describing: type(of: self))).\(#function) - sid: \(storedMessage.sid), channel: \(storedMessage.channel), body: \(storedMessage.body ?? "nil")")
                        }
                    }
                    
                    chatStore.storedMembers(forChannel: storedChannel) { storedMembers in
                        
                        storedMembers.forEach { storedMember in
                            
                            print("\(String(describing: type(of: self))).\(#function) - identity: \(storedMember.identity), channel: \(storedMember.channel), lastConsumedMessageIndex: \(storedMember.lastConsumedMessageIndex ?? -1)")
                        }
                    }
                    
                }
            }
        #endif
        
        self.chatStore = chatStore
        
        self.reachability = Reachability()
        self.isReachable = self.reachability.isReachable
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:))
            , name: ReachabilityChangedNotification
            , object: reachability)
        
        _ = try? reachability.startNotifier()
    }
    
    @objc func reachabilityChanged(_ note: Notification) {
        
        guard let reachability = note.object as? Reachability else {
            
            assertionFailure("Notification object is not of type Reachability")
            
            return
        }
        
        guard self.isReachable != reachability.isReachable else {
            
            return
        }
        
        self.isReachable = reachability.isReachable
        
        if self.isReachable {
            
            self.requestTokenWithCompletion { succeeded, token in
                if let token = token, succeeded {
                    
                    self.initializeClientWithToken(token: token)
                } else {
                    
                    self.logout()
                }
            }
        } else {
            
            // alternative to disconnect i.e. kill online client
            //self.offlineClient.disconnect()
        }
    }
    
    deinit {
        
        self.reachability.stopNotifier()
    }
    
    // MARK: User and session management
    
    func initializeClientWithToken(token: String?) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        TwilioOfflineChatClient.chatClient(withToken: token, properties: nil, delegate: self, chatStore: UserDefaultChatStore.shared) { [weak self] result, chatClient in
            
            guard result == true else { return }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            self?.connected = true
            self?.client = chatClient
        }
    }
    
    func requestTokenWithCompletion(completion:@escaping (Bool, String?) -> Void) {
        
        guard self.reachability.isReachable else { return completion(false, nil) }
        
        if let device = UIDevice.current.identifierForVendor?.uuidString {
            
            TokenRequestHandler.fetchToken(params: ["device": device, "identity":SessionManager.getUsername()]) {response,error in
                var token: String?
                token = response["token"] as? String
                completion(token != nil, token)
            }
        }
    }
    
    func errorWithDescription(description: String, code: Int) -> NSError {
        
        let userInfo = [NSLocalizedDescriptionKey: description]
        return NSError(domain: "app", code: code, userInfo: userInfo)
    }
}



extension TCHMessagingManager: MessagingManager {
    
    static func sharedManager() -> MessagingManager {
        
        return _sharedManager
    }
    
    var user: StoredUser? {
        
        guard let client = self.client else {
            
            return nil
        }
        
        return client.user
    }
    
    func startup(completion: StartupHandler?) {
        
        print("\(String(describing: type(of: self))).\(#function) - \(Date())")
        
        self.startup = completion
        
        guard self.reachability.isReachable else {
            
            self.initializeClientWithToken(token: nil)
            return
        }
        
        requestTokenWithCompletion { succeeded, token in
            
            if let token = token, succeeded {
                
                self.initializeClientWithToken(token: token)
            }
            else {
                
                self.initializeClientWithToken(token: nil)
            }
        }
    }
    
    func shutdown() {
        
        self.client.shutdown()
    }
    
    func loginWithUsername(_ username: String,
                           completion: StartupHandler?) {
        
        SessionManager.loginWithUsername(username: username)
        self.startup(completion: completion)
    }
    
    func logout() {
        
        SessionManager.logout()
        DispatchQueue.global(qos: .userInitiated).async {
            self.client.shutdown()
        }
        self.connected = false
    }
    
    func sendMessage(_ body: String, inChannel channel: ChatChannel) {
        
        self.client.sendMessage(body, inChannel: channel)
    }
    
    func removeMessage(atIndex index: Int, fromChannel channel: ChatChannel) {
        
        self.client.removeMessage(atIndex: index, fromChannel: channel)
    }
    
    func advanceLastConsumedMessageIndex(_ index: Int, forChannel channel: ChatChannel) {
        
        self.client.advanceLastConsumedMessageIndex(index, forChannel: channel)
    }
    
    func typingInChannel(_ channel: ChatChannel) {
        
        self.client.typingInChannel(channel)
    }
    
    func activateChannel(_ channel: ChatChannel, completion: @escaping ActiveChannelHandler) {
        
        guard let chatStore = self.client.chatStore else {
            
            completion(nil)
            return
        }
        
        chatStore.storedChannels { storedChannels in
            
            let matchingChannels = storedChannels.filter { $0.sid == channel.sid }
            
            guard let storedChannel = matchingChannels.first else {
                
                completion(nil)
                return
            }
            
            let group = DispatchGroup()
            
            var users: [StoredUser] = []
            var members: [StoredMember] = []
            var messages: [StoredMessage] = []
            
            group.enter() // .storedUsers
            chatStore.storedUsers { storedUsers in
                
                users = storedUsers
                group.leave() // .storedUsers
            }
            
            group.enter() // .storedMembers
            chatStore.storedMembers(forChannel: storedChannel) { storedMembers in
                
                members = storedMembers
                group.leave() // .storedMembers
            }
            
            group.enter() // .storedMessages
            chatStore.storedMessages(forChannel: storedChannel) { storedMessages in
                
                messages = storedMessages
                group.leave() // .storedMessages
            }
            
            group.notify(queue: DispatchQueue.main) {
                
                let activeChannel = ActiveChannel(messagingManager: self
                    , storedChannel: storedChannel
                    , storedUsers: users, storedMembers: members
                    , storedMessages: messages)
                
                self.activeChannels.update(with: activeChannel)
                
                completion(activeChannel)
            }
        }
    }
    
    func deactivateChannel(_ channel: ActiveChannel) {
        
        self.activeChannels.remove(channel)
    }
    
    func addChannel(_ channel: ChatChannel) {
        
        // TODO add to twilioclient
    }
    
    func deleteChannel(_ channel: ChatChannel) {
        
        // TODO delete from twilioclient
    }
    
    func updateChannel(_ channel: ChatChannel) {
        
        // TODO update in twilioclient
    }
}



extension TCHMessagingManager: ChatClientDelegate {
    
    func chatClient(_ client: TwilioOfflineChatClient, channelAdded channel: TCHChannel) {
        
        let storableChannel = channel.storable
        
        self.delegate?.messagingManager(self, addedChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channel: TCHChannel, synchronizationStatusUpdated status: TCHChannelSynchronizationStatus) {
        
        guard status == .all else { return }
        
        let storableChannel = channel.storable
        
        self.delegate?.messagingManager(self, updatedChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channelDeleted channel: TCHChannel) {
        
        let storableChannel = channel.storable
        
        self.delegate?.messagingManager(self, deletedChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        
        // TODO: in the case of .failed, we also want to init from chatStore?
        
        if status == TCHClientSynchronizationStatus.completed {
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            print("\(String(describing: type(of: self))).\(#function) - \(Date())")
            
            let group = DispatchGroup()
            
            group.enter()
            self.chatStore.storedChannels { storedChannels in
                
                self.channels = storedChannels.sortedInAscendingOrderOfDisplayName
                group.leave()
            }
            
            group.notify(queue: DispatchQueue.main) {
                
                self.startup?(true, nil)
                self.startup = nil
            }
        }
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channel: TCHChannel, messageAdded message: TCHMessage) {
        
        let storableMessage = message.storable(forChannel: channel)
        let storableChannel = channel.storable
        
        self.delegate?.messagingManager(self, addedMessage: storableMessage, toChannel: storableChannel)
        
        guard let activeChannel = (self.activeChannels.first { $0.sid == channel.sid }) else {
            
            return
        }
        
        activeChannel.messagingManager(self, addedMessage: storableMessage, toChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channel: TCHChannel, message: TCHMessage, updated: TCHMessageUpdate) {
        
        let storableMessage = message.storable(forChannel: channel)
        let storableChannel = channel.storable
        
        self.delegate?.messagingManager(self, updatedMessage: storableMessage, inChannel: storableChannel)
        
        guard let activeChannel = (self.activeChannels.first { $0.sid == channel.sid }) else {
            
            return
        }
        
        activeChannel.messagingManager(self, updatedMessage: storableMessage, inChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channel: TCHChannel, messageDeleted message: TCHMessage) {
        
        let storableMessage = message.storable(forChannel: channel)
        let storableChannel = channel.storable
        
        self.delegate?.messagingManager(self, deletedMessage: storableMessage, fromChannel: storableChannel)
        
        guard let activeChannel = (self.activeChannels.first { $0.sid == channel.sid }) else {
            
            return
        }
        
        activeChannel.messagingManager(self, deletedMessage: storableMessage, fromChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channel: TCHChannel, memberJoined member: TCHMember) {
        
        let storableMember = member.storable(forChannel: channel)
        let storableChannel = channel.storable
        
        self.delegate?.messagingManager(self, addedMember: storableMember, toChannel: storableChannel)
        
        guard let activeChannel = (self.activeChannels.first { $0.sid == channel.sid }) else {
            
            return
        }
        
        activeChannel.messagingManager(self, addedMember: storableMember, toChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channel: TCHChannel, member: TCHMember, updated: TCHMemberUpdate) {
        
        let storableMember = member.storable(forChannel: channel)
        let storableChannel = channel.storable
        
        self.delegate?.messagingManager(self, updatedMember: storableMember, inChannel: storableChannel)
        
        guard let activeChannel = (self.activeChannels.first { $0.sid == channel.sid }) else {
            
            return
        }
        
        activeChannel.messagingManager(self, updatedMember: storableMember, inChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channel: TCHChannel, memberLeft member: TCHMember) {
        
        let storableMember = member.storable(forChannel: channel)
        let storableChannel = channel.storable
        
        self.delegate?.messagingManager(self, deletedMember: storableMember, fromChannel: storableChannel)
        
        guard let activeChannel = (self.activeChannels.first { $0.sid == channel.sid }) else {
            
            return
        }
        
        activeChannel.messagingManager(self, deletedMember: storableMember, fromChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioChatClient, typingStartedOn channel: TCHChannel, member: TCHMember) {
        
        let storableChannel = channel.storable
        let storableMember = member.storable(forChannel: channel)
        
        self.delegate?.messagingManager(self, memberStartedTyping: storableMember, inChannel: storableChannel)
        
        guard let activeChannel = (self.activeChannels.first { $0.sid == channel.sid }) else {
            
            return
        }
        
        activeChannel.messagingManager(self, memberStartedTyping: storableMember, inChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioChatClient, typingStoppedOn channel: TCHChannel, member: TCHMember) {
        
        let storableChannel = channel.storable
        let storableMember = member.storable(forChannel: channel)
        
        self.delegate?.messagingManager(self, memberStoppedTyping: storableMember, inChannel: storableChannel)
        
        guard let activeChannel = (self.activeChannels.first { $0.sid == channel.sid }) else {
            
            return
        }
        
        activeChannel.messagingManager(self, memberStoppedTyping: storableMember, inChannel: storableChannel)
    }
}



extension TCHMessagingManager: TwilioAccessManagerDelegate {
    
    public func accessManagerTokenWillExpire(_ accessManager: TwilioAccessManager) {
        
        requestTokenWithCompletion { succeeded, token in
            if succeeded {
                accessManager.updateToken(token!)
            }
            else {
                print("Error while trying to get new access token")
            }
        }
    }
    
    func accessManager(_ accessManager: TwilioAccessManager!, error: Error!) {
        
        print("Access manager error: \(error.localizedDescription)")
    }
}

