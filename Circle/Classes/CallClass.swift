//
//  CallClass.swift
//  Circle
//
//  Created by Kumar Rounak on 01/09/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import Foundation

class CallClass {
    
    var objectID: String
    var callerId: String
    var callerFullName: String
    var withUserFullName: String
    var withUserId: String
    var status: String
    var isIncoming: Bool
    var callDate: Date
    
    
    init(_callerId: String , _withUserId: String, _callerFullName: String, _withUserFullName: String){
        
       objectID = UUID().uuidString
       callerId = _callerId
       callerFullName = _callerFullName
       withUserFullName = _withUserFullName
       withUserId = _withUserId
       status = ""
       isIncoming = false
       callDate = Date()
        
        
    }
    
    init(_dictionary: NSDictionary){
        
        objectID = _dictionary[kOBJECTID] as! String
        
        if let callId = _dictionary[kCALLERID] {
            callerId = callId as! String
        } else {
            callerId = ""
        }
        if let withId = _dictionary[kWITHUSERUSERID] {
            withUserId = withId as! String
        } else {
            withUserId = ""
        }
        if let callFName = _dictionary[kCALLERFULLNAME] {
            callerFullName = callFName as! String
        } else {
            callerFullName = "Unknown User"
        }
        if let withUserFName = _dictionary[kWITHUSERFULLNAME] {
            withUserFullName = withUserFName as! String
        } else {
            withUserFullName = "Unknown User"
        }
        if let callStatus = _dictionary[kCALLSTATUS] {
            status = callStatus as! String
        } else {
            status = "Unknown"
        }
        if let incoming = _dictionary[kISINCOMING] {
            isIncoming = incoming as! Bool
        } else {
            isIncoming = false
        }
        
        if let date = _dictionary[kDATE] {
            if (date as! String).count != 14 {
                callDate = Date()
            } else {
                callDate = dateFormatter().date(from: date as! String)!
            }
        } else {
            callDate = Date()
        }
    }
    
    func dictionaryFromCall() -> NSDictionary {
        
        let dateString = dateFormatter().string(from: callDate)
        return NSDictionary(objects: [objectID,callerId,callerFullName,withUserId,withUserFullName,status,isIncoming,dateString], forKeys: [kOBJECTID as NSCopying, kCALLERID as NSCopying, kCALLERFULLNAME as NSCopying, kWITHUSERUSERID as NSCopying, kWITHUSERFULLNAME as NSCopying, kSTATUS as NSCopying, kISINCOMING as NSCopying, kDATE as NSCopying])
    }
    
    //MARK: SAVE
    func saveCallInBackground() {
        
    
        reference(.Call).document(callerId).collection(callerId).document(objectID).setData(dictionaryFromCall() as! [String : Any])
        reference(.Call).document(withUserId).collection(withUserId).document(objectID).setData(dictionaryFromCall() as! [String : Any])
        
    }
    
    
    //MARK: Delete
    
    func deleteCall() {
        
        reference(.Call).document(FUser.currentId()).collection(FUser.currentId()).document(objectID).delete()
        
    }
    
    
    
}
