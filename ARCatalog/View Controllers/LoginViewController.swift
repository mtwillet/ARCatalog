//
//  LoginViewController.swift
//  ARCatalog
//
//  Created by Mathew Willett on 12/24/18.
//  Copyright © 2018 Mathew Willett. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth


class LoginViewController : UIViewController {
    
    
    //MARK: Variables
    
    @IBOutlet weak var logInEmail: UITextField!
    @IBOutlet weak var logInPassword: UITextField!
    
    //Peer to Peer connection code
    var connectionCode = ""
    
    //MARK: Outlets
    
    @IBAction func logInButton(_ sender: Any) {
        //Sign into Firebase
        Auth.auth().signIn(withEmail: logInEmail.text!, password: logInPassword.text!) { (user, error) in
            
            //Currently allows any email and password to get through for debuggin purposes.
            print("Sign In successfull")
            
            self.performSegue(withIdentifier: "sucessfullLogIn", sender: nil)
            
        }
    }
    
    
    @IBAction func goToViewerButton(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Connection Code", message: "Please enter your connection code", preferredStyle: UIAlertControllerStyle.alert)
        
        let connectAction = UIAlertAction(title: "Connect", style: .default) { (alertAction) in
            let textField = alert.textFields![0] as UITextField
            self.connectionCode = textField.text!
            print(self.connectionCode)
            self.performSegue(withIdentifier: "SegueToViewer", sender: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) in
        }
        
        alert.addTextField { (textField) in
        }
        
        alert.addAction(connectAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated:true, completion: nil)
        
    }
    
    
    
    
    
}
