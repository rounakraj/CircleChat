//
//  BackgroundCollectionViewCell.swift
//  Circle
//
//  Created by Kumar Rounak on 02/08/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit

class BackgroundCollectionViewCell: UICollectionViewCell {
    

    @IBOutlet weak var imageView: UIImageView!
    
    func generateCell(image: UIImage) {
        
        self.imageView.image = image
    }
    

}
