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
    
    var rootViewControllerName: String?
    
    override init() {
        super.init()
        delegate = ChannelManager.sharedManager

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
        
        if (!self.hasIdentity) {
            presentViewControllerByName(viewController: "LoginViewController")
            return
        }

        connectClientWithCompletion { success, error in
            
            guard success else {
                print("\(error?.localizedDescription ?? "Unknow error!")")
                return
            }
            
            print("Delegate method will load views when sync is complete")
        }

        print("\(String(describing: type(of: self))).\(#function) - \(Date())")
    }
    
    func presentViewControllerByName(viewController: String) {
        
        let name = "Main.\(viewController)"
        
        guard name != self.rootViewControllerName else {
            
            return
        }
        
        self.rootViewControllerName = name
        presentViewController(controller: storyBoardWithName(name: "Main").instantiateViewController(withIdentifier: viewController))
    }
    
    func presentLaunchScreen() {
        let name = "LaunchScreen.Initial"

        guard name != self.rootViewControllerName else {
            
            return
        }

        self.rootViewControllerName = name
        presentViewController(controller: storyBoardWithName(name: "LaunchScreen").instantiateInitialViewController()!)
    }
    
    private func presentViewController(controller: UIViewController) {
        let window = UIApplication.shared.delegate!.window!!

        window.rootViewController = controller
    }
    
    fileprivate var mainChatViewController: MainChatViewController? {
    
        let window = UIApplication.shared.delegate!.window!!
    
        return window.rootViewController?.childViewControllers.last?.childViewControllers.first as? MainChatViewController
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

        guard self.reachability.isReachable else {
            
            completion(true, nil)
            self.chatClient(self.offlineClient, synchronizationStatusUpdated: self.offlineClient.synchronizationStatus)
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

            let isOnlineClient = (client == self.client)
            
            if isOnlineClient {
            
                self.offlineClient.connect(toClient: client)
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            ChannelManager.sharedManager.channelsList = client.channelsList()
            
            // TODO behaviour is currently based on which client comes last - which is usually the onlineClient
            ChannelManager.sharedManager.connected = isOnlineClient
            ChannelManager.sharedManager.populateChannels()
            
            loadFirstChannelWithCompletion { (success, error) in

                guard success else {
                    return print("\(error?.localizedDescription ?? "Unknow error!")")
                }

                guard let mainChatViewController = self.mainChatViewController else {
                    
                    self.presentViewControllerByName(viewController: "RevealViewController")
                    return
                }

                mainChatViewController.channel = ChannelManager.sharedManager.currentChannel
            }
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
