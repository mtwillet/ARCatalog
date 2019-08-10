//
//  ARViewControllerHelerMethods.swift
//  ARCatalog
//
//  Created by Mathew Willett on 12/26/18.
//  Copyright © 2018 Mathew Willett. All rights reserved.
//

import Foundation
import ARKit
import MultipeerConnectivity
import Alamofire
import FirebaseFirestore



class ARKitHelper {
    
    
    ///This method updates the labels on the AR View Controllers to give information about the session
    func updateSessionInfoLabel(multipeerSession: MultipeerSession, mapProvider: MCPeerID?, for frame: ARFrame, trackingState: ARCamera.TrackingState) -> String {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            message = "Connected with \(peerNames)."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            message = "Received map from \(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }

        return message
        
    }
    
    
    
    
    
    ///Using the User Defaults to store the data, this method updates the User Defaults with information about the downloaded Catalog Items. Including if they have been downloaded.
    func initLocallyStoredCatalogedItemInfo() -> [CatalogItemObject]? {
        //Stores User Defaults into the catalogItem object if any items exist.
        if let data = UserDefaults.standard.data(forKey: "CatalogItems") {
            
            do {
                
                let catalogItems = try (NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [CatalogItemObject])
                return catalogItems
                
            } catch {
                print("Error! InitUserDefaults -  Can't encode data: \(error)")
            }
            
        } else {
            //print("No Stored User Defaults. New ones will be created when available.")
            UserDefaults.standard.set(nil, forKey: "CatalogItems")
        }
    
        return nil
    }
    
    
    
    ///Uses the User Defaults to locally store the list of Catalog Items. Update catalogItems prior to using this method
    func updateLocallyStoredCatalogedItemInfo(CatalogItems: [CatalogItemObject]){
        
        //Remove old User Defaults that stored the last version of the Firebase items
        UserDefaults.standard.removeObject(forKey: "CatalogItems")
        
        //Add new User Defaults with the updated list of Firebase items
        do {
            let encodeData = try NSKeyedArchiver.archivedData(withRootObject: CatalogItems, requiringSecureCoding: false)
            UserDefaults.standard.set(encodeData, forKey: "CatalogItems")
        } catch {
            print("Can't encode user defaults: \(error)")
        }
        
    }
    
    
    
    ///Downloadfiles from Firebase Storage
    func downloadFiles(fileName : String, fileCloudURL : String, completionInfo : @escaping (_ complete: Bool, _ localURL: URL, _ error: Error?) -> Void) {
        
        //locates the applications Local Documents folder
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(fileName)
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        //Downloads a specific file
        Alamofire.download(fileCloudURL, to: destination).downloadProgress { progress in
            print("Download Progress: " + fileName + " "  + String(progress.fractionCompleted))
            }.response { response in
                let nilURL : URL = URL(fileURLWithPath: "")
                if response.error != nil {
                    return completionInfo(false, nilURL, response.error)
                } else {
                    return completionInfo(true, response.destinationURL!, nil)
                }
        }
    }
    
    

