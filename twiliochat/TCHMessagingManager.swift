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
    
    lazy var channelManager: ChannelManager = {
        
        let manager = OfflineChannelManager(messagingManager: self)
        
        self.chatStore.storedChannels{ storedChannels in
            
            storedChannels.forEach { storedChannel in
                
                manager.addChannel(storedChannel)
            }
        }
        
        return manager
    }()
    
    var delegate: MessagingDelegate?
    
    fileprivate var startup: StartupHandler?
    fileprivate var client: TwilioOfflineChatClient!
    fileprivate var reachability: Reachability!
    fileprivate var isReachable: Bool!
    fileprivate var requestTokenWithCompletionActive = false
    fileprivate var chatStore: ChatStore!
    
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
        
        let userInfo = [NSLocalizedDescriptionKey : description]
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
                
                let activeChannel = ActiveChannel(storedChannel
                    , storedUsers: users, storedMembers: members
                    , storedMessages: messages)
                
                activeChannel.manager = self.channelManager
                completion(activeChannel)
            }
        }
    }
}



extension TCHMessagingManager : ChatClientDelegate {
    
    func chatClient(_ client: TwilioOfflineChatClient, channelAdded channel: TCHChannel) {
        
        let storableChannel = channel.storable
        
        self.channelManager.addChannel(storableChannel)
        self.delegate?.channelManager(self.channelManager, addedChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channel: TCHChannel, synchronizationStatusUpdated status: TCHChannelSynchronizationStatus) {
        
        guard status == .all else { return }
        
        let storableChannel = channel.storable
        
        self.channelManager.updateChannel(storableChannel)
        self.delegate?.channelManager(self.channelManager, updatedChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channelDeleted channel: TCHChannel) {
        
        let storableChannel = channel.storable
        
        self.channelManager.deleteChannel(storableChannel)
        self.delegate?.channelManager(self.channelManager, deletedChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        
        if status == TCHClientSynchronizationStatus.completed {
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            print("\(String(describing: type(of: self))).\(#function) - \(Date())")
            
            self.startup?(true, nil)
            self.startup = nil
        }
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channel: TCHChannel, messageAdded message: TCHMessage) {
        
        let storableMessage = message.storable(forChannel: channel)
        let storableChannel = channel.storable
        
        self.delegate?.messagingManager(self, addedMessage: storableMessage, toChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channel: TCHChannel, message: TCHMessage, updated: TCHMessageUpdate) {
        
        let storableMessage = message.storable(forChannel: channel)
        let storableChannel = channel.storable
        
        self.delegate?.messagingManager(self, updatedMessage: storableMessage, inChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioOfflineChatClient, channel: TCHChannel, messageDeleted message: TCHMessage) {
        
        let storableMessage = message.storable(forChannel: channel)
        let storableChannel = channel.storable
        
        self.delegate?.messagingManager(self, deletedMessage: storableMessage, fromChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioChatClient, typingStartedOn channel: TCHChannel, member: TCHMember) {
        
        let storableChannel = channel.storable
        let storableMember = member.storable(forChannel: channel)
        
        self.channelManager.member(storableMember, startedTypingInChannel: storableChannel)
        self.delegate?.channelManager(self.channelManager, memberStartedTyping: storableMember, inChannel: storableChannel)
    }
    
    func chatClient(_ client: TwilioChatClient, typingStoppedOn channel: TCHChannel, member: TCHMember) {
        
        let storableChannel = channel.storable
        let storableMember = member.storable(forChannel: channel)
        
        self.channelManager.member(storableMember, startedTypingInChannel: storableChannel)
        self.delegate?.channelManager(self.channelManager, memberStoppedTyping: storableMember, inChannel: storableChannel)
    }
}



extension TCHMessagingManager : TwilioAccessManagerDelegate {
    
    public func accessManagerTokenWillExpire(_ accessManager: TwilioAccessManager) {
        
        requestTokenWithCompletion { succeeded, token in
            if (succeeded) {
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

