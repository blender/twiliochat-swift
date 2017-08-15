import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var messagingManager: MessagingManager = TCHMessagingManager.sharedManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.presentLaunchScreen()
        self.presentRootViewController()
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}



extension AppDelegate {
    
    static var sharedDelegate: AppDelegate {
        
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func presentViewController(controller: UIViewController) {
        
        guard let window = self.window else { return }
        
        window.rootViewController = controller
    }
    
    func storyBoardWithName(name:String) -> UIStoryboard {
        
        return UIStoryboard(name:name, bundle: Bundle.main)
    }
    
    func presentViewControllerByName(viewController: String) {
        
        presentViewController(controller: storyBoardWithName(name: "Main").instantiateViewController(withIdentifier: viewController))
    }
    
    func presentLaunchScreen() {
        
        presentViewController(controller: storyBoardWithName(name: "LaunchScreen").instantiateInitialViewController()!)
    }

    func presentRootViewController() {
        
        if (self.messagingManager.user == nil) {
            
            self.presentViewControllerByName(viewController: "LoginViewController")
            return
        }
        
        self.messagingManager.startup { success, error in
            
            guard success else {
                print("\(error?.localizedDescription ?? "Unknow error!")")
                return
            }
            
            self.presentViewControllerByName(viewController: "RevealViewController")
        }
    }
}

