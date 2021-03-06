//
//  RegisterViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 25/06/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker


class RegisterViewController: UIViewController, ImagePickerDelegate {
    

    var avatarImage: UIImage?
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var phoneTextField: UITextField!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    
    @IBOutlet weak var surnameTextField: UITextField!
    
    @IBOutlet weak var countryTextField: UITextField!
    
    @IBOutlet weak var cityTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avatarImageView.isUserInteractionEnabled = true

        // Do any additional setup after loading the view.
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        if self.isMovingFromParent {
            dismissKeyboard()
            cleanTextFields()
            
        }
        
    }
    
    func backViewController() -> UIViewController? {
        let numberOfViewControllers = self.navigationController!.viewControllers.count
        if numberOfViewControllers < 2 {
            return nil
        }
        else {
            return self.navigationController!.viewControllers[numberOfViewControllers - 2]
        }
    }
    //MARK: IBActions
    
    @IBAction func avatarImageTapped(_ sender: Any) {
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1
        present(imagePickerController, animated: true, completion: nil)
        
        dismissKeyboard()
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        if usernameTextField.text != "" && emailTextField.text != "" && passwordTextField.text != ""  && repeatPasswordTextField.text != ""  && surnameTextField.text != "" && countryTextField.text != "" && cityTextField.text != "" && phoneTextField.text != ""{
            
            if (passwordTextField.text == repeatPasswordTextField.text){
                registerUser()
            } else {
                ProgressHUD.showError("Passwords do not match!")
            }
                        
        }else {
            ProgressHUD.showError("All fields are mandatory!")
        }
    }
    
    
    @IBAction func cameraButtonPressed(_ sender: Any) {
        
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1
        present(imagePickerController, animated: true, completion: nil)
        
        dismissKeyboard()
    }
    
    
    @IBAction func tapButtonPressed(_ sender: Any) {
        dismissKeyboard()
    }
    
    
    //MARK: Helper Functions
    
    func registerUser()
    {
        print("Register.....")
        
        dismissKeyboard()
        ProgressHUD.show("Registering....")
        
        if let _ = self.backViewController() as? LoginViewController  {
            FUser.registerUserWith(email: emailTextField.text!, password: passwordTextField.text!, firstName: usernameTextField.text!, lastName: surnameTextField.text!) { (error) in
                
                if error != nil{
                    ProgressHUD.dismiss()
                    ProgressHUD.showError(error!.localizedDescription)
                    return
                }
                
                self.registerMyUser()
                
            }
        } else {
         self.registerMyUser()
        }
        
        
        
        
        
    }
    
    
    func finishRegistration(withValues: [String: Any]){
        
        updateCurrentUserInFirestore(withValues: withValues) { (error) in
            if error != nil{
                
                DispatchQueue.main.async {
                    ProgressHUD.showError(error!.localizedDescription)
                    print(error!.localizedDescription)
                }
                return
            }
            
            ProgressHUD.dismiss()
            //go to app
            self.goToApp()
            
        }
        
    }
    
    func dismissKeyboard()
    {
        self.view.endEditing(false)
    }
    
    func cleanTextFields(){
        emailTextField.text = ""
        passwordTextField.text = ""
        usernameTextField.text = ""
        surnameTextField.text = ""
        repeatPasswordTextField.text = ""
        cityTextField.text = ""
        countryTextField.text = ""
        phoneTextField.text = ""
        
        
    }
    
    func registerMyUser()
    {
        
        let fullName = usernameTextField.text! + " " + surnameTextField.text!
        var tempDictionary : Dictionary = [kFIRSTNAME: usernameTextField.text!, kLASTNAME: surnameTextField.text!, kFULLNAME: fullName, kCOUNTRY: countryTextField.text!, kCITY: cityTextField.text!, kPHONE: phoneTextField.text!] as [String: Any]
        
        if avatarImage == nil {
            imageFromInitials(firstName: usernameTextField.text!, lastName: surnameTextField.text!) { (avatarInitials) in
                
                let avatarIMG = avatarInitials.jpegData(compressionQuality: 0.7)
                let avatar = avatarIMG?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                tempDictionary[kAVATAR] = avatar
                
                //finishRegistration
                self.finishRegistration(withValues: tempDictionary)
                
            }
        }else {
            let avatarData = avatarImage?.jpegData(compressionQuality: 0.5)
            let avatar = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            tempDictionary[kAVATAR] = avatar
            
            //finishRegistration
            self.finishRegistration(withValues: tempDictionary)
            
            
        }
    }
    
    func goToApp()
    {
        cleanTextFields()
        dismissKeyboard()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
        
        
        //present the app here
        print("Show the App")
        
        
        
    }
    
    //MARK: ImagePickerDelegate
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        if  images.count > 0 {
            self.avatarImage = images.first!
            self.avatarImageView.image = self.avatarImage?.circleMasked
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    

}
