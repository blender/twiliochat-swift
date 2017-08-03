import UIKit

class MessagingManager: NSObject {
    
    static let _sharedManager = MessagingManager()
    
    fileprivate var client: TwilioChatClient?
    fileprivate var reachability: Reachability!
    fileprivate var isReachable: Bool!
    fileprivate var requestTokenWithCompletionActive = false
    
    lazy var offlineClient: TwilioOfflineChatClient = {

        let client = TwilioOfflineChatClient(delegate: self)
        
        return client
    }()
    var delegate:ChannelManager?
    var connected = false
    
    var userIdentity:String {
        return SessionManager.getUsername()
    }
    
    var hasIdentity: Bool {
        return SessionManager.isLoggedIn()
    }
    
    override init() {
        super.init()
        delegate = ChannelManager.sharedManager

        self.reachability = Reachability()
        self.isReachable = self.reachability.isReachable

        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:))
            , name: ReachabilityChangedNotification
            , object: reachability)
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

            self.offlineClient.disconnect()
        }
    }
    
    deinit {
        
        self.reachability.stopNotifier()
    }
    
    class func sharedManager() -> MessagingManager {
        return _sharedManager
    }
    
//    func offlineMessages(forChannel channel: TCHChannel, completion: ([TCHOfflineMessage]) -> ()) {
//
//        self.offlineClient.store.storedMessages(forChannel: channel) { storedMessages in
//            
//            let offlineMessages = storedMessages.map { (storedMessage) -> TCHOfflineMessage in
//                
//                return TCHOfflineMessage(storedMessage)
//            }
//            
//            completion(offlineMessages)
//        }
//    }
    
    func presentRootViewController() {
        
        if (!hasIdentity) {
            presentViewControllerByName(viewController: "LoginViewController")
            return
        }
        
        if (!connected) {
            connectClientWithCompletion { success, error in
                
                guard success else {
                    print("\(error?.localizedDescription ?? "Unknow error!")")
                    return
                }
                
                print("Delegate method will load views when sync is complete")
            }
            return
        }
        
        print("\(String(describing: type(of: self))).\(#function) - \(Date())")

        presentViewControllerByName(viewController: "RevealViewController")
    }
    
    func presentViewControllerByName(viewController: String) {
        presentViewController(controller: storyBoardWithName(name: "Main").instantiateViewController(withIdentifier: viewController))
    }
    
    func presentLaunchScreen() {
        presentViewController(controller: storyBoardWithName(name: "LaunchScreen").instantiateInitialViewController()!)
    }
    
    func presentViewController(controller: UIViewController) {
        let window = UIApplication.shared.delegate!.window!!
        window.rootViewController = controller
    }
    
    func storyBoardWithName(name:String) -> UIStoryboard {
        return UIStoryboard(name:name, bundle: Bundle.main)
    }
    
    // MARK: User and session management
    
    func loginWithUsername(username: String,
                           completion: @escaping (Bool, NSError?) -> Void) {
        SessionManager.loginWithUsername(username: username)
        connectClientWithCompletion(completion: completion)
    }
    
    func logout() {
        SessionManager.logout()
        DispatchQueue.global(qos: .userInitiated).async {
            self.offlineClient.shutdown()
        }
        self.connected = false
    }
    
    // MARK: Twilio Client
    
