//
//  GroupMemberCollectionViewCell.swift
//  Circle
//
//  Created by Kumar Rounak on 31/08/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit

protocol GroupMemberCollectionViewCellDelegate {
    func didClickDeleteButton(indexPath: IndexPath)
}

class GroupMemberCollectionViewCell: UICollectionViewCell {
    
    var indexPath : IndexPath!
    var delegate  : GroupMemberCollectionViewCellDelegate?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    func generateCell(user: FUser, indexPath: IndexPath){
        self.indexPath = indexPath
        nameLabel.text = user.firstname
        
        if user.avatar != "" {
            
            imageFromData(pictureData: user.avatar) { (avatarImage) in
                if avatarImage != nil {
                    
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
        
    }
    
    
    //MARK: IBAction
    
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        delegate!.didClickDeleteButton(indexPath: indexPath)
    }
    
    
}
