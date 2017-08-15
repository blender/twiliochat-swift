import UIKit
import SlackTextViewController

class MainChatViewController: SLKTextViewController {
    static let TWCChatCellIdentifier = "ChatTableCell"
    static let TWCChatStatusCellIdentifier = "ChatStatusTableCell"
    
    static let TWCOpenGeneralChannelSegue = "OpenGeneralChat"
    static let TWCLabelTag = 200
    
    fileprivate var channel:ActiveChannel?
    
    var messages:Set<StoredMessage> = Set<StoredMessage>()
    var sortedMessages:[StoredMessage]!
    
    @IBOutlet weak var revealButtonItem: UIBarButtonItem!
    @IBOutlet weak var actionButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (revealViewController() != nil) {
            revealButtonItem.target = revealViewController()
            revealButtonItem.action = #selector(SWRevealViewController.revealToggle(_:))
            navigationController?.navigationBar.addGestureRecognizer(revealViewController().panGestureRecognizer())
            revealViewController().rearViewRevealOverdraw = 0
        }
        
        bounces = true
        shakeToClearEnabled = true
        isKeyboardPanningEnabled = true
        shouldScrollToBottomAfterKeyboardShows = false
        isInverted = true
        
        let cellNib = UINib(nibName: MainChatViewController.TWCChatCellIdentifier, bundle: nil)
        tableView!.register(cellNib, forCellReuseIdentifier:MainChatViewController.TWCChatCellIdentifier)
        
        let cellStatusNib = UINib(nibName: MainChatViewController.TWCChatStatusCellIdentifier, bundle: nil)
        tableView!.register(cellStatusNib, forCellReuseIdentifier:MainChatViewController.TWCChatStatusCellIdentifier)
        
        textInputbar.autoHideRightButton = true
        textInputbar.maxCharCount = 256
        textInputbar.counterStyle = .split
        textInputbar.counterPosition = .top
        
        let font = UIFont(name:"Avenir-Light", size:14)
        textView.font = font
        
        rightButton.setTitleColor(UIColor(red:0.973, green:0.557, blue:0.502, alpha:1), for: .normal)
        
