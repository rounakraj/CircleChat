//
//  ProfileTableViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 27/06/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import ProgressHUD

class ProfileTableViewController: UITableViewController {

   
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var callButtonOutlet: UIButton!
    @IBOutlet weak var textButtonOutlet: UIButton!
    @IBOutlet weak var blockUserOutlet: UIButton!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var user: FUser?
    
    
    
    
    //IBActions
    
    
    @IBAction func callButtonPressed(_ sender: Any) {
        
        //Call user
        
        callUser()
        
        let currentUser = FUser.currentUser()!
        
        let call = CallClass(_callerId: currentUser.objectId, _withUserId: user!.objectId, _callerFullName: currentUser.fullname, _withUserFullName: user!.fullname)
        
        call.saveCallInBackground()
    }
    
    
    @IBAction func messageButtonPressed(_ sender: Any) {
        
        if !checkUserBlockStatus(withUser: user!) {
            
            let chatVC = ChatViewController()
            chatVC.viewTitle = user!.firstname
            chatVC.membersToPush = [FUser.currentId(),user!.objectId]
            chatVC.memberIds = [FUser.currentId(),user!.objectId]
            chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: user!)
            chatVC.isGroup = false
            chatVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(chatVC, animated: true)
        } else {
            
            ProgressHUD.showError("This user is not available for chat!")
        }
        
    }
    
    
    @IBAction func blockButtonPressed(_ sender: Any) {
        
        var currentBlockedIds = FUser.currentUser()!.blockedUsers
        if currentBlockedIds.contains(user!.objectId){
            
            let index = currentBlockedIds.index(of: user!.objectId)
            currentBlockedIds.remove(at: index!)
            
        }else{
            
            currentBlockedIds.append(user!.objectId)
        }
        
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID : currentBlockedIds]) { (error) in
            if error != nil {
                print(error?.localizedDescription)
                return
            }
            self.updateBlockStatus()
            
        }
        
        blcockUser(userToBlock: user!)
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
   
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
    
    
    //MARK: SetupUI
    func setupUI()
    {
        if user != nil
        {
            self.title = "Profile"
            fullNameLabel.text = user!.fullname
            phoneNumberLabel.text = user!.phoneNumber
            updateBlockStatus()
            imageFromData(pictureData: user!.avatar) { (avatarImage) in
                if avatarImage != nil{
                    self.avatarImageView.image = avatarImage!.circleMasked
                    
                    
                }
                
            }
            
        }
    }
    
    func updateBlockStatus()
    {
        if user!.objectId != FUser.currentId() {
            blockUserOutlet.isHidden = false
            callButtonOutlet.isHidden = false
            textButtonOutlet.isHidden = false
        } else {
            
            blockUserOutlet.isHidden = true
            callButtonOutlet.isHidden = true
            textButtonOutlet.isHidden = true
        }
        
        if FUser.currentUser()!.blockedUsers.contains(user!.objectId){
            blockUserOutlet.setTitle("Unblock User", for: .normal)
            
        } else {
            blockUserOutlet.setTitle("Block User", for: .normal)
            
        }
        
        
        
    }
    
    //MARK: CallUser
    
    func callClient() -> SINCallClient {
        
        return appDelegate._client.call()
    }
    func callUser() {
        let userToCall = user!.objectId
        let call = callClient().callUserVideo(withId: userToCall)
        
        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoVC") as! VideoCallViewController
        
        callVC._call = call
        self.present(callVC, animated: true, completion: nil)
    }
    
}
