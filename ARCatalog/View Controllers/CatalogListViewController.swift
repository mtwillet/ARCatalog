//
//  OptionsPanelViewController.swift
//  ARCatalog
//
//  Created by Mathew Willett on 5/23/18.
//  Copyright © 2018 Mathew Willett. All rights reserved.
//


import UIKit
import ARKit
import FirebaseFirestore
import Alamofire



class CatalogListViewController: UIViewController {
   
    //MARK: Variables
    
    var helperClass = CLVCHelper()
    
    var clientObjectListDB: Firestore!  //Firestore BD object
    var catalogItems = [CatalogItemObject]()  //Holds the list of items downloaded from Firebase
    var delegate: CatalogDelegate?  //Delegate object to transfer selected item to ARViewController
    var objectSceneSource : SCNSceneSource?  //Object to hold the location of the item file that will be sent to the ARViewController
    
    //LoadingAnimationLayers
    let shapeLayer = CAShapeLayer()
    var shapeLayerDict : [Int : CAShapeLayer] = [:]
    
    ///Awesome helper functions for the AR View Controllers
    let arHelper = ARKitHelper()
    
    //Cell Download Images
    let successfullDownloadImage = #imageLiteral(resourceName: "DownloadSuccessfull")
    let errorDownloadImage = #imageLiteral(resourceName: "DownloadError")
    
    
    
    
    //MARK: Outlets
    
    @IBOutlet weak var catalogTableView: UITableView!
    
    @IBAction func downloadItems(_ sender: Any) {
        //Haptic Feedback
        let feedback = UISelectionFeedbackGenerator()
        feedback.selectionChanged()
        
        DownloadItems()
        
    }
    
   
    
    
    
    
    @IBOutlet weak var syncButtonText: UILabel!
    
    @IBOutlet weak var syncButtonOutlet: UIButton!
    
    @IBOutlet weak var progressBarView: UIView!
    
    @IBOutlet weak var companyNameLabel: UILabel!
    
    @IBOutlet weak var filesDownloaded: UILabel!
    
    @IBOutlet weak var filesDownloadedLabel: UILabel!
    
    
    
    //MARK: ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Table View Setup
        catalogTableView.delegate = self
        catalogTableView.dataSource = self
        
        //Register custom Cell
        catalogTableView.register(UINib(nibName: "CatalogCell", bundle: nil), forCellReuseIdentifier: "customCatalogCell")
        
        //Set any stored information about the downloaded items to be used later
        if arHelper.initLocallyStoredCatalogedItemInfo() != nil {
            catalogItems = arHelper.initLocallyStoredCatalogedItemInfo()!
        }
        
        //Get list of items from Firebase
        arHelper.downloadItemList(catalogItems: catalogItems) { (completionInfo) in
            self.catalogItems = completionInfo
            self.arHelper.updateLocallyStoredCatalogedItemInfo(CatalogItems: self.catalogItems)
            self.catalogTableView.reloadData()
            
            self.setItemsDownloadedLabel()

        }

