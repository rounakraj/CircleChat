//
//  UserTableViewCell.swift
//  Circle
//
//  Created by Kumar Rounak on 26/06/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit



protocol UserTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}


class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var fullNameLabel: UILabel!
    
    var indexPath: IndexPath!
    let tapGestureRecognizer = UITapGestureRecognizer()
    var delegate: UserTableViewCellDelegate?
    
    
    override func awakeFromNib() {
        
        //ViewDidLoad for Cell
        super.awakeFromNib()
        
        tapGestureRecognizer.addTarget(self, action: #selector(self.avatarTap))
        // Initialization code
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGestureRecognizer)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    //MARK: Functions
    
    func generateUserCell(fUser: FUser, indexPath: IndexPath)
    {
        self.indexPath = indexPath
        self.fullNameLabel.text = fUser.fullname
        if fUser.avatar != ""
        {
            imageFromData(pictureData: fUser.avatar) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
                
            }
        }
    }
    
    
    //MARK: Helpers
    
    @objc func avatarTap(){
        
        print("avatar tap at \(String(describing: indexPath))")
        delegate!.didTapAvatarImage(indexPath: indexPath)
        
    }

}
