//
//  BlockedUsersViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 02/08/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import ProgressHUD


class BlockedUsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UserTableViewCellDelegate {
    
    
   
    @IBOutlet weak var noBlockedUsersLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var blockedUsersrray : [FUser] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        loadUsers()

        
    }
    
    //MARK: TABLE VIEW DATA SOURCE
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        noBlockedUsersLabel.isHidden = blockedUsersrray.count != 0
        
        return blockedUsersrray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        
        cell.delegate = self
        cell.generateUserCell(fUser: blockedUsersrray[indexPath.row], indexPath: indexPath)
        return cell
    }
    
    
    //MARK: TABLE VIEW DELEGATE
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Unblock"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        var tempBlockedUsers = FUser.currentUser()!.blockedUsers
        let userIdToUnblock = blockedUsersrray[indexPath.row].objectId
        
        tempBlockedUsers.remove(at: tempBlockedUsers.index(of: userIdToUnblock)!)
        blockedUsersrray.remove(at: indexPath.row)
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID:tempBlockedUsers])
        {
        
            (error) in
            
            if error != nil {
                
                ProgressHUD.showError(error!.localizedDescription)
            }
       }
        
        self.tableView.reloadData()
    }
    
    //MARK: Load Blocked Users
    
    func loadUsers() {
        
        if FUser.currentUser()!.blockedUsers.count > 0 {
            ProgressHUD.show()
            getUsersFromFirestore(withIds: FUser.currentUser()!.blockedUsers) { (allBlockedUsers) in
                
                ProgressHUD.dismiss()
                self.blockedUsersrray = allBlockedUsers
                self.tableView.reloadData()
                
            }
        }
        
    }
    
    //MARK: USER Table View Cell Delegate
    
    func didTapAvatarImage(indexPath: IndexPath) {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
        
        profileVC.user = blockedUsersrray[indexPath.row]
        self.navigationController?.pushViewController(profileVC, animated: true)
        
    }


}
