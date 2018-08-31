//
//  UsersTableViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 27/06/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD


class UsersTableViewController: UITableViewController, UISearchResultsUpdating, UserTableViewCellDelegate {
   
    
   
   

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var filterSegmentedViewController: UISegmentedControl!
    
    var allUsers: [FUser] = []
    var filteredUser: [FUser] = []
    var allUserGroupped = NSDictionary() as! [String: [FUser]]
    var sectionTitleList : [String] = []
    let searchController = UISearchController(searchResultsController: nil)
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Users"
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        loadUsers(filter: kCITY)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        
        if searchController.isActive && searchController.searchBar.text != ""
        {
            return 1
        }else{
            return allUserGroupped.count
        }
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
         if searchController.isActive && searchController.searchBar.text != ""
         {
            return filteredUser.count
            
         }else {
            
            //find sectionTitle
            let sectionTitle = self.sectionTitleList[section]
            
            //user for given title
            
            let users = self.allUserGroupped[sectionTitle]
            return users!.count
        }
        
        
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell

        var user: FUser
        if searchController.isActive && searchController.searchBar.text != "" {
            
            user = filteredUser[indexPath.row]
        }else
        {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUserGroupped[sectionTitle]
            
            user = users![indexPath.row]
            
        }
        
        // Configure the cell...\
        cell.generateUserCell(fUser: user, indexPath: indexPath)
        cell.delegate = self
        
        

        return cell
    }
    
    //MARK: TableView  Delegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
     
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        }else{
            return sectionTitleList[section]
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
       
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        }else{
            return self.sectionTitleList
            
        }
        
    }
        
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var user: FUser
        if searchController.isActive && searchController.searchBar.text != "" {
            
            user = filteredUser[indexPath.row]
        }else
        {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUserGroupped[sectionTitle]
            
            user = users![indexPath.row]
            
        }
        
        if !checkUserBlockStatus(withUser: user) {
            
            let chatVC = ChatViewController()
            chatVC.viewTitle = user.firstname
            chatVC.membersToPush = [FUser.currentId(),user.objectId]
            chatVC.memberIds = [FUser.currentId(),user.objectId]
            chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: user)
            chatVC.isGroup = false
            chatVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(chatVC, animated: true)
        } else {
            
            ProgressHUD.showError("This user is not available for chat!")
        }
        
        
        
        
    }
    
    //MARK: IBActions
    
    
    @IBAction func filterSegmnetValueChanged(_ sender: UISegmentedControl) {
        
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
    
    
    //MARK: SearchControl Functions
    
    func filterContentForSearchText(searchText: String, scope: String = "All")
    {
        filteredUser = allUsers.filter({ (user) -> Bool in
            return user.firstname.lowercased().contains(searchText.lowercased())
        })
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func loadUsers(filter: String)
    {
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
            self.allUserGroupped = [:]
            
            if error != nil
            {
                print(error!.localizedDescription)
                ProgressHUD.dismiss()
                self.tableView.reloadData()
                return
                
            }
            guard let snapshot = snapshot else {
                ProgressHUD.dismiss(); return
            }
            
            if !snapshot.isEmpty
            {
                for userDictionary in snapshot.documents {
                    let userDictionary = userDictionary.data() as NSDictionary
                    let fUser = FUser(_dictionary: userDictionary)
                    if fUser.objectId != FUser.currentId(){
                        self.allUsers.append(fUser)
                    }
                }
                
                //split to groups
                
                self.splitDataIntoSection()
                self.tableView.reloadData()
                
            }
            self.tableView.reloadData()
            ProgressHUD.dismiss()
            
        }
        
    }

    //MARK: Helper Functions
    
    fileprivate func splitDataIntoSection() {
        var sectionTitle: String = ""
        for i in 0..<self.allUsers.count {
            
            let currentUser = self.allUsers[i]
            let firstCharacter = currentUser.firstname.first!
            
            let firstCharacString = "\(firstCharacter)"
            if firstCharacString != sectionTitle {
                
                sectionTitle = firstCharacString
                self.allUserGroupped[sectionTitle] = []
                
                if !sectionTitleList.contains(sectionTitle){
                    self.sectionTitleList.append(sectionTitle)
                }
                
            }
            self.allUserGroupped[firstCharacString]!.append(currentUser)
            
        }
        
    }
    
    
    //MARK: UserTableViewCell Delegate
    func didTapAvatarImage(indexPath: IndexPath) {
        print("User Avatar Tapped at \(indexPath)")
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
        
        var user: FUser
        if searchController.isActive && searchController.searchBar.text != "" {
            
            user = filteredUser[indexPath.row]
        }else
        {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUserGroupped[sectionTitle]
            
            user = users![indexPath.row]
            
        }
        
        profileVC.user = user
        
        
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    

}
