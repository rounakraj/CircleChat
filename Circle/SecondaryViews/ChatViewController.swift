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


class ChatViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var chatRoomId: String!
    var memberIds: [String]!
    var membersToPush: [String]!
    
    var viewTitle: String!
    
    var isGroup: Bool?
    var group: NSDictionary?
    
    var withUsers: [FUser] = []
    
    
    
    var maxMessagesNumber = 0
    var minMessagesNumber = 0
    var loadOld = false
    var loadedMessagesCount = 0
    
    var typingListener: ListenerRegistration?
    var updatedChatListener: ListenerRegistration?
    var newChatListener: ListenerRegistration?
    
    
    
    
    let legitTypes = [kAUDIO, kVIDEO, kTEXT, kLOCATION, kPICTURE]
    
    
    var messages: [JSQMessage] = []
    var objectMessages: [NSDictionary] = []
    var loadedMessages: [NSDictionary] = []
    
    var allPictureMessages: [String] = []
    
    var initialLoadComplete = false
    
    
    var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    
    var incomingBubble = JSQMessagesBubbleImageFactory()?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    
    //MARK: Custom Chat Header
    
    let leftBarButtonView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        return view
    }()
    
    let avatarButton: UIButton = {
        let button = UIButton(frame:CGRect(x: 0, y: 10, width: 25, height: 25))
        return button
        
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel(frame:CGRect(x: 30, y: 10, width: 140, height: 15))
        label.textAlignment = .left
        label.font = UIFont(name: label.font.fontName, size: 14)
        return label
    }()
    
    let subTitle: UILabel = {
        let subTitle = UILabel(frame:CGRect(x: 30, y: 25, width: 140, height: 15))
        subTitle.textAlignment = .left
        subTitle.font = UIFont(name: subTitle.font.fontName, size: 10)
        return subTitle
    }()
    
    
    
    
    
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
        
        setCustomTitle()
        
        
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
        if (data.text != nil) {
            
            if data.senderId == FUser.currentId() {
                
                cell.textView.textColor = .white
                
            } else {
                cell.textView.textColor = .black
                
            }
            
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
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        if indexPath.item % 3 == 0
        {
            let message = messages[indexPath.row]
            return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
            
        }
        return nil
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        
        if indexPath.item % 3 == 0
        {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
            
        }
        
        return 0.0
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        let message = objectMessages[indexPath.row]
        let status: NSAttributedString!
        
        let attributedStringColor = [NSAttributedString.Key.foregroundColor : UIColor.darkGray]
        
        
        switch message[kSTATUS] as! String {
        case kDELIVERED:
            let deliveredText = "Delivered"
            status = NSAttributedString(string: deliveredText)
        case kREAD:
            let statusText = "Read" + " " + readTimeFrom(dateString: message[kREADDATE] as! String)
            status = NSAttributedString(string: statusText, attributes: attributedStringColor)
        default:
            status = NSAttributedString(string: "✔︎" )
        }
        
        return status
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        
        let data = messages[indexPath.row]
        
        if data.senderId == FUser.currentId()
        {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
            
        }else
        {
            return 0.0
        }
    }
    
    //MARK: JSQMessages Delegate Functions
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        
        print("accessory pressed")
        
        let camera = Camera(delegate_: self)
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            
            print("Camera")
            camera.PresentMultyCamera(target: self, canEdit: true)
            
        }
        
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            
            print("Photo Library")
            
            camera.PresentPhotoLibrary(target: self, canEdit: true)
            
        }
        
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            
            print("Video Library")
            camera.PresentVideoLibrary(target: self, canEdit: true)
            
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
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        
        //Load More Messages
        self.loadMoreMessages(maxNumber: maxMessagesNumber, minNumber: minMessagesNumber)
        
        self.collectionView.reloadData()
        
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
        
        
        //picture message
        
        if let pic = picture {
            
            uploadImage(image: pic, chatRoomId: chatRoomId, view: self.navigationController!.view) { (imageLink) in
                
                if imageLink != nil {
                    
                    let text = "[\(kPICTURE)]"

                    
                    outgoingMessage = OutgoingMessages(message: text, pictureLink: imageLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kPICTURE)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    print("Picture Sent Sound Played")
                    self.finishSendingMessage()
                    print("Picture Seding Finished")
                    outgoingMessage!.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
                    print("Picture Uploaded and Saved")
                    
                }
            }
            return
            
        }
        
        //video message
        
        if let video = video {
            
            let videoData = NSData(contentsOfFile: video.path!)
            let dataThumbNail = videoThumbNail(video: video).jpegData(compressionQuality: 0.4)
            
            uploadVideo(video: videoData!, chatRoomId: chatRoomId, view: self.navigationController!.view) { (videoLink) in
                if videoLink != nil {
                    
                    let text = "[\(kVIDEO)]"
                    
                    outgoingMessage = OutgoingMessages(message: text, video: videoLink!, thumbNail: dataThumbNail! as NSData,senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kVIDEO)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    outgoingMessage!.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
                    
                }
                print("Video Message Sent\n")
                
            }
            return
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
            self.getOldMessagesInBackground()
            
            
            //start listening for new messages
            self.listenForNewChats()
            
            
            
            
        }
        
    }
    
    func listenForNewChats()
    {
        var lastMessageDate = "0"
        if loadedMessages.count > 0 {
            lastMessageDate = loadedMessages.last![kDATE] as! String
            
        }
        
        newChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty {
                for diff in snapshot.documentChanges {
                    
                    if diff.type == .added {
                        let item = diff.document.data() as NSDictionary
                        
                        if let type = item[kTYPE] {
                            
                            if self.legitTypes.contains(type as! String) {
                                
                                //Picture Messages
                                if type as! String == kPICTURE {
                                    //add to pictures
                                }
                                
                                if self.insertInitialLoadMessage(messageDictionary: item)
                                {
                                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                    
                                }
                                self.finishReceivingMessage()
                            }
                        }
                    }
                }
            }
        })
        
        
    }
    
    func getOldMessagesInBackground() {
        
        if loadedMessages.count > 10 {
            let firstMessageDate = loadedMessages.first![kDATE] as! String
            reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: firstMessageDate).getDocuments { (snapshot, error) in
                guard let snapshot = snapshot else { return }
                
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                
                self.loadedMessages = self.removeBadMessages(allMessages: sorted) + self.loadedMessages
                
                //Picture Messages Fetch
                
                self.maxMessagesNumber = self.loadedMessages.count - self.loadedMessagesCount - 1
                self.minMessagesNumber = self.maxMessagesNumber - kNUMBEROFMESSAGES
                
                
            }
            
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
    
    
    
    //MARK: Load More Messages
    
    func loadMoreMessages(maxNumber: Int, minNumber: Int)
    {
        if loadOld {
            maxMessagesNumber = minNumber - 1
            minMessagesNumber = maxMessagesNumber - kNUMBEROFMESSAGES
        }
        
        if minMessagesNumber < 0
        {
            minMessagesNumber = 0
        }
        
        for i in (minMessagesNumber ... maxMessagesNumber).reversed() {
            
            let messageDictionary = loadedMessages[i]
            insertNewMessage(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
            
            
        }
        loadOld = true
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    
    func insertNewMessage(messageDictionary: NSDictionary){
        
        let incomingMessage = IncomingMessages(collectionView_: self.collectionView!)
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        objectMessages.insert(messageDictionary, at: 0)
        messages.insert(message!, at: 0)
        
    }
    //MARK: IBActions
    
    @objc func backAction()
    {
        self.navigationController?.popViewController(animated: true)
        
    }
    
    
    @objc func infoButtonPressed()
    {
        
    }
    
    @objc func showGroup()
    {
        
    }
    
    
    @objc func showUserProfile()
    {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
        
        profileVC.user = withUsers.first!
        self.navigationController?.pushViewController(profileVC, animated: true)
        
        
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
    
    
    
    //MARK: UIIMAGEPickerController Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        sendMessage(text: nil, date: Date(), picture: image, location: nil, video: video, audio: nil)
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    
    
    
    
    //MARK: Helper Function
    
    
    
    //MARK: UpdateUI
    func setCustomTitle()
    {
        leftBarButtonView.addSubview(avatarButton)
        leftBarButtonView.addSubview(titleLabel)
        leftBarButtonView.addSubview(subTitle)
        
        
        let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.infoButtonPressed))
        
        self.navigationItem.rightBarButtonItem = infoButton
        
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
        self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
        if (isGroup!)
        {
            avatarButton.addTarget(self, action: #selector(self.showGroup), for: .touchUpInside)
        } else {
            
             avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
        }
        
        getUsersFromFirestore(withIds: memberIds) { (withUsers) in
            
            self.withUsers = withUsers
            //get avatars
            
            if !self.isGroup! {
                //update user info
                self.setUIForSingleChat()
            }
        }
        
    }
    
    
    func setUIForSingleChat() {
        
        let withUser = withUsers.first!
        imageFromData(pictureData: withUser.avatar) { (image) in
            
            if image != nil {
                avatarButton.setImage(image!.circleMasked, for: .normal)
                
            }
            
       }
       titleLabel.text = withUser.fullname
        if withUser.isOnline {
            subTitle.text = "Online"
        } else {
            subTitle.text = "Offline"
        }
        
        avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
    }
    
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
    
    func readTimeFrom(dateString: String) -> String {
        let date = dateFormatter().date(from: dateString)
        let currentDateFormat = dateFormatter()
        currentDateFormat.dateFormat = "HH:MM"
        return currentDateFormat.string(from: date!)
    }
}
