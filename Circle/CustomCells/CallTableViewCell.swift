//
//  CallTableViewCell.swift
//  Circle
//
//  Created by Kumar Rounak on 01/09/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit

class CallTableViewCell: UITableViewCell {

    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var callDirectionImageOutlet: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        
        print("Call Cell is Selected")
        
    }
    
    func generateCellWith(call: CallClass){
        dateLabel.text = formatCallTime(date: call.callDate)
        statusLabel.text = ""
        if FUser.currentUser()!.avatar != ""
        {
            imageFromData(pictureData: FUser.currentUser()!.avatar) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
                
            }
        }
        if (call.callerId == FUser.currentId()) {
            
            statusLabel.text = "Outgoing Call"
            fullNameLabel.text = call.withUserFullName
            
            callDirectionImageOutlet.image = UIImage(named: "outgoing")
        } else {
            
            statusLabel.text = "Incoming Call"
            fullNameLabel.text = call.callerFullName
            callDirectionImageOutlet.image = UIImage(named: "incoming")
        }
        
    }
    
    
    
}
