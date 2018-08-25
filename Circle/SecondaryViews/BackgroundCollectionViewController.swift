//
//  BackgroundCollectionViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 02/08/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import ProgressHUD

private let reuseIdentifier = "cell"

class BackgroundCollectionViewController: UICollectionViewController {

    var backgrounds: [UIImage] = []
    let userDefaults = UserDefaults.standard
    
    
    
    private let imageNamesArray =  ["bg0", "bg1", "bg2", "bg3", "bg4", "bg5", "bg6", "bg7", "bg8", "bg9", "bg10", "bg11"]
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.largeTitleDisplayMode = .never
        
        let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(self.resetToDefault))
        
        self.navigationItem.rightBarButtonItem = resetButton
        setupImageArray()

       
    }

  
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return backgrounds.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BackgroundCollectionViewCell
    
        // Configure the cell
        
        cell.generateCell(image: backgrounds[indexPath.row])
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        userDefaults.set(imageNamesArray[indexPath.row], forKey: kBACKGROUBNDIMAGE)
        userDefaults.synchronize()
        ProgressHUD.showSuccess("Background Changed!")
        
    }
    
    
    //MARK: Load Image
    
    func setupImageArray()
    {
        for imageName in imageNamesArray {
            let image = UIImage(named: imageName)
            if image != nil {
                
                backgrounds.append(image!)
                
            }
        }
    }
    
    @objc func resetToDefault() {
        
        userDefaults.removeObject(forKey: kBACKGROUBNDIMAGE)
        userDefaults.synchronize()
        ProgressHUD.showSuccess("Reset Succesfull!")
    }

}