    //TODO: Make this more generic. Remoce the object Scene Location parameter
    ///Creates a node and adds its material using the locally stored URL file path
    func loadSelectedNode(itemName: String, objectSceneLocation: URL) -> SCNNode {
        
        //Base direcetory of the Application file that houses the downloaded item files
        var documentsUrl: URL {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
      
        let item3DURL = documentsUrl.appendingPathComponent(itemName + ".dae")
        
        let objectSceneSource = SCNSceneSource(url: item3DURL, options: nil)
        
        if let newNode = ((objectSceneSource!.entryWithIdentifier("node9", withClass: SCNNode.self))) {
            
            print("Node Loaded")
            
            //newNode.position = worldTrans
            let material = SCNMaterial()
            var imageData : Data?
           
            let fileURL = documentsUrl.appendingPathComponent(itemName + ".png")
            
            do {
                imageData = try Data(contentsOf: fileURL)
                if imageData == nil {
                    print("Error converting 3DPng image Local URL to Data. Image Data == nil")
                }
            } catch {
                print("Error loading image : \(error)")
            }
            
            material.diffuse.contents = UIImage(data: imageData!)
            newNode.geometry?.firstMaterial = material
            
            return newNode
            
        } else {
            print("Nil Node. About to crash")
            
            let emptyNode = SCNNode()
            
            return emptyNode
            
        }
      
    }
    
    
    
    ///This Looks through a Catalog Item list and see if the item (using its Item Name) has been marked as downloaded.
    func findCatalogItemIndexWithItemName(catalogItems: [CatalogItemObject], itemName: String) -> Int {
        var itemIndex = -1
        for items in catalogItems {
            itemIndex += 1
            if items.itemDisplayName == itemName {
                break
            }
        }
        return itemIndex
    }
    
    
    
    
    //MARK: Variables for dowloadItemList
    var clientObjectListDB: Firestore!  //Firestore BD object
    let testData = TestClient()
    
    //Conversion for Cloud field names and local field names
    let cloudItemDisplayName = "Name"
    let cloudItemBothFilesName = "3DFileName"
    let cloudItemDAEFileURL = "3DURL"
    let cloudItemThumbnailURL = "ThumbnailURL"
    let cloudItemPNGFileUrl = "3DPng"
    
    ///This downloaded all of the items from Firebase and stores them in a [CatalogItemObject]
    func downloadItemList(catalogItems: [CatalogItemObject], completionInfo: @escaping ([CatalogItemObject]) -> Void) {
        //Firebase setup
        clientObjectListDB = Firestore.firestore()
        var returnList = catalogItems
        let settings = clientObjectListDB.settings
        clientObjectListDB.settings = settings
        
        
        //Identify the clients storage folder in the cloud
        clientObjectListDB.collection("Clients/\(testData.clientID)/Items").order(by: "Name", descending: false).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents from Firebase: \(err)")
            } else {
                //Add item information into the CatalogItem object. This will be the data to load the table and to point the download method to the right URL.
                for document in querySnapshot!.documents {
                    //create temp vars to build new item object
                    let xcloudItemDisplayName = document.get(self.cloudItemDisplayName) as! String
                    let xcloudItemBothFilesName = document.get(self.cloudItemBothFilesName) as! String
                    let xcloudItemDAEFileURL = document.get(self.cloudItemDAEFileURL) as! String
                    let xcloudItemPNGFileUrl =  document.get(self.cloudItemPNGFileUrl) as! String
                    let xcloudItemThumbnailURL = document.get(self.cloudItemThumbnailURL) as! String
                    
                    //Check if the Firebase item exists in the CatalogItems object
                    var notExist = 0
                    for item in catalogItems {
                        if xcloudItemDisplayName != item.itemDisplayName {
                            notExist += 1
                        }
                    }
                    
                    if notExist == catalogItems.count {
                        let nilURL : URL = URL(fileURLWithPath: "")
                        returnList.append(CatalogItemObject(itemDisplayName: xcloudItemDisplayName, itemBothFilesName: xcloudItemBothFilesName, itemCloudDAEFileUrl: xcloudItemDAEFileURL, itemCloudPNGFileUrl: xcloudItemPNGFileUrl, itemLocalPNGFileUrl: nilURL, itemCloudThumbnailUrl: xcloudItemThumbnailURL, itemPNGFileDownloaded: false, itemDAEFIleDownloaded: false, itemLocalDAEFileUrl: nilURL))
                        
                    }
                    
                }
            
                return completionInfo(returnList)
                //self.arHelper.updateLocallyStoredCatalogedItemInfo(CatalogItems: self.catalogItems)
            }
        }
    }
    
    
    
    
    func DeleteDownloadedFiles(CatalogItems: inout [CatalogItemObject]) {
        let fileManager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: documentsPath)
            for filePath in filePaths {
                if filePath != "firestore" || filePath != "UserPhotos" {
                    try fileManager.removeItem(atPath: documentsPath + "/" + filePath)
                    updateCatalogItem(file : filePath, catalogItems : &CatalogItems)
                    print(filePath)
                }
            }
            print("Files Deleted")
            
        } catch {
            print("Could not clear document folder: \(error)")
        }
        
    }
    
    
    
    func updateCatalogItem(file: String, catalogItems : inout [CatalogItemObject]){
        for item in catalogItems {
            if (item.itemBothFilesName + ".dae") == file || (item.itemBothFilesName + ".png") == file {
                item.itemDAEFileDownloaded = false
                item.itemPNGFileDownloaded = false
            }
        }
    }
    
}
