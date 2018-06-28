//
//  LoginViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 25/06/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit
import ProgressHUD

class LoginViewController: UIViewController {

    
    
    @IBOutlet weak var emailTextField: UITextField!
    
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    //MARK: IBActions
    
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        dismissKeyboard()
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            loginUser()
            
        } else {
            ProgressHUD.showError("Email and Password is missing!")
            
        }
        
    }
    
    
    @IBAction func backgroundTap(_ sender: Any) {
        dismissKeyboard()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    //MARK: Helper Functions
    
    func loginUser() {
        print("Logging in the user")
        ProgressHUD.show("Logging In....")
        FUser.loginUserWith(email: emailTextField.text!, password: passwordTextField.text!) { (error) in
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            //present the app
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
    }
    
    //MARK: GoToApp
    
    func goToApp()
    {
        ProgressHUD.dismiss()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        
        cleanTextFields()
        dismissKeyboard()
        
        //present the app here
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
        print("Show the App")
        
        
        
    }

}
