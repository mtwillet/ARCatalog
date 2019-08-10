//
//  ViewerViewController.swift
//  ARCatalog
//
//  Created by Mathew Willett on 12/26/18.
//  Copyright © 2018 Mathew Willett. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import MultipeerConnectivity
import FirebaseAuth
import FirebaseFirestore


class ViewerViewController : UIViewController, ARSCNViewDelegate, ARSessionDelegate  {
    
    //MARK: Class Varibles
    
    ///Multipeer Session Object
    var multipeerSession: MultipeerSession!
    
    ///Peer ID who sent the map
    var mapProvider: MCPeerID?

    ///Helper class full of wonderfully useful methods
    let arHelper = ARKitHelper()
    
    ///Object that holds the locally stored data of the Catalog Items
    var catalogItems = [CatalogItemObject]()
    
    ///Holds the name of the anchor sent from the Peer
    var itemSentFromPeer = ""
    
    
    
    //MARK: Outlets
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var sessionLabel: UILabel!
    
    @IBAction func exitButton(_ sender: Any) {
        let alert = UIAlertController(title: "Exit View", message: "Would you like to exit your session?", preferredStyle: UIAlertControllerStyle.alert)
        
        let exitAction = UIAlertAction(title: "Exit", style: .default) { (alertAction) in
            self.dismiss(animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) in
        }
        
        alert.addAction(exitAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated:true, completion: nil)
    }
    
    
    
    
    //MARK: VC Startup Methods
    
    override func viewDidLoad() {
        super .viewDidLoad()
        
        //delegate that looks for nodes being added to anchors
        sceneView.delegate = self
        //delegate that looks to Anchors being added to the session
        sceneView.session.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        //show feture points
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        //Change the lighting to default
        sceneView.autoenablesDefaultLighting = false
        //Create an empty scene in the scene view
        let scene = SCNScene()
        sceneView.scene = scene
        //Initiate Multipeer Session
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
        
        //Sign into Firebase
        Auth.auth().signIn(withEmail: "mtwilletthome@gmail.com", password: "test12345") { (user, error) in
            print("Sign In successfull")
        }
        
        //Set any stored information about the downloaded items to be used later
        if arHelper.initLocallyStoredCatalogedItemInfo() != nil {
            catalogItems = arHelper.initLocallyStoredCatalogedItemInfo()!
        }
        
        
        //Get list of items from Firebase
        arHelper.downloadItemList(catalogItems: catalogItems) { (completionInfo) in
            self.catalogItems = completionInfo
            self.arHelper.updateLocallyStoredCatalogedItemInfo(CatalogItems: self.catalogItems)
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        //detect horizontal and vertical planes planes
        configuration.planeDetection = [.horizontal,.vertical]
        // Run the view's session
        sceneView.session.run(configuration)
        
        //Test
        sceneView.session.delegate = self
        
    }
    
    
    
    
    
    
    
    
    
    // Receives ARMap of ARAnchor from peer
    func receivedData(_ data: Data, from peer: MCPeerID) {
        
        do {
            //Add Map to the session
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                print("receivedData - Succeffully unarchived ARWorldMap from Peer")
                
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                
                //Store the name of the Peer who sent the data
                mapProvider = peer
            }
            
        } catch {
            print("Error: reveiveData - Error trying to unarchive the ARWorldMap sent from Peer: \(peer)")
        }
        
        
        
        do {
            //Add anchor to the session
            if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
                itemSentFromPeer = anchor.name!
                
                if checkIfFileIsDownloaded(AnchorName: anchor.name!) == true {
                    sceneView.session.add(anchor: anchor)
                } else {
                    
                    
                    //Download file if it doesnt already exist
                    let index = arHelper.findCatalogItemIndexWithItemName(catalogItems: catalogItems, itemName: anchor.name!)
                    let item = catalogItems[index]
                    
                    var successfullDAEDownload = false
                    var successfullPNGDowload = false
                
                    //Download 3D File
                    arHelper.downloadFiles(fileName: item.itemBothFilesName + ".dae", fileCloudURL: item.itemCloudDAEFileURL) { (complete, localURL, error) in
                        if error != nil {
                            print("Error: receivedData - Error while downloading DAE file from Firebase Storage. Error = " + String(describing: error))
                        } else {
                            if complete == true {
                                print("receivedData - " + item.itemDisplayName + ".dae File Downloaded Sussesfully")
                                successfullDAEDownload = true
                                
                                item.itemLocalDAEFileUrl = localURL
                            }
                        }
                    }
                        
                    //Download 3D File skin png
                    self.arHelper.downloadFiles(fileName: item.itemBothFilesName + ".png", fileCloudURL: item.itemCloudPNGFileUrl) { (complete, localURL, error) in
                        if error != nil {
                            print("Error: receivedData - Error while downloading PNG file from Firebase Storage. Error = " + String(describing: error))
                        } else {
                            if complete == true {
                                print("receivedData - " + item.itemDisplayName + " PNG File Downloaded Sussesfully")
                                successfullPNGDowload = true
                                
                                item.itemLocalPNGFileUrl = localURL
                            }
                        }
                    }
                    
                    
                    //Check if all files have been downloaded and save item info locally
                    if successfullDAEDownload == true && successfullPNGDowload == true {
                        print("receivedData - All files for " + item.itemDisplayName + " were downloaded")
                        
                        item.itemPNGFileDownloaded = true
                        arHelper.updateLocallyStoredCatalogedItemInfo(CatalogItems: self.catalogItems)
                    }
                }
            }
        } catch {
            print("Error: receiveData - Error trying to unarchive the Anchor sent from Peer : \(peer)")
        }
    }
    
    
    
    
   
    
   
    
    
    
    
    func checkIfFileIsDownloaded(AnchorName: String) -> Bool {
        var downloaded = false
        for item in catalogItems {
            if item.itemDisplayName == AnchorName {
                if item.itemPNGFileDownloaded == true {
                    downloaded = true
                } else {
                    downloaded = false
                }
            }
        }
        return downloaded
    }
    
    
    
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        //update session label
        sessionLabel.text = arHelper.updateSessionInfoLabel(multipeerSession: multipeerSession, mapProvider: mapProvider, for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        sessionLabel.text = frame.worldMappingStatus.description
        sessionLabel.text = arHelper.updateSessionInfoLabel(multipeerSession: multipeerSession, mapProvider: mapProvider, for: session.currentFrame!, trackingState: frame.camera.trackingState)
    }
    
    
    //Sees that an achor was added to the scene. Then add the Item Node
    //TODO: Make the Prefix more Generic
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
   
        let xcatalogItemIndex = arHelper.findCatalogItemIndexWithItemName(catalogItems: catalogItems, itemName: itemSentFromPeer)
        let xcatalogItemName = catalogItems[xcatalogItemIndex].itemBothFilesName
        let xobjectSceneLocation = catalogItems[xcatalogItemIndex].itemLocalDAEFileUrl
        node.addChildNode(arHelper.loadSelectedNode(itemName: xcatalogItemName, objectSceneLocation: xobjectSceneLocation))
    
    }
    
    
    
}
