//
//  Recents.swift
//  Circle
//
//  Created by Kumar Rounak on 27/06/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import Foundation

func startPrivateChat(user1: FUser, user2: FUser) -> String {
    
    let userId1 = user1.objectId
    let userId2 = user2.objectId
    
    var chatRoomId = ""
    
    let value = userId1.compare(userId2).rawValue
    
    if value < 0{
        chatRoomId = userId1 + userId2
    }else {
        chatRoomId = userId2 + userId1
    }
    
    let members = [userId1, userId2]
    
    
    //create recents chats
    createRecentsChat(members: members, chatRoomId: chatRoomId, withUserName: "", type: kPRIVATE, users: [user1,user2], avatarOfGroup: nil)
    
    return chatRoomId
    
}



func createRecentsChat(members: [String], chatRoomId: String, withUserName: String, type: String, users: [FUser]?, avatarOfGroup: String?)
{
    
    var tempMembers = members
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        
        guard let snapshot = snapshot else {
            
            return
        }
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let currentRecent = recent.data() as NSDictionary
                
                if let currentUserId = currentRecent[kUSERID]
                {
                    if tempMembers.contains(currentUserId as! String){
                        tempMembers.remove(at: tempMembers.index(of: currentUserId as! String)!)
                    }
                }
            }
        }
        for userId in tempMembers {
            //create recent items
           createRecentItem(userId: userId, chatRoomId: chatRoomId, members: members, withUserName: withUserName, type: type, users: users, avatarOfGroup: avatarOfGroup)
            
        }
    }
    
}


func createRecentItem(userId: String, chatRoomId: String, members: [String], withUserName: String, type: String, users: [FUser]?, avatarOfGroup: String?){
    
    let localReference = reference(.Recent).document()
    let recentId = localReference.documentID
    
    let date = dateFormatter().string(from: Date())
    
    var recent: [String: Any]!
    
    if type == kPRIVATE
    {
        //private
        
        var withUser: FUser?
        
        if users != nil && users!.count > 0 {
            if userId == FUser.currentId() {
                //for current user
                
                withUser = users!.last!
            } else {
                
                withUser = users!.first!
            }
            
        }
        
        recent = [kRECENTID: recentId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERFULLNAME: withUser!.fullname, kWITHUSERUSERID: withUser!.objectId, kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: withUser!.avatar] as [String: Any]
        
        
    } else {
        
        //Group Chat
        
        
        if avatarOfGroup != nil {
            recent = [kRECENTID: recentId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERFULLNAME: withUserName,  kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: avatarOfGroup!] as [String: Any]
            
        }
        
    }
    
    //save recent chat
    
    localReference.setData(recent)
    
    
    
    
}


//Restart Chat


func restartRecenChat(recent: NSDictionary){
    
    if recent[kTYPE] as? String == kPRIVATE {
        createRecentsChat(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserName: FUser.currentUser()!.firstname, type: kPRIVATE, users: [FUser.currentUser()!], avatarOfGroup: nil)
        
        
    }
    
    if recent[kTYPE] as? String == kGROUP{
        
        createRecentsChat(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserName: recent[kWITHUSERFULLNAME] as! String, type: kGROUP, users: nil, avatarOfGroup: recent[kAVATAR] as? String)
    }
}

//Update Recent


func updateRecents(chatRoomId: String, lastMessage: String) {
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            
            for recent in snapshot.documents {
                
                let currentRecent = recent.data() as NSDictionary
                updateRecentItems(recent: currentRecent, lastMessage: lastMessage)
            }
        }
    }
}


func updateRecentItems(recent: NSDictionary, lastMessage: String) {
    
    
    let date = dateFormatter().string(from: Date())
    var counter = recent[kCOUNTER] as! Int
    
    if recent[kUSERID] as? String != FUser.currentId() {
        counter += 1
        
    }
    
    let values = [kLASTMESSAGE : lastMessage, kCOUNTER : counter, kDATE : date] as [String : Any]
    reference(.Recent).document(recent[kRECENTID] as! String).updateData(values)
}







//Delete Chat

func deleteRecentChat(recentChatDictionary: NSDictionary){
    if let recentId = recentChatDictionary[kRECENTID]{
        reference(.Recent).document(recentId as! String).delete()
    }
}

//Clear Counter
func clearRecentCounter(chatRoomId: String) {
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            
            for recent in snapshot.documents {
                
                let currentRecent = recent.data() as NSDictionary
                if currentRecent[kUSERID] as? String == FUser.currentId() {
                    clearRecentCounterItems(recent: currentRecent)
                    
                }
            }
        }
    }
}

func clearRecentCounterItems(recent: NSDictionary){
    
    print("Clear Recent Counter")
    reference(.Recent).document(recent[kRECENTID] as! String).updateData([kCOUNTER : 0])
}



//group

func startGroupChat(group: Group) {
    
    let chatRoomId = group.groupDictionary[kGROUPID] as! String
    let members = group.groupDictionary[kMEMBERS] as! [String]
    
    createRecentsChat(members: members, chatRoomId: chatRoomId, withUserName: group.groupDictionary[kNAME] as! String, type: kGROUP, users: nil, avatarOfGroup: group.groupDictionary[kAVATAR] as? String)
}

func createRecentsForNewMembers(groupId: String, groupName: String, membersToPush: [String], avatar: String) {
    
    createRecentsChat(members: membersToPush, chatRoomId: groupId, withUserName: groupName, type: kGROUP, users: nil, avatarOfGroup: avatar)
}




//Update Recents in Firebase

func updateExistingRecentWithNewValues(chatRoomId: String, members: [String], withValues: [String : Any])
{
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        
        guard let snapshot = snapshot else { return }
        if !snapshot.isEmpty {
            
            for recent in snapshot.documents {
                let recent = recent.data() as NSDictionary
                updateRecent(recentId: recent[kRECENTID] as! String, values: withValues)
            }
        }
    }
    
    
}


func updateRecent(recentId: String, values: [String : Any]) {
    
    reference(.Recent).document(recentId).updateData(values)
    
}

//Block User

func blcockUser(userToBlock: FUser) {
    
    
    let userId1 = FUser.currentId()
    let userId2 = userToBlock.objectId
    
    var chatRoomId = ""
    
    let value = userId1.compare(userId2).rawValue
    
    if value < 0{
        chatRoomId = userId1 + userId2
    }else {
        chatRoomId = userId2 + userId1
    }
    
    getRecentsFor(chatRoomId: chatRoomId)
    
    
}

func getRecentsFor(chatRoomId: String) {
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        
        guard let snapshot = snapshot else { return }
        if !snapshot.isEmpty {
            
            for recent in snapshot.documents {
                let recent = recent.data() as NSDictionary
                deleteRecentChat(recentChatDictionary: recent)
            }
        }
    }
    
    
}

