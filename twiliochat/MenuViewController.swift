import UIKit

class MenuViewController: UIViewController {
    static let TWCOpenChannelSegue = "OpenChat"
    static let TWCRefreshControlXOffset: CGFloat = 120
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    var refreshControl: UIRefreshControl!
    
    var messagingManager = AppDelegate.sharedDelegate.messagingManager
    lazy var channelManager: ChannelManager = {
       
        var manager = self.messagingManager.channelManager
        manager.delegate = self
        
        return manager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bgImage = UIImageView(image: UIImage(named:"home-bg"))
        bgImage.frame = self.tableView.frame
        tableView.backgroundView = bgImage
        
        usernameLabel.text = self.messagingManager.user?.displayName
        
        refreshControl = UIRefreshControl()
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(MenuViewController.refreshChannels), for: .valueChanged)
        refreshControl.tintColor = UIColor.white
        
        self.refreshControl.frame.origin.x -= MenuViewController.TWCRefreshControlXOffset
        
        reloadChannelList()
    }
    
    // MARK: - Internal methods
    
    func loadingCellForTableView(tableView: UITableView) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "loadingCell")!
    }
    
    func channelCellForTableView(tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let menuCell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath as IndexPath) as! MenuTableCell
        
        let channel = self.channelManager.channels[indexPath.row]
        
        menuCell.channelName = channel.displayName ?? ""
        
        return menuCell
    }
    
    func reloadChannelList() {
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    func refreshChannels() {
        refreshControl.beginRefreshing()
        reloadChannelList()
    }
    
    func deselectSelectedChannel() {
        let selectedRow = tableView.indexPathForSelectedRow
        if let row = selectedRow {
            tableView.deselectRow(at: row, animated: true)
        }
    }
    
    // MARK: - Channel
        
    // MARK: Logout
    
    func promptLogout() {
        let alert = UIAlertController(title: nil, message: "You are about to Logout", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { action in
            self.logOut()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        present(alert, animated: true, completion: nil)
    }
    
    func logOut() {
        self.messagingManager.logout()
        AppDelegate.sharedDelegate.presentRootViewController()
    }
    
    // MARK: - Actions
    
    @IBAction func logoutButtonTouched(_ sender: UIButton) {
        promptLogout()
    }
    
//    @IBAction func newChannelButtonTouched(_ sender: UIButton) {
//        createNewChannelDialog()
//    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == MenuViewController.TWCOpenChannelSegue {
            let indexPath = sender as! NSIndexPath
            let channel = self.channelManager.channels[indexPath.row]
            let navigationController = segue.destination as! UINavigationController
            
            guard let mainChatViewController = navigationController.visibleViewController as? MainChatViewController else {
                
                return
            }
            
            self.messagingManager.delegate = nil
            mainChatViewController.chooseChannel(channel)
        }
    }
    
    // MARK: - Style
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

// MARK: - UITableViewDataSource
extension MenuViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return max(self.channelManager.channels.count, 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        if self.channelManager.channels.isEmpty {
            cell = loadingCellForTableView(tableView: tableView)
        }
        else {
            cell = channelCellForTableView(tableView: tableView, atIndexPath: indexPath as NSIndexPath)
        }
        
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        
        let channel = self.channelManager.channels[indexPath.row]
        self.channelManager.deleteChannel(channel)
    }
}


// MARK: - UITableViewDelegate
extension MenuViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: MenuViewController.TWCOpenChannelSegue, sender: indexPath)
    }
}



extension MenuViewController: ChannelDelegate {
    
    func channelManager(_ manager: ChannelManager, addedChannel: ChatChannel) {
        
        tableView.reloadData()
    }

    func channelManager(_ manager: ChannelManager, deletedChannel: ChatChannel) {
        
        tableView.reloadData()
    }

    func channelManager(_ manager: ChannelManager, updatedChannel: ChatChannel) {
        
        tableView.reloadData()
    }
}
