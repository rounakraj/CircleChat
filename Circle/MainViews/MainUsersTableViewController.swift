//
//  MainUsersTableViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 01/09/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import ProgressHUD
import Firebase

class MainUsersTableViewController: UITableViewController, UserTableViewCellDelegate {
    
    
    
    @IBOutlet weak var headerView: UIView!
    
    var allUsers: [FUser] = []
    var allUsersGroupped = NSDictionary() as! [String : [FUser]]
    var sectionTitleList : [String] = []
    
    var newMemberIds: [String] = []
    var currentMemberIds: [String] = []
    var group: NSDictionary!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var user: FUser?
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        loadUsers(filter: kCITY)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Users"
        tableView.tableFooterView = UIView()
        
       
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.allUsersGroupped.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionTitle = self.sectionTitleList[section]
        
        let users = self.allUsersGroupped[sectionTitle]
        
        return users!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        
        let sectionTitle = self.sectionTitleList[indexPath.section]
        let users = self.allUsersGroupped[sectionTitle]
        
        cell.generateUserCell(fUser: users![indexPath.row], indexPath: indexPath)
        cell.delegate = self
        
        return cell
    }
    
    //MARK: TableView Delegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return sectionTitleList[section]
    }
    
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        return self.sectionTitleList
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        
        return index
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sectionTitle = self.sectionTitleList[indexPath.section]
        let userToChat : FUser
        let users = self.allUsersGroupped[sectionTitle]
        userToChat = users![indexPath.row]
        
        //////////////////
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let sendChat = UIAlertAction(title: "Chat", style: .default) { (action) in
            
            print("Chat")
            if !checkUserBlockStatus(withUser: userToChat) {
                
                let chatVC = ChatViewController()
                //chatVC.title = userToChat.firstname
                chatVC.memberIds = [FUser.currentId(),userToChat.objectId]
                chatVC.membersToPush = [FUser.currentId(),userToChat.objectId]
                chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: userToChat)
                chatVC.isGroup = false
                chatVC.hidesBottomBarWhenPushed = true
                
                self.navigationController?.pushViewController(chatVC, animated: true)
                
            } else {
                
                ProgressHUD.showError("This user is not available for Chat!")
            }
            
            
        }
        
        let sendVideo = UIAlertAction(title: "Video Call", style: .default) { (action) in
            
            print("Video Call")
            self.user = userToChat
            self.callUser()
            let currentUser = FUser.currentUser()!
            let call = CallClass(_callerId: currentUser.objectId, _withUserId: userToChat.objectId, _callerFullName: currentUser.fullname, _withUserFullName: userToChat.fullname)
            call.saveCallInBackground()
            
        }
        
        let sendAudio = UIAlertAction(title: "Audio Call", style: .default) { (action) in
            
            print("Audio Call")
            self.user = userToChat
            self.callUser()
            let currentUser = FUser.currentUser()!
            let call = CallClass(_callerId: currentUser.objectId, _withUserId: userToChat.objectId, _callerFullName: currentUser.fullname, _withUserFullName: userToChat.fullname)
            call.saveCallInBackground()
            
            
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        
        sendChat.setValue(UIImage(named: "optionChat"), forKey: "image")
        sendVideo.setValue(UIImage(named: "videocall"), forKey: "image")
        sendAudio.setValue(UIImage(named: "optionCall"), forKey: "image")
        
        optionMenu.addAction(sendChat)
        optionMenu.addAction(sendVideo)
        optionMenu.addAction(sendAudio)
        optionMenu.addAction(cancelAction)
        
        
        //Options Menu on iPad
        if (UI_USER_INTERFACE_IDIOM() == .pad)
        {
            
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController{
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                self.present(optionMenu,animated: true, completion: nil)
            }
        }else {
            self.present(optionMenu,animated: true, completion: nil)
            
        }
       
    }
    
    
    //MARK: LoadUsers
    
    func loadUsers(filter: String) {
        
        ProgressHUD.show()
        
        var query: Query!
        
        switch filter {
        case kCITY:
            query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city).order(by: kFIRSTNAME, descending: false)
        case kCOUNTRY:
            query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country).order(by: kFIRSTNAME, descending: false)
        default:
            query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        
        query.getDocuments { (snapshot, error) in
            
            self.allUsers = []
            self.sectionTitleList = []
            self.allUsersGroupped = [:]
            
            if error != nil {
                print(error!.localizedDescription)
                ProgressHUD.dismiss()
                self.tableView.reloadData()
                return
            }
            
            guard let snapshot = snapshot else {
                ProgressHUD.dismiss(); return
            }
            
            if !snapshot.isEmpty {
                
                for userDictionary in snapshot.documents {
                    
                    let userDictionary = userDictionary.data() as NSDictionary
                    let fUser = FUser(_dictionary: userDictionary)
                    
                    if fUser.objectId != FUser.currentId() {
                        self.allUsers.append(fUser)
                    }
                }
                
                
                self.splitDataIntoSection()
                self.tableView.reloadData()
            }
            
            self.tableView.reloadData()
            ProgressHUD.dismiss()
            
        }
        
    }
    
    
    
    
    //MARK: IBactions
    
    @IBAction func filterSegmentValueChanged(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            loadUsers(filter: kCITY)
        case 1:
            loadUsers(filter: kCOUNTRY)
        case 2:
            loadUsers(filter: "")
        default:
            return
        }
    }
    
   
    
    //MARK: UsersTableViewCellDelegate
    func didTapAvatarImage(indexPath: IndexPath) {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
        
        let sectionTitle = self.sectionTitleList[indexPath.section]
        
        let users = self.allUsersGroupped[sectionTitle]
        
        profileVC.user = users![indexPath.row]
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    //MARK: Helper functions
    
   
    
    
    fileprivate func splitDataIntoSection() {
        
        var sectionTitle: String = ""
        
        for i in 0..<self.allUsers.count {
            
            let currentUser = self.allUsers[i]
            
            let firstChar = currentUser.firstname.first!
            
            let firstCarString = "\(firstChar)"
            
            
            if firstCarString != sectionTitle {
                
                sectionTitle = firstCarString
                
                self.allUsersGroupped[sectionTitle] = []
                
                if !sectionTitleList.contains(sectionTitle) {
                    self.sectionTitleList.append(sectionTitle)
                }
            }
            
            self.allUsersGroupped[firstCarString]?.append(currentUser)
            
        }
        
    }
    
    func callClient() -> SINCallClient {
        
        return appDelegate._client.call()
    }
    func callUser() {
        let userToCall = user!.objectId
        let call = callClient().callUser(withId: userToCall)
        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallVC") as! CallViewController
        
        callVC._call = call
        self.present(callVC, animated: true, completion: nil)
    }
    
    
    func callUserVideo() {
        let userToCall = user!.objectId
        let call = callClient().callUserVideo(withId: userToCall)
        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoVC") as! VideoCallViewController
        callVC._call = call
        self.present(callVC, animated: true, completion: nil)
    }
    
    
}
