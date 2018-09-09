//
//  CallTableViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 01/09/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import ProgressHUD
import FirebaseFirestore

class CallTableViewController: UITableViewController, UISearchResultsUpdating {
    
    var allCalls: [CallClass] = []
    var filteredCalls: [CallClass] = []
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let searchController = UISearchController(searchResultsController: nil)
    var callListener: ListenerRegistration!
    
    override func viewWillAppear(_ animated: Bool) {
        loadCalls()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        callListener.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBadges(controller: self.tabBarController!)
        
        tableView.tableFooterView = UIView()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
    }
    
    //MARK: TableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredCalls.count
        }
        return allCalls.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CallTableViewCell
        
        var call: CallClass!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            call = filteredCalls[indexPath.row]
        } else {
            call = allCalls[indexPath.row]
        }
        
        cell.generateCellWith(call: call)
        
        return cell
    }
    
    
    //MARK: TableViewDelegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            var tempCall: CallClass!
            
            if searchController.isActive && searchController.searchBar.text != "" {
                tempCall = filteredCalls[indexPath.row]
                filteredCalls.remove(at: indexPath.row)
            } else {
                tempCall = allCalls[indexPath.row]
                allCalls.remove(at: indexPath.row)
            }
            
            tempCall.deleteCall()
            tableView.reloadData()
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let userToCall = allCalls[indexPath.row]
        print("Caller Object Id")
        print(userToCall.callerId)
        print(userToCall.callerFullName)
        
        
        
       //////////////////
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let sendVideo = UIAlertAction(title: "Video Call", style: .default) { (action) in
            
            print("Video Call")
            self.callUserVideo(userId: userToCall.callerId)
            let currentUser = FUser.currentUser()!
            let call = CallClass(_callerId: currentUser.objectId, _withUserId: userToCall.callerId, _callerFullName: currentUser.fullname, _withUserFullName: userToCall.callerFullName)
            call.saveCallInBackground()
            
        }
        
        let sendAudio = UIAlertAction(title: "Audio Call", style: .default) { (action) in
            
            print("Audio Call")
            self.callUser(userId: userToCall.callerId)
            let currentUser = FUser.currentUser()!
            let call = CallClass(_callerId: currentUser.objectId, _withUserId: userToCall.callerId, _callerFullName: currentUser.fullname, _withUserFullName: userToCall.callerFullName)
            call.saveCallInBackground()
            
            
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        
        sendVideo.setValue(UIImage(named: "videocall"), forKey: "image")
        sendAudio.setValue(UIImage(named: "optionCall"), forKey: "image")
        
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
    
    //MARK: LoadCalls
    
    func loadCalls() {
        
        callListener = reference(.Call).document(FUser.currentId()).collection(FUser.currentId()).order(by: kDATE, descending: true).limit(to: 20).addSnapshotListener({ (snapshot, error) in
            
            self.allCalls = []
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                
                let sortedDictionary = dictionaryFromSnapshots(snapshots: snapshot.documents)
                
                for callDictionary in sortedDictionary {
                    let call = CallClass(_dictionary: callDictionary)
                    self.allCalls.append(call)
                }
                
            }
            self.tableView.reloadData()
        })
    }
    
    
    //MARK: Search controller
    
    func filteredContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredCalls = allCalls.filter({ (call) -> Bool in
            
            var callerName: String!
            
            if call.callerId == FUser.currentId() {
                callerName = call.withUserFullName
            } else {
                callerName = call.callerFullName
            }
            
            return (callerName).lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func callClient() -> SINCallClient {
        
        return appDelegate._client.call()
    }
    func callUser(userId: String) {
        let userToCall = userId
        let call = callClient().callUser(withId: userToCall)
        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallVC") as! CallViewController
        
        callVC._call = call
        self.present(callVC, animated: true, completion: nil)
    }
    
    
    func callUserVideo(userId: String) {
        let userToCall = userId
        let call = callClient().callUserVideo(withId: userToCall)
        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoVC") as! VideoCallViewController
        callVC._call = call
        self.present(callVC, animated: true, completion: nil)
    }
    
    
}
