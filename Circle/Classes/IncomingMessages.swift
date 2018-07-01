//
//  IncomingMessages.swift
//  Circle
//
//  Created by Kumar Rounak on 01/07/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class IncomingMessages {
    
    var collectionView: JSQMessagesCollectionView
    
    init(collectionView_: JSQMessagesCollectionView) {
        collectionView = collectionView_
        
    }
    
    //MARK: Create Message
    
    func  createMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage? {
        
        
        var message: JSQMessage?
        let type = messageDictionary[kTYPE] as! String
        
        switch type{
        case kTEXT:
            //create text message
            print("create text message")
            message = createTextMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
            
        case kPICTURE:
            //create picture message
            print("create picture message")
        case kVIDEO:
            //create video message
            print("create video message")
        case kAUDIO:
            //create audio message
            print("create audio message")
        case kLOCATION:
            //create location text
            print("create location message")
        default:
            print("Unknown message type")
        }
        
        if message != nil {
            return message!
        }
        
        return nil
    }
    
    
    //MARK: Create Message Type
    
    func createTextMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        var date: Date!
        
        if let created = messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
                
            }else {
                date = dateFormatter().date(from: created as! String)
            }
        }else {
            date = Date()
        }
        
        let text = messageDictionary[kMESSAGE] as! String
        
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, text: text)
        
    }
    
}
