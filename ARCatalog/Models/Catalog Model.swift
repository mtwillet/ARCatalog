//
//  Catalog Model.swift
//  ARCatalog
//
//  Created by Mathew Willett on 5/15/18/Users/Willett/Downloads.
//  Copyright © 2018 Mathew Willett. All rights reserved.
//

import Foundation
import UIKit

//Frames up User Defaults and encodes them so we can pass an object into User Defaults
class CatalogItemObject : NSObject, NSCoding {

    let itemDisplayName : String   //Initiallized from Firebase - items file name without file extention
    let itemBothFilesName : String    //Initiallized from Firebase - items file name without extention
    var itemCloudDAEFileURL : String    //Initiallized from Firebase - google storage location URL for the 3D file
    let itemCloudPNGFileUrl : String   //Initiallized from Firebase - items cloud url for the png file used to skin the model
    let itemCloudThumbnailUrl : String    //Initiallized from Firebase - google storage location URL for the items thumbnail
   
    var itemLocalDAEFileUrl : URL  //Iniitiallized from local - items local path to where it is stored on the phone
    var itemLocalPNGFileUrl : URL     //Initiallized from Firebase - items local url for png file used to skin the model
    var itemPNGFileDownloaded : Bool   //Initiallized from local - indicates if the PNG file has been downloaded
    var itemDAEFileDownloaded : Bool //Intiallized from local - indicates if the DAE file has been downloaded
    
    init(itemDisplayName: String, itemBothFilesName: String, itemCloudDAEFileUrl: String, itemCloudPNGFileUrl: String, itemLocalPNGFileUrl: URL, itemCloudThumbnailUrl: String, itemPNGFileDownloaded : Bool, itemDAEFIleDownloaded : Bool,  itemLocalDAEFileUrl: URL) {
        self.itemDisplayName  = itemDisplayName
        self.itemBothFilesName = itemBothFilesName
        self.itemCloudDAEFileURL = itemCloudDAEFileUrl
        self.itemCloudPNGFileUrl = itemCloudPNGFileUrl
        self.itemCloudThumbnailUrl = itemCloudThumbnailUrl
        
        self.itemLocalDAEFileUrl = itemLocalDAEFileUrl
        self.itemLocalPNGFileUrl = itemLocalPNGFileUrl
        self.itemPNGFileDownloaded = itemPNGFileDownloaded
        self.itemDAEFileDownloaded = itemDAEFIleDownloaded
        
    }
    
    required init(coder decoder: NSCoder) {
        self.itemDisplayName = decoder.decodeObject(forKey: "localItemDisplayName") as? String ?? ""
        self.itemBothFilesName = decoder.decodeObject(forKey: "localItemBothFilesName") as? String ?? ""
        self.itemCloudDAEFileURL = decoder.decodeObject(forKey: "localItemCloudDAEFileURL") as? String ?? ""
        self.itemCloudPNGFileUrl = decoder.decodeObject(forKey: "localItemCloudPNGFileUrl") as? String ?? ""
        self.itemCloudThumbnailUrl = decoder.decodeObject(forKey: "localItemCloudThumbnailUrl") as? String ?? ""
        
        self.itemLocalDAEFileUrl = decoder.decodeObject(forKey: "localItemLocalDAEFileUrl") as! URL
        self.itemLocalPNGFileUrl = decoder.decodeObject(forKey: "LocalItemLocalPNGFileUrl") as! URL
        self.itemPNGFileDownloaded = decoder.decodeBool(forKey: "localItemPNGFileDownloaded")
        self.itemDAEFileDownloaded = decoder.decodeBool(forKey: "localItemDAEFileDownloaded")
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(itemDisplayName, forKey : "localItemDisplayName")
        coder.encode(itemBothFilesName, forKey : "localItemBothFilesName")
        coder.encode(itemCloudDAEFileURL, forKey : "localItemCloudDAEFileURL")
        coder.encode(itemCloudPNGFileUrl, forKey : "localItemCloudPNGFileUrl")
        coder.encode(itemCloudThumbnailUrl, forKey : "localItemCloudThumbnailUrl")
        
        coder.encode(itemLocalDAEFileUrl, forKey : "localItemLocalDAEFileUrl")
        coder.encode(itemLocalPNGFileUrl, forKey: "LocalItemLocalPNGFileUrl")
        coder.encode(itemPNGFileDownloaded, forKey : "localItemPNGFileDownloaded")
        coder.encode(itemDAEFileDownloaded, forKey : "localItemDAEFileDownloaded")
    }
    
}



