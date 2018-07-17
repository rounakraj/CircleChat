//
//  PictureCollectionViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 17/07/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import IDMPhotoBrowser


class PictureCollectionViewController: UICollectionViewController {

    
    var allImages: [UIImage] = []
    var allImagesLink: [String] = []
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Media Shared"
        
        if allImagesLink.count > 0 {
            //download Image
            downloadImages()
            
        }
        

    }

    

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return allImages.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PictureCollectionViewCell
    
        // Configure the cell
       cell.generateCell(image: allImages[indexPath.row])
       return cell
    }
    
    
    //MARK: UICollectionview Delegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let photos = IDMPhoto.photos(withImages: allImages)
        let browser = IDMPhotoBrowser(photos: photos)
        browser?.displayDoneButton = false
        browser?.setInitialPageIndex(UInt(indexPath.row))
        
        self.present(browser!, animated: true, completion: nil)
        
    }
    //MARK: Download Images
    
    func downloadImages() {
        
        for imageLink in allImagesLink {
            downloadImage(imageUrl: imageLink) { (image) in
                
                if image != nil {
                    self.allImages.append(image!)
                    self.collectionView.reloadData()
                }
            }
        }
    }

}
