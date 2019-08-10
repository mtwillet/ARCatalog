//
//  CatelogViewController.swift
//  ARMall
//
//  Created by Mathew Willett on 5/10/18.
//  Copyright © 2018 Mathew Willett. All rights reserved.
//


import UIKit
import Firebase


//Delegate and datasource are defined in the storyboard
class OptionsViewController : UIViewController {
    
    //MARK: Variables
    
    let helperMethods = ARKitHelper()
    var catalogItems = [CatalogItemObject]()
    
    
    //MARK: Outlets
    
    @IBOutlet weak var optiongsTableView: UITableView!
    
    @IBAction func deleteDownloadedFiles(_ sender: Any) {
        
        helperMethods.DeleteDownloadedFiles(CatalogItems: &catalogItems)
        
        helperMethods.updateLocallyStoredCatalogedItemInfo(CatalogItems: catalogItems)
    
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if helperMethods.initLocallyStoredCatalogedItemInfo() != nil {
            catalogItems = helperMethods.initLocallyStoredCatalogedItemInfo()!
            return
        }
        
        
    }
    

}


