//    func loadGeneralChatRoomWithCompletion(completion:@escaping (Bool, NSError?) -> Void) {
//        
//        guard self.connected else { return completion(false, nil) }
//        
//        ChannelManager.sharedManager.joinGeneralChatRoomWithCompletion { succeeded in
//            if succeeded {
//                completion(succeeded, nil)
//            }
//            else {
//                let error = self.errorWithDescription(description: "Could not join General channel", code: 300)
//                completion(succeeded, error)
//            }
//        }
//    }
    
    func loadFirstChannelWithCompletion(completion:@escaping (Bool, NSError?) -> Void) {
        
        ChannelManager.sharedManager.joinFirstChannelWithCompletion { succeeded in
            
            if succeeded {
                completion(succeeded, nil)
            }
            else {
                let error = self.errorWithDescription(description: "Could not join first channel", code: 300)
                completion(succeeded, error)
            }
        }
    }
    
    func connectClientWithCompletion(completion: @escaping (Bool, NSError?) -> Void) {
        
        print("\(String(describing: type(of: self))).\(#function) - \(Date())")

        self.reachability.stopNotifier()
        
        if offlineClient.isConnected {
            
            self.logout()
        }

        // if offline we can not obtain the token so can not continue
        // timeout can be very long so we want to preempt the call by checking availability
        // need initializeClientWithChatStore(...) to show offline content
        // this means the TwilioChatClient is not initialised or available so none of the delegate methods are called
        // We want a TwilioOfflineChatClient that has the same API but which deals with the offline store
        // It can then addMessages etc. using the usual interfaces
        // to cycle between online/offline, we need to switch the self.client and refresh the UI
        // when online, messages are added to the TwilioChatClient and in the UI via the various delegates
        // going offline we must synchronize with the TwilioOfflineChatClient i.e. channels and messages etc.
        // when the application is going to shutdown, this should be persisted

        guard self.reachability.isReachable else {
            
            completion(true, nil)
            return
        }
        
        requestTokenWithCompletion { succeeded, token in
            if let token = token, succeeded {
                self.initializeClientWithToken(token: token)
                completion(succeeded, nil)
            }
            else {
                let error = self.errorWithDescription(description: "Could not get access token", code:301)
                completion(succeeded, error)
                self.chatClient(self.offlineClient, synchronizationStatusUpdated: self.offlineClient.synchronizationStatus)
            }
        }
        
        _ = try? reachability.startNotifier()
    }
    
    func initializeClientWithToken(token: String) {
        let accessManager = TwilioAccessManager(token:token, delegate:self)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        TwilioChatClient.chatClient(withToken: token, properties: nil, delegate: self) { [weak self] result, chatClient in
            guard (result?.isSuccessful() ?? false) else { return }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self?.connected = true
            self?.client = chatClient // owership?
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

// MARK: - TwilioChatClientDelegate
extension MessagingManager : TwilioChatClientDelegate {
    func chatClient(_ client: TwilioChatClient!, channelAdded channel: TCHChannel!) {
        
        self.offlineClient.store.addChannel(channel)
        self.delegate?.chatClient(client, channelAdded: channel)
    }
    
    func chatClient(_ client: TwilioChatClient!, channelChanged channel: TCHChannel!) {
        
        self.offlineClient.store.updateChannel(channel)
        self.delegate?.chatClient(client, channelChanged: channel)
    }
    
    func chatClient(_ client: TwilioChatClient!, channelDeleted channel: TCHChannel!) {
        
        self.offlineClient.store.deleteChannel(channel)
        self.delegate?.chatClient(client, channelDeleted: channel)
    }
    
    func chatClient(_ client: TwilioChatClient!, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        
        if status == TCHClientSynchronizationStatus.completed {

            let presentBlock: (Bool, NSError?) -> () = { [weak self] (success, error) in
                
                guard success else {
                    return print("\(error?.localizedDescription ?? "Unknow error!")")
                }
                
                self?.presentRootViewController()
            }

            if client == self.client {
            
                self.offlineClient.connect(toClient: client)
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            ChannelManager.sharedManager.channelsList = client.channelsList()
            ChannelManager.sharedManager.connected = client.connectionState == .connected
            ChannelManager.sharedManager.populateChannels()
            
            loadFirstChannelWithCompletion(completion: presentBlock)
        }
        self.delegate?.chatClient(client, synchronizationStatusUpdated: status)
    }
    
    // TODO is this called even for channels that the user is not subscribed to?
    // Is there a difference between TCHChannelDelegate and TwilioChatClientDelegate in this respect?
    func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, messageAdded message: TCHMessage!) {
        
        self.offlineClient.store.addMessage(message, forChannel: channel)
    }
    
    func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, message: TCHMessage!, updated: TCHMessageUpdate) {
        
        self.offlineClient.store.updateMessage(message, forChannel: channel)
    }
    
    func chatClient(_ client: TwilioChatClient!, channel: TCHChannel!, messageDeleted message: TCHMessage!) {
        
        self.offlineClient.store.deleteMessage(message, forChannel: channel)
    }
}

// MARK: - TwilioAccessManagerDelegate
extension MessagingManager : TwilioAccessManagerDelegate {
    func accessManagerTokenWillExpire(_ accessManager: TwilioAccessManager) {
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