        if let font = UIFont(name:"Avenir-Heavy", size:17) {
            navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: font]
        }
        
        tableView!.allowsSelection = false
        tableView!.estimatedRowHeight = 70
        tableView!.rowHeight = UITableViewAutomaticDimension
        tableView!.separatorStyle = .none
        
        var messagingManager = AppDelegate.sharedDelegate.messagingManager
        messagingManager.delegate = self
    
        if self.channel == nil {

            let channelManager = messagingManager.channelManager
            self.messagingManager(messagingManager
                , choseChannel: channelManager.channels.first)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToBottom()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: NSInteger) -> Int {
        
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        
        let message = sortedMessages[indexPath.row]
        
        if let statusMessage = message as? StatusMessage {
            cell = getStatusCellForTableView(tableView: tableView, forIndexPath:indexPath, message:statusMessage)
        }
        else {
            cell = getChatCellForTableView(tableView: tableView, forIndexPath:indexPath, message:message)
        }
        
        cell.transform = tableView.transform
        return cell
    }
    
    func getChatCellForTableView(tableView: UITableView, forIndexPath indexPath:IndexPath, message: ChatMessage) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainChatViewController.TWCChatCellIdentifier, for:indexPath as IndexPath)
        
        let chatCell: ChatTableCell = cell as! ChatTableCell
        let timestamp = DateTodayFormatter().stringFromDate(date: message.timestamp as NSDate)
        
        chatCell.setUser(user: message.author ?? "[Unknown author]", message: message.body, date: timestamp ?? "[Unknown date]")
        
        // TODO: advanceLastConsumedMessageIndex as it has been displayed on screen
        // maybe add a view model to assist UI clients
        // work on the basis of accessing a dedicated array of messages which imply consumption...
        
        return chatCell
    }
    
    func getStatusCellForTableView(tableView: UITableView, forIndexPath indexPath:IndexPath, message: StatusMessage) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainChatViewController.TWCChatStatusCellIdentifier, for:indexPath as IndexPath)
        
        let label = cell.viewWithTag(MainChatViewController.TWCLabelTag) as! UILabel
        let memberStatus = (message.status! == .Joined) ? "joined" : "left"
        label.text = "User \(message.member.identity) has \(memberStatus)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle
        , forRowAt indexPath: IndexPath) {
        
        self.channel?.removeMessage(atIndex: indexPath.row)
    }
    
    // Disable user input and show activity indicator
    func setViewOnHold(onHold: Bool) {
        self.isTextInputbarHidden = onHold;
        UIApplication.shared.isNetworkActivityIndicatorVisible = onHold;
    }
    
    override func didPressRightButton(_ sender: Any!) {
        textView.refreshFirstResponder()
        self.sendMessage(inputMessage: textView.text)
        super.didPressRightButton(sender)
    }
    
    // MARK: - Chat Service
    
    func sendMessage(inputMessage: String) {

        self.channel?.sendMessage(inputMessage)
    }
    
    private func addMessages(_ newMessages: [StoredMessage]) {
        self.messages =  messages.union(Set(newMessages))
        self.sortMessages()
        DispatchQueue.main.async {
            self.tableView!.reloadData()
            if self.messages.count > 0 {
                self.scrollToBottom()
            }
        }
    }
    
    fileprivate func sortMessages() {
        sortedMessages = messages.sorted { a, b in a.timestamp > b.timestamp }
    }
    
    fileprivate func clearMessages() {
        
        messages.removeAll()
    }
    
    fileprivate func loadMessages() {
        
        self.clearMessages()
        
        guard let messages = self.channel?.messages else { return }
        
        self.addMessages(messages)
    }
    
    private func scrollToBottom() {
        if messages.count > 0 {
            let indexPath = IndexPath(row: 0, section: 0)
            tableView!.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    @IBAction func revealButtonTouched(_ sender: AnyObject) {
        revealViewController().revealToggle(animated: true)
    }
}



extension MainChatViewController: MessagingDelegate {
    
    private func activateChannel(_ channel: StoredChannel, inManager manager: ChannelManager) {
    
        manager.activateChannel(channel) { [weak self] activeChannel in
            
            self?.channel = activeChannel
            self?.title = self?.channel?.displayName
            self?.loadMessages()
        }
    }
    
    func messagingManager(_ manager: MessagingManager, addedMessage message: StoredMessage, toChannel channel: StoredChannel) {
     
        guard self.channel?.sid == channel.sid else { return }

        // TODO: this refreshes everything... maybe sync change instead
        self.activateChannel(channel, inManager: manager.channelManager)
    }
    
    func messagingManager(_ manager: MessagingManager, deletedMessage message: StoredMessage, fromChannel channel: StoredChannel) {

        guard self.channel?.sid == channel.sid else { return }
        
        // TODO: this refreshes everything... maybe sync change instead
        self.activateChannel(channel, inManager: manager.channelManager)
    }
    
    func messagingManager(_ manager: MessagingManager, updatedMessage: StoredMessage, inChannel channel: StoredChannel) {
        
        guard self.channel?.sid == channel.sid else { return }
        
        // TODO: this refreshes everything... maybe sync change instead
        self.activateChannel(channel, inManager: manager.channelManager)
    }

    func messagingManager(_ manager: MessagingManager, updatedChannel channel: StoredChannel) {
        
        guard self.channel?.sid == channel.sid else { return }
        
        self.activateChannel(channel, inManager: manager.channelManager)
    }
    
    func messagingManager(_ manager: MessagingManager, choseChannel channel: StoredChannel?) {
    
        guard self.channel?.sid != channel?.sid else {
            
            return
        }
        
        guard let chosenChannel = channel else {
            
            self.channel = nil
            self.clearMessages()
            return
        }
        
        self.activateChannel(chosenChannel, inManager: manager.channelManager)
    }
    
    func channelManager(_: ChannelManager, deletedChannel: StoredChannel) {
        
        // TODO: if this is the current channel we must reset
    }
    
    func channelManager(_ manager: ChannelManager, updatedChannel channel: StoredChannel) {
        
        guard self.channel?.sid == channel.sid else { return }
        
        self.activateChannel(channel, inManager: manager)
    }

}
