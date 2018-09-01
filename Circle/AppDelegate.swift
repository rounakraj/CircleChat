//
//  AppDelegate.swift
//  Circle
//
//  Created by Kumar Rounak on 22/06/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import Firebase

import CoreLocation

import OneSignal
import PushKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, SINClientDelegate, SINCallClientDelegate, SINManagedPushDelegate, PKPushRegistryDelegate {
    
    

    var window: UIWindow?
    var authListener: AuthStateDidChangeListenerHandle?
    
    var locationManager: CLLocationManager?
    var coordinates: CLLocationCoordinate2D?
    
    
    var _client: SINClient!
    var push: SINManagedPush!
    


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        
        //AutoLogin
        
        authListener = Auth.auth().addStateDidChangeListener({(auth, user) in
            Auth.auth().removeStateDidChangeListener(self.authListener!)
            if user != nil {
                if (UserDefaults.standard.object(forKey: kCURRENTUSER) != nil)
                {
                    DispatchQueue.main.async {
                        self.goToApp()
                    }
                    
                }
            }
            
        })
        
        self.voipRegistration()
        self.push = Sinch.managedPush(with: .development)
        self.push.delegate = self
        self.push.setDesiredPushTypeAutomatically()
        
        func userDidLogin(userId: String) {
            self.push.registerUserNotificationSettings()
            self.initSinchWithUserId(userId: userId)
            self.startOneSignal()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(USER_DID_LOGIN_NOTIFICATION), object: nil, queue: nil) { (note) in
            
            let userId = note.userInfo![kUSERID] as! String
            UserDefaults.standard.set(userId, forKey: kUSERID)
            UserDefaults.standard.synchronize()
            userDidLogin(userId: userId)
            
        }
        OneSignal.initWithLaunchOptions(launchOptions, appId: kONESIGNALAPPID)
        
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        var top = self.window?.rootViewController
        while top?.presentedViewController != nil {
            top = top?.presentedViewController
        }
        
        if top! is UITabBarController {
            setBadges(controller: top as! UITabBarController)
        }
        
        if FUser.currentUser() != nil {
            updateCurrentUserInFirestore(withValues: [kISONLINE : true]) { (success) in
                
            }
        }
        startLocationManager()
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        recentBadgeHandler?.remove()
        
        if FUser.currentUser() != nil {
            updateCurrentUserInFirestore(withValues: [kISONLINE : false]) { (success) in
                
            }
        }
        stopLocationManager()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK: goToApp
    func goToApp()
    {
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.window?.rootViewController = mainView
        
        //present the app here
        print("Show the App")
        
        
        
    }
    
    
    //MARK: PUSHNOTIFICATION FUNCTIONS
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        self.push.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let firebaseAuth = Auth.auth()
        if firebaseAuth.canHandleNotification(userInfo) {
            return
        } else {
            self.push.application(application, didReceiveRemoteNotification: userInfo)
        }
    }
    
    //MARK: Location Manager Delegate
    
    func startLocationManager()
    {
        if locationManager == nil{
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            
            locationManager!.requestWhenInUseAuthorization()
        }
        
        locationManager!.startUpdatingLocation()
    }
    
    func stopLocationManager()
    {
        if locationManager != nil{
            
            locationManager!.stopUpdatingLocation()
        }
    }

   //Delegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print("Failed to get Location")
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .authorizedAlways:
            manager.startUpdatingLocation()
        case .restricted:
            print("Restricted")
        case .denied:
            locationManager = nil
            print("Denied Location Access")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        coordinates = locations.last!.coordinate
        
    }
    
    //MARK: OneSignal
    
    func startOneSignal() {
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        
        let userID = status.subscriptionStatus.userId
        let pushToken = status.subscriptionStatus.pushToken
        
        if pushToken != nil {
            if let playerID = userID {
                UserDefaults.standard.set(playerID, forKey: kPUSHID)
            } else {
                UserDefaults.standard.removeObject(forKey: kPUSHID)
            }
            UserDefaults.standard.synchronize()
        }
        //updateOneSignalID
        
        updateOneSignalId()
    }
    
    //MARK: SINCH
    
    func initSinchWithUserId(userId: String)
    {
        if _client == nil {
            
            _client = Sinch.client(withApplicationKey: kSINCHKEY, applicationSecret: kSINCHSECRET, environmentHost: "sandbox.sinch.com", userId: userId)
            
            _client.delegate = self
            _client.call()?.delegate = self
            
            _client.setSupportCalling(true)
            _client.enableManagedPushNotifications()
            _client.start()
            _client.startListeningOnActiveConnection()
            
        }
        
    }
    

    
    //MARK: SINCH MANAGED PUSH DELEGATE
    
    func managedPush(_ managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [AnyHashable : Any]!, forType pushType: String!) {
        
        let result = SINPushHelper.queryPushNotificationPayload(payload)
        
        if result!.isCall() {
            print("Incoming Push Payload")
            //handle remote notifications
            self.handleRemoteNotification(userInfo: payload as NSDictionary)
        }
    }
    
    
    func handleRemoteNotification(userInfo: NSDictionary) {
        
        if _client == nil {
            let userId = UserDefaults.standard.object(forKey: kUSERID)
            if userId != nil {
                self.initSinchWithUserId(userId: userId as! String)
            }
        }
        
        let result = self._client.relayRemotePushNotification(userInfo as! [AnyHashable : Any])
        
        if result!.isCall() {
            print("Handle Call Notification")
        }
        
        if result!.isCall() && result!.call()!.isCallCanceled {
            
            print("Missed Call")
            self.presentMissedCallNotificationWithRemoteUserId(userId: result!.call()!.callId)
        }
    }
    
    func presentMissedCallNotificationWithRemoteUserId(userId: String) {
        
        if UIApplication.shared.applicationState == .background {
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "Missed Call"
            content.body = "From \(userId)"
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            let request = UNNotificationRequest(identifier: "ContentIdentifier", content: content, trigger: trigger)
            
            center.add(request) { (error) in
                if error != nil {
                    print("error on notification", error!.localizedDescription)
                }
            }
        }
    }
    
    
    //MARK: SinchCallClientDelegate
    
    func client(_ client: SINCallClient!, willReceiveIncomingCall call: SINCall!) {
        
        print("will receive incoming call")
    }
    
    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        
        print("did receive call")
        
        //present call view
        
        var top = self.window?.rootViewController
        
        while(top?.presentedViewController != nil) {
            
            top = top?.presentedViewController
        }
        
       let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier:  "CallVC") as! CallViewController
        
        callVC._call = call
        top?.present(callVC,animated: true, completion: nil)
        
    }
    
    //MARK: SinchClientDelegate
    
    func clientDidStart(_ client: SINClient!) {
        print("Sinch did start")
    }
    
    func clientDidStop(_ client: SINClient!) {
        print("Sinch did stop")
    }
    
    func clientDidFail(_ client: SINClient!, error: Error!) {
        print("Sinch did fail\(error.localizedDescription)")
    }
    
    func voipRegistration() {
        
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
    
    //MARK: PKPUSH DELEGATE
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        
        print("Did get incoming Push")
        self.handleRemoteNotification(userInfo: payload.dictionaryPayload as NSDictionary)
    }
    
 }

