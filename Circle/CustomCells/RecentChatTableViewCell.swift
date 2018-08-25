//
//  RecentChatTableViewCell.swift
//  Circle
//
//  Created by Kumar Rounak on 28/06/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit

protocol RecentChatTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}

class RecentChatTableViewCell: UITableViewCell {

    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameTextLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageCounterLabel: UILabel!
    @IBOutlet weak var messageCounterBackground: UIView!
    
    
    var indexPath: IndexPath!
    let tapGestureRecognizer = UITapGestureRecognizer()
    var delegate: RecentChatTableViewCellDelegate?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        messageCounterBackground.layer.cornerRadius = messageCounterBackground.frame.width / 2
        tapGestureRecognizer.addTarget(self, action: #selector(self.avatarTap))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGestureRecognizer)
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    //MARK: Generate Cell
    
    func generateCell(recentChat: NSDictionary, indexPath: IndexPath)
    {
        self.indexPath = indexPath
        self.fullNameTextLabel.text = recentChat[kWITHUSERFULLNAME] as? String
        
        let decryptedText = Encryption.decryptText(chatRoomId: recentChat[kCHATROOMID] as! String, encryptedMessage: recentChat[kLASTMESSAGE] as! String)
        self.lastMessageLabel.text = decryptedText
        self.messageCounterLabel.text = recentChat[kCOUNTER] as? String
        
        
        
        if let avatarString = recentChat[kAVATAR] {
            imageFromData(pictureData: avatarString as! String) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                    
                }
            }
        }
        
        if recentChat[kCOUNTER] as! Int != 0 {
            self.messageCounterLabel.text = "\(recentChat[kCOUNTER] as! Int)"
            self.messageCounterBackground.isHidden = false
            self.messageCounterLabel.isHidden = false
        } else {
            
            self.messageCounterBackground.isHidden = true
            self.messageCounterLabel.isHidden = true
        }
        
        var date: Date!
        if let created = recentChat[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
                
            }
            else
            {
                date = dateFormatter().date(from: created as! String)
            }
        }else
        {
            date = Date()
            
        }
        
        self.dateLabel.text = timeElapsed(date: date)
    }
    
    
    @objc func avatarTap()
    {
        print("avatar tap at \(String(describing: indexPath))")
        delegate!.didTapAvatarImage(indexPath: indexPath)
    }

}
