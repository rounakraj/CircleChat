//
//  SettingsTableViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 26/06/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import ProgressHUD

class SettingsTableViewController: UITableViewController {
    
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var fullNameLabel: UILabel!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var showAvatarStatusSwitch: UISwitch!
    
    
    @IBOutlet weak var versionLabel: UILabel!
    
    var avatarSwitchStatus = false
    
    let userDefaults = UserDefaults.standard
    var firstLoad: Bool?
    
    override func viewDidAppear(_ animated: Bool) {
        if FUser.currentUser() != nil {
            setupUI()
            loadUserDefaults()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.tableFooterView = UIView()
        
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 1 {
            return 5
        }
         return 2
    }

    //MARK: TAbleView Delegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
        
        
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            return 0
        }
        
        return 30
        
        
    }
    //MARK: IBActions
    
    @IBAction func showAvatarSwitchValueChanged(_ sender: UISwitch) {
        
        if sender.isOn {
            avatarSwitchStatus = true
        } else {
            avatarSwitchStatus = false
        }
        //save user defaults
        saveUserDefaults()
        
    }
    
    
    
    @IBAction func cleanCacheButtonPressed(_ sender: Any) {
        
        do {
            
            let files = try FileManager.default.contentsOfDirectory(atPath: getDocumnetsURL().path)
            
            for file in files {
                try FileManager.default.removeItem(atPath: "\(getDocumnetsURL().path)/\(file)")
            }
            ProgressHUD.showSuccess("Cache Cleaned!")
        }
        catch
        {
            ProgressHUD.showError("Cache Cleaning Failed!")
        }
    }
    
    
    @IBAction func tellAFriendButtonPressed(_ sender: Any) {
        
        let text = "Hey! Lets chat on Circle Chat. \(kAPPURL)"
        let objectsToShare:[Any] = [text]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.setValue("Lets chat on Circle Chat!", forKey: "subject")
        self.present(activityViewController,animated: true,completion: nil)
    }
    
    
    
    @IBAction func termsAndConditionsButtonPressed(_ sender: Any) {
    }
    
    @IBAction func deleteAccountButtonPressed(_ sender: Any) {
        let optionMenu = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete your account?", preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (alert) in
            //Delete the User
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
            //Cancel the Dialog
        }
        
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        //Options Menu on iPad
        if (UI_USER_INTERFACE_IDIOM() == .pad)
        {
            
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController{
                
                currentPopoverpresentioncontroller.sourceView = deleteButton
                currentPopoverpresentioncontroller.sourceRect = deleteButton.bounds
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                self.present(optionMenu,animated: true, completion: nil)
            }
        }else {
            self.present(optionMenu,animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        
        FUser.logOutCurrentUser { (success) in
            if success {
                //show login view
                ProgressHUD.show("Logging Out...")
                self.showLoginView()
                
            }
        }
    }
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        
        print("Back Button Pressed")
        self.goToApp()
        
    }
    
    //MARK: Delete User
    
    func deleteUser()
    {
        userDefaults.removeObject(forKey: kPUSHID)
        userDefaults.removeObject(forKey: kCURRENTUSER)
        userDefaults.synchronize()
        
        //Delete from firebase
        
        reference(.User).document(FUser.currentId()).delete()
        FUser.deleteUser { (error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    ProgressHUD.showError("User Deletion Failed!")
                }
                return
            }
            self.showLoginView()
        }
    }
    
    //MARK: SAVE USER DEFAULTS
    
    func saveUserDefaults()
    {
        userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
        userDefaults.synchronize()
    }
    
    func loadUserDefaults()
    {
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        if !firstLoad! {
            userDefaults.set(true, forKey: kFIRSTRUN)
            userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
            userDefaults.synchronize()
        }
        avatarSwitchStatus = userDefaults.bool(forKey: kSHOWAVATAR)
        showAvatarStatusSwitch.isOn = avatarSwitchStatus
    }
    
    func goToApp()
    {
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
        
        
        //present the app here
        print("Show the App")
        
        
        
    }
    
    func showLoginView()
    {
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateInitialViewController()
        ProgressHUD.dismiss()
        self.present(mainView!, animated: true, completion: nil)
    }
    
    
    //MARK: SetupUI
    func setupUI()
    {
        let currentUser = FUser.currentUser()!
        fullNameLabel.text = currentUser.fullname
        
        if(currentUser.avatar != ""){
            
            imageFromData(pictureData: currentUser.avatar) { (image) in
                if image != nil {
                    self.avatarImageView.image = image!.circleMasked
                }
            }
            
            
        }
        //set app version
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String{
            versionLabel.text = version
        }
        
    }
    
}
