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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func generateCellWith(call: CallClass){
        dateLabel.text = formatCallTime(date: call.callDate)
        statusLabel.text = ""
        if (call.callerId == FUser.currentId()) {
            
            statusLabel.text = "Outgoing Call"
            fullNameLabel.text = call.withUserFullName
            
           // avatarImageView.image = UIImage(named: "Outgoing")
        } else {
            
            statusLabel.text = "Incoming Call"
            fullNameLabel.text = call.callerFullName
           // avatarImageView.image = UIImage(named: "Incoming")
        }
        
    }
}
