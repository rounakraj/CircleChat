//
//  ChatViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 30/06/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import IDMPhotoBrowser
import AVFoundation
import AVKit
import FirebaseFirestore


class ChatViewController: JSQMessagesViewController {

    var chatRoomId: String!
    var memberIds: [String]!
    var membersToPush: [String]!
    
    var viewTitle: String!
    
    var maxMessagesNumber = 0
    var minMessagesNumber = 0
    var loadOld = false
    var loadedMessagesCount = 0
    
    let legitTypes = [kAUDIO, kVIDEO, kTEXT, kLOCATION, kPICTURE]
    
    
    var messages: [JSQMessage] = []
    var objectMessages: [NSDictionary] = []
    var loadedMessages: [NSDictionary] = []
    
    var allPictureMessages: [String] = []
    
    var initialLoadComplete = false
    
    
    var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    
    var incomingBubble = JSQMessagesBubbleImageFactory()?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    
    //Fixig for iPhone X
    override func viewDidLayoutSubviews() {
        perform(Selector("jsq_updateCollectionViewInsets"))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backAction))]
        
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        loadMessages()
        
        self.senderId = FUser.currentId()
        self.senderDisplayName = FUser.currentUser()!.firstname
        
        //Fixig for iPhone X
        let constraint = perform(Selector(("toolbarBottomLayoutGuide")))?.takeUnretainedValue() as! NSLayoutConstraint
        
        constraint.priority = UILayoutPriority(rawValue: 1000)
        
        
        self.inputToolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        
        
        //End of iPhoneX Fix
        
        
        
        //Custom Send Button
        
        self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
        
        

       
    }
    
    //MARK: JSQMessages DataSource Functions
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let data = messages[indexPath.row]
        
        
        //set text color
        if data.senderId == FUser.currentId() {
            cell.textView.textColor = .white
            
        } else {
            cell.textView.textColor = .black
            
        }
        
        return cell
        
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        
        return messages[indexPath.row]
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let data = messages[indexPath.row]
        
        if data.senderId == FUser.currentId(){
            return outgoingBubble
        } else {
            return incomingBubble
        }
    }
    
    //MARK: JSQMessages Delegate Functions
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        
        print("accessory pressed")
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            
            print("Camera")
            
        }
        
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            
            print("Photo Library")
            
        }
        
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            
            print("Video Library")
            
        }
        
        let shareLocation = UIAlertAction(title: "Location", style: .default) { (action) in
            
            print("Location")
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        sharePhoto.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        optionMenu.addAction(takePhotoOrVideo)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(shareVideo)
        optionMenu.addAction(shareLocation)
        optionMenu.addAction(cancelAction)
        
        
        //Options Menu on iPad
        if (UI_USER_INTERFACE_IDIOM() == .pad)
        {
            
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController{
                
                currentPopoverpresentioncontroller.sourceView = self.inputToolbar.contentView.leftBarButtonItem
                currentPopoverpresentioncontroller.sourceRect = self.inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                self.present(optionMenu,animated: true, completion: nil)
            }
        }else {
            self.present(optionMenu,animated: true, completion: nil)
            
        }
        
        
        
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        print("send")
        
        
        if text != ""
        {
            
            print(text!)
            self.sendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
            
            updateSendButton(isSend: false)
            
            
            
        } else {
            
            //Audio Message
        }
        
        
        
    }
    
    //MARK: Send Messages
    
    func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?)
    {
        var outgoingMessage: OutgoingMessages?
        
        let currentUser = FUser.currentUser()!
        
        //text messsage
        
        if let text = text {
            
            outgoingMessage = OutgoingMessages(message: text, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kTEXT )
        }
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        outgoingMessage!.sendMessage(chatRoomId: chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: memberIds, membersToPush: membersToPush)
        
        
    }
    
    
    //MARK: Load Messages
    
    func loadMessages()
    {
        //get last 11 messages
        
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
            
            guard let snapshot = snapshot else {
               //Initial Loading is DOne
                
                self.initialLoadComplete = true
                
                //listen for new chat
                return
                
            }
            
            let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            
            //remove bad messages
            self.loadedMessages = self.removeBadMessages(allMessages: sorted)
            //insert messages
            self.insertMessages()
            self.finishReceivingMessage(animated: true)
            
            
            self.initialLoadComplete = true
            
            print("We have \(self.messages.count) messages loaded")
            
            //Get Picture messages
            
            //Get Old messages in background
            
            //start listening for new messages
            
            
            
        }
        
    }
    
    
    //MARK: Insert Messages
    
    func insertMessages() {
        maxMessagesNumber = loadedMessages.count - loadedMessagesCount
        minMessagesNumber = maxMessagesNumber - kNUMBEROFMESSAGES
        
        if minMessagesNumber < 0 {
            minMessagesNumber = 0
        }
        
        for i in minMessagesNumber ..< maxMessagesNumber {
            let messageDictionary = loadedMessages[i]
            
            //insert message
            insertInitialLoadMessage(messageDictionary: messageDictionary)
            
            
            loadedMessagesCount += 1
            
        }
        
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    
    
    func insertInitialLoadMessage(messageDictionary: NSDictionary) -> Bool {
        
        
        let incomingMessage = IncomingMessages(collectionView_: self.collectionView!)
        //Check if incoming
        
        if (messageDictionary[kSENDERID] as! String) != FUser.currentId() {
            //update message status
            
        }
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        
        if message != nil
        {
            objectMessages.append(messageDictionary)
            messages.append(message!)
        }
        
        return isIncoming(messageDictionary: messageDictionary)
        
    }
    
    //MARK: IBActions
    
    @objc func backAction()
    {
        self.navigationController?.popViewController(animated: true)
        
    }
    

    //MARK: CustomSendButton
    
    override func textViewDidChange(_ textView: UITextView) {
        
        if textView.text != ""
        {
            updateSendButton(isSend: true)
        } else{
            updateSendButton(isSend: false)
        }
    }
    
    
    func updateSendButton(isSend: Bool)
    {
        if isSend{
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
            
        } else {
            
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        }
    }
    
    
    //Helper Function
    
    func removeBadMessages(allMessages: [NSDictionary]) -> [NSDictionary]{
        var tempMessages = allMessages
        
        for message in tempMessages {
            if message[kTYPE] != nil {
                if !self.legitTypes.contains(message[kTYPE] as! String) {
                    
                    //remove the message
                    tempMessages.remove(at: tempMessages.index(of: message)!)
                }
                
            } else
            {
                //remove the message
                tempMessages.remove(at: tempMessages.index(of: message)!)
            }
        }
        return tempMessages
    }
    
    func isIncoming(messageDictionary: NSDictionary) -> Bool {
        if FUser.currentId() == messageDictionary[kSENDERID] as! String {
            return false
        } else {
            return true
        }
    }
}