        helperClass.dowloadCompanyInfo(label: companyNameLabel)
    }
    
    
    func setItemsDownloadedLabel(){
        //Set items downloaded label
        let totalItems = catalogItems.count
        var itemsDownloaded = 0
        for item in catalogItems {
            if item.itemDAEFileDownloaded == true {
                itemsDownloaded += 1
            }
        }
        filesDownloaded.text = "\(itemsDownloaded) of \(totalItems)"
    }
 
    
    //MARK: Cell Dimension Setup
    
    //Sets the height of the cell to match its contets
    func configureTableView(){
        catalogTableView.rowHeight = UITableViewAutomaticDimension
    }

    
    
    //MARK: Download Items
    
    var itemsNeededToBeDownloaded = 0.0
    var itemsDownloaded = 0.0
    
    //Method called when the tabled view is pulled down. This calls the Download method to download the 3D files
    func DownloadItems() {
        //downloadFiles { (complete) in
        
        for item in catalogItems {
            
           // print("handleRefresh - " + item.itemName + " starting to download")
            
        
            if item.itemPNGFileDownloaded == false {
                
                //Start download progress bar
                //Animation completions are in the chekIfAllFilesAreDownloaded method
                helperClass.startDownloadBar(progressView: &progressBarView)
                filesDownloaded.isHidden = true
                filesDownloadedLabel.isHidden = true
                catalogTableView.allowsSelection = false
                syncButtonOutlet.isHidden = true
                syncButtonText.isHidden = true
                syncButtonOutlet.isEnabled = false
                
                itemsNeededToBeDownloaded += 1
         
                //Download 3D File
                self.arHelper.downloadFiles(fileName: item.itemBothFilesName + ".dae", fileCloudURL: item.itemCloudDAEFileURL) { (complete, localURL, error) in
                    if error != nil {
                        print("Error: handleRefresh - Error while downloading DAE file from Firebase Storage. Error = " + String(describing: error))
                    } else {
                        if complete == true {
                            print("DownloadItems - " + item.itemDisplayName + ".dae File Downloaded Sussesfully")
                            
                            self.itemsDownloaded += 0.5
                            
                            item.itemDAEFileDownloaded = true
                            
                            self.checkIfAllFilesAreDownloaded()
                            
                            item.itemLocalDAEFileUrl = localURL
                        }
                    }
                }
                     
                //Download 3D File skin png
                self.arHelper.downloadFiles(fileName: item.itemBothFilesName + ".png", fileCloudURL: item.itemCloudPNGFileUrl) { (complete, localURL, error) in
                    if error != nil {
                        print("Error: handleRefresh - Error while downloading PNG file from Firebase Storage. Error = " + String(describing: error))
                    } else {
                        if complete == true {
                            print("handleRefresh - " + item.itemDisplayName + " PNG File Downloaded Sussesfully")
                            //successfullPNGDowload = true
                            
                            self.itemsDownloaded += 0.5
                            
                            item.itemPNGFileDownloaded = true
                            
                            self.checkIfAllFilesAreDownloaded()

                            item.itemLocalPNGFileUrl = localURL
                        }
                    }
                }
            }
        }
    }


    func checkIfAllFilesAreDownloaded() {
        print("Items Needing to be downloaded")
        print(itemsNeededToBeDownloaded)
        print("Items Downloaded")
        print(itemsDownloaded)
        if itemsNeededToBeDownloaded == itemsDownloaded {
            arHelper.updateLocallyStoredCatalogedItemInfo(CatalogItems: self.catalogItems)
            catalogTableView.reloadData()
            
            //Stop downloaded animation and show labels
            progressBarView.layer.removeAllAnimations()
            helperClass.stopAnimations(progressView: &progressBarView)
//            filesDownloaded.isHidden = false
//            filesDownloadedLabel.isHidden = false
            catalogTableView.allowsSelection = true
            syncButtonOutlet.isHidden = false
            syncButtonText.isHidden = false
            syncButtonOutlet.isEnabled = true
            
            setItemsDownloadedLabel()
            
        }
    }
    

}




//MARK: Extensions

//Define the table data
extension CatalogListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return catalogItems.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCatalogCell", for: indexPath) as! CatalogCell
       
        //Cell apearance setup
        
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.width/2
        //Cell Data
        cell.cellLabel.text = catalogItems[indexPath.row].itemDisplayName
        
        if catalogItems[indexPath.row].itemPNGFileDownloaded == true && catalogItems[indexPath.row].itemDAEFileDownloaded == true {
            cell.downloadStatus.image = successfullDownloadImage
        } else {
            cell.downloadStatus.image = errorDownloadImage
        }
        
        if catalogItems[indexPath.row].itemCloudThumbnailUrl != "" {
            cell.cellImage.loadImageUsingCacheWithUrlString(catalogItems[indexPath.row].itemCloudThumbnailUrl)
        } else {
            cell.cellImage?.image = UIImage(named: "MissingImage")
        }
    
        return cell
    }
}



//Method for when the row is selected. This will call the delegate to pass the file location for that item to the ARViewController
extension CatalogListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemObject = catalogItems[indexPath.row]
        
        if itemObject.itemPNGFileDownloaded == true && itemObject.itemDAEFileDownloaded == true {
        //Send location to ARViewController
            delegate?.objectLocation(itemObject.itemLocalDAEFileUrl, itemObject.itemDisplayName, indexPath.row)
        } else {
            let alert = UIAlertController(title: "File Not Downloaded", message: "Pull down on item list to download latest models.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}



//MARK: Image Download Extension

let imageCache = NSCache<NSString, AnyObject>()

extension UIImageView {
    
    //This downloads a cells Thumbnail image if link exists. If there is a download error, defualt to the ? image.
    func loadImageUsingCacheWithUrlString(_ urlString: String) {
        
        self.image = nil
        
        //check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = cachedImage
            return
        }
        
        //otherwise fire off a new download
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            //download hit an error so lets return out
            if let error = error {
                print(error)
                self.image = UIImage(named: "MissingImage")
                return
            }
            
            DispatchQueue.main.async(execute: {
                
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                    
                    self.image = downloadedImage
                }
            })
            
        }).resume()
    }
    
}
