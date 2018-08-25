//
//  EditProfileTableViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 02/08/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class EditProfileTableViewController: UITableViewController, ImagePickerDelegate {
    

    
    @IBOutlet weak var saveButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var firstNametextField: UITextField!
    @IBOutlet weak var lastNametextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet var avtarImageTapgestureRecognizer: UITapGestureRecognizer!
    var avatarImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        setupUI()

    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 4
    }

    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    //MARK: IB Action
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        if firstNametextField.text != "" && lastNametextField.text != "" && emailTextField.text != "" {
            
            ProgressHUD.showSuccess("Saving")
            saveButtonOutlet.isEnabled = false
            let fullName = firstNametextField.text! + " " + lastNametextField.text!
            
            var withValues = [kFIRSTNAME:firstNametextField.text!,kLASTNAME:lastNametextField.text!,kFULLNAME:fullName]
            
            if avatarImage != nil {
                let avatarData = avatarImage!.jpegData(compressionQuality: 0.5)!
                let avatarString = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                
                withValues[kAVATAR] = avatarString
            }
            withValues[kEMAIL] = emailTextField.text!
            
            updateCurrentUserInFirestore(withValues: withValues) { (error) in
                
                if error != nil {
                    DispatchQueue.main.async {
                         ProgressHUD.showError(error!.localizedDescription)
                        print("Could'nt Update User")
                        print(error!.localizedDescription)
                    }
                   self.saveButtonOutlet.isEnabled = true
                   return
                }
                
                ProgressHUD.showSuccess("User Data Updated!")
                self.navigationController?.popViewController(animated: true)
                
            }
            
        }else
        {
            ProgressHUD.showError("All fields are required.")
        }
    }
    
    
    
    @IBAction func avatarTap(_ sender: Any) {
        
        print("show image Picker")
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1
        
        present(imagePickerController, animated: true, completion: nil)
        
        
    }
    //MARK: Setup UI
    
    func setupUI()
    {
        let currentUser = FUser.currentUser()!
        avatarImageView.isUserInteractionEnabled = true
        
        
        firstNametextField.text = currentUser.firstname
        lastNametextField.text = currentUser.lastname
        emailTextField.text = currentUser.email
        
        if currentUser.avatar != ""
        {
            imageFromData(pictureData: currentUser.avatar) { (image) in
                if image != nil {
                    self.avatarImageView.image = image!.circleMasked
                }
            }
        }
        
    }
    
    //MARK: ImagePicker Delegate
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        
        if images.count > 0 {
            self.avatarImage = images.first!
            self.avatarImageView.image = self.avatarImage!.circleMasked
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    

}
