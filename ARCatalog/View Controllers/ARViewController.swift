//
//  ViewController.swift
//  ARCatalog
//
//  Created by Mathew Willett on 5/12/18.
//  Copyright © 2018 Mathew Willett. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Alamofire
import MultipeerConnectivity
import FirebaseAuth





class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    //MARK: Variables
    
    ///Delegate object for slide view controller funtionality
    var delegate: ARViewControllerDelegate?
    
    ///Holds the list of nodes in the scene
    var objectNodes = [SCNNode]()
    
    ///Holds the dimentions and locations of the AR planes
    var planes = [UUID : VirtualPlane]()
    
    ///Holds the selected item from the catalog list. This is passed from the Catalog VC
    var selectedItem : String = ""
    
    ///Holds the location of the 3D file that was selected in the Catalog VC. This is passed from the Catalog VC
    var objectSceneLocation : URL?
    
    ///Holds what the row index being sent from the Catalog VC
    var selectedItemIndex : Int?
    
    ///Multipeer Session Object
    var multipeerSession: MultipeerSession!
    
    ///ARKit Helper Class
    let arHelper = ARKitHelper()

    ///Holds the data for the downloaded items
    var catalogItems = [CatalogItemObject]()

    
    
    
    
    //MARK: Outlets
    
    @IBOutlet weak var phoneIcon: UIImageView!
    
    @IBOutlet weak var phoneIconSuperView: UIView!
    
    @IBOutlet var itemLabel: UILabel!
    
    @IBOutlet weak var itemLabelSuperView: UIView!
    
    @IBOutlet var sceneView: ARSCNView!

    @IBAction func takePhoto(_ sender: UIButton) {
        //Take photo and Store it in the Photo Library
        let image = sceneView.snapshot()
        
        saveUserTakenPhoto(image: image, UniqueID: String(Date().toMillis()))
        
        //Haptic Feedback
        let feedback = UISelectionFeedbackGenerator()
        feedback.selectionChanged()
        
        //Create screen flash when photo is taken
        if let window = self.view{
            let view = UIView(frame: window.bounds)
            view.backgroundColor = UIColor.white
            view.alpha = 0.75
            window.addSubview(view)
            UIView.animate(withDuration: 1, animations: {
                view.alpha = 0.0
            }, completion: {(finished:Bool) in
                view.removeFromSuperview()
            })
        }
    }
    
    @IBAction func resetScene(_ sender: UIButton) {
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal,.vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        //Haptic Feedback
        let feedback = UISelectionFeedbackGenerator()
        feedback.selectionChanged()
        
    
    }
    
    
    @IBAction func viewPhotosButton(_ sender: Any) {
        //Haptic Feedback
        let feedback = UISelectionFeedbackGenerator()
        feedback.selectionChanged()
    }
    

    @IBOutlet weak var SessionLabel: UILabel!

    
    ///Sends the current map to the peers attatched to the session
    @IBAction func sendSessionMap(_ sender: Any) {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            self.multipeerSession.sendToAllPeers(data)
        }
    }

    @IBAction func connectPeers(_ sender: Any) {
        
        let rec = CGRect(x: view.frame.width / 2, y: view.frame.height / 2, width: 100, height: 100)
        let path = UIBezierPath(ovalIn: rec)
        
        let rec2 = CGRect(x: view.frame.width / 2, y: view.frame.height / 2, width: 1000, height: 1000)
        let path2 = UIBezierPath(ovalIn: rec2)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        shapeLayer.strokeColor = #colorLiteral(red: 0, green: 0.4793452024, blue: 0.9990863204, alpha: 1).cgColor
        shapeLayer.lineWidth = 10
        shapeLayer.path = path.cgPath
    
        view.layer.addSublayer(shapeLayer)
        
        addAnimation(layer: shapeLayer)
        
        
    }
    
    func addAnimation(layer: CAShapeLayer){
        let animation = CABasicAnimation(keyPath: "scale")
        //animation.fromValue = 0
        animation.toValue = CGPoint(x: 0, y: 0)
        animation.duration = 5
        animation.repeatCount = .infinity
        animation.autoreverses = true
        animation.isRemovedOnCompletion = false
        
        layer.add(animation, forKey: "animation")
    }

    
    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {
        
       
        
        //get information about the downloaded items
        if arHelper.initLocallyStoredCatalogedItemInfo() != nil {
            catalogItems = arHelper.initLocallyStoredCatalogedItemInfo()!
        }
        
        
        // Hit test to find a place for a virtual object.
        guard let hitTestResult = sceneView
            .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane, .estimatedVerticalPlane])
            .first
            else { return }
    
        
        
        if selectedItemIndex != nil {
            // Place an anchor for a virtual character. The model appears in renderer(_:didAdd:for:).
            let anchor = ARAnchor(name: catalogItems[selectedItemIndex!].itemDisplayName, transform: hitTestResult.worldTransform)
            sceneView.session.add(anchor: anchor)
            
            // Send the anchor info to peers, so they can place the same content.
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
                else { fatalError("Error: handleSceneTap - Error = can't encode anchor") }
            self.multipeerSession.sendToAllPeers(data)
        } else {
            print("handleSceneTap: No selected item")
        }
    }
    
    
    
    
    
    //MARK: View did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //delegate that looks for nodes being added to anchors
        sceneView.delegate = self
        //delegate that looks to Anchors being added to the session
        sceneView.session.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        //show feture points
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        //Change the lighting to default
        sceneView.autoenablesDefaultLighting = false
        //Create an empty scene in the scene view
        let scene = SCNScene()
        sceneView.scene = scene
        //Initiate Multipeer Session
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
        
        //Hides the navigation bar that is used for the Slide View Controller
        self.navigationController?.isNavigationBarHidden = true
    
        
        //animateItemLabelToComeIn()
       
    }
    
    
    //MARK: View Will Appear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        //detect horizontal and vertical planes planes
        configuration.planeDetection = [.horizontal,.vertical]
        // Run the view's session
        sceneView.session.run(configuration)
     
        //Setup the photos folder if it does not already exist
        checkOrAddIImageFolder()
        
        //Hide Phone Animation
        phoneIcon.isHidden = true
        
        //Restart phone animation
        phoneIcon.transform = .identity

    }
    
    
    
    
    
    
//    @objc func panGesture(_ gesture: UIPanGestureRecognizer) {
//        print("Moving Object")
//
//        gesture.minimumNumberOfTouches = 1
//
//        let results = self.sceneView.hitTest(gesture.location(in: gesture.view), types: ARHitTestResult.ResultType.featurePoint)
//
//        guard let result: ARHitTestResult = results.first else {
//            return
//        }
//
//        let hits = self.sceneView.hitTest(gesture.location(in: gesture.view), options: nil)
//        if let tappedNode = hits.first?.node {
//            let position = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
//            tappedNode.position = position
//        }
//
//    }
    
    
    
    
    
    func checkOrAddIImageFolder(){
        
        let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        
        if let pathComponent = documentsPath.appendingPathComponent("/UserPhotos") {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            
            if fileManager.fileExists(atPath: filePath) {
                print("checkIfAddImageFolder - Photos Folder Exists")
            } else {
                
                let photosFolderPath = documentsPath.appendingPathComponent("UserPhotos")
                do
                {
                    try FileManager.default.createDirectory(atPath: photosFolderPath!.path, withIntermediateDirectories: true, attributes: nil)
                    print("checkIfAddImageFolder - Photos Folder Created")
                }
                catch let error as NSError
                {
                    print("Error: checkOrAddImageFolder - Unable to create directory. Error = \(error.debugDescription)")
                }
            }
            
        } else {
            print("Error: checkOrAddImageFolder - Unable to access Documents Directory")
        }
    }
    
    
    
    
    func saveUserTakenPhoto(image: UIImage, UniqueID: String){
        
        let fileManager = FileManager.default
        
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("/UserPhotos/" + UniqueID + ".jpg")
            
        let imageData = UIImageJPEGRepresentation(image, 0)
        
        fileManager.createFile(atPath: paths as String, contents: imageData, attributes: nil)
        
    }

    
    

    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
       
        //update session label
        SessionLabel.text = arHelper.updateSessionInfoLabel(multipeerSession: multipeerSession, mapProvider: mapProvider, for: session.currentFrame!, trackingState: camera.trackingState)
        
    }
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //update session label
        SessionLabel.text = frame.worldMappingStatus.description

        SessionLabel.text = arHelper.updateSessionInfoLabel(multipeerSession: multipeerSession, mapProvider: mapProvider, for: session.currentFrame!, trackingState: frame.camera.trackingState)
      
        //Show the phone animation
        if arHelper.updateSessionInfoLabel(multipeerSession: multipeerSession, mapProvider: mapProvider, for: session.currentFrame!, trackingState: frame.camera.trackingState) != "" {
            animatePhoneIcon()
        } else {
            phoneIcon.isHidden = true
        }
    }
    
    
    //MARK: Animations
    
    ///Animates the phone icon to sway back and forth when the user needs to map more of there surroundings.
    func animatePhoneIcon(){

        phoneIcon.isHidden = false
    
        UIView.animate(withDuration: 1.5, delay: 0, options: [.autoreverse, .repeat], animations: {
            self.phoneIcon.transform = CGAffineTransform(translationX: self.phoneIconSuperView.frame.width - self.phoneIcon.frame.width, y: 0)
            //self.phoneIcon.center = CGPoint(x: self.phoneIconSuperView.frame.width - self.phoneIcon.frame.width, y: 0)
                

            
            
        }, completion: nil)
        
        
        
        
//        UIView.animate(withDuration: 0.75, delay: 0, options: [.autoreverse, .repeat], animations: {
//
//            self.phoneIcon.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        //            self.phoneIcon.frame = CGRect(x: 0, y: 0, width: self.phoneIcon.frame.width, height: (self.phoneIcon.frame.height * 0.8))

//        }, completion: nil)
    
    }
    
    
    
    
//    func animateItemLabelToComeIn() {
//
//
//        UIView.animate(withDuration: 1.5, delay: 1, usingSpringWithDamping: 0.8, initialSpringVelocity: 3, options: .curveEaseOut, animations: {
//            self.itemLabelSuperView.transform = CGAffineTransform(translationX: 262, y: 0)
//
//
//        }, completion: nil)
//
//
//    }

    
    
    
    

    //Add item to the scene
    //override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        

    
    
    
    //MARK: AR Planes
    
    //Adds Node to Anchors to the scene when they are found
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        //Add Plane Anchor to Scene
        if let arPlaneAnchor = anchor as? ARPlaneAnchor {
            let plane = VirtualPlane(anchor: arPlaneAnchor)
            self.planes[arPlaneAnchor.identifier] = plane
            node.addChildNode(plane)
            //print("New Anchor Added")
            //print(node.childNodes.count)
        }
        
        //Add Anchor for the Item to the Scene
        if let name = anchor.name, name.hasPrefix(catalogItems[selectedItemIndex!].itemDisplayName) {
            let xcatalogItemName = catalogItems[selectedItemIndex!].itemBothFilesName
            
            node.addChildNode(arHelper.loadSelectedNode(itemName: xcatalogItemName, objectSceneLocation: catalogItems[selectedItemIndex!].itemLocalDAEFileUrl))
        }
    }
    
    

    
    
    
    //TODO: There is no need for this in this controller
    
    var mapProvider: MCPeerID?
    
    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        
        do {
            //print("Trying to Get World Map")
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                print("receivedData: Received World Map from Peer")
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                
                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
            }
            
        } catch {
            print("receivedData: Error decoding map")
        }
        
        
        
        do {
            //print("Tryng to get Anchor")
            if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
                // Add anchor to the session, ARSCNView delegate adds visible content.
                print("receivedData: Received Anthor Data from Peer")
                sceneView.session.add(anchor: anchor)
            }
//            else {
//                print("unknown data recieved from \(peer)")
//            }
        } catch {
            print("receivedData: Error decoding anchor")
            //print("can't decode data recieved from \(peer)")
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //Update plane when more surface is found
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let plane = planes[arPlaneAnchor.identifier] {
            plane.updateWithNewAnchor(arPlaneAnchor)
            
//            //TEST: Change planes color
//            let material = [chooseMaterial()]
//            plane.planeGeometry.materials = material


        }
    }
    
    
    //MARK: TEST - Code to change plane colors
//    var x = 0
//    func chooseMaterial() -> SCNMaterial{
//        if x == 0 {
//            let material = SCNMaterial()
//            material.diffuse.contents = UIColor.red.withAlphaComponent(0.5)
//            x += 1
//            return material
//        } else {
//            let material = SCNMaterial()
//            material.diffuse.contents = UIColor.blue.withAlphaComponent(0.5)
//            x -= 1
//            return material
//        }
//    }
    
    
    
    
    //Remove plane
    
    //TODO: Remove planes when app is in the background for 20 min. Create a Scene Reset when app comes out of sleep.
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let index = planes.index(forKey: arPlaneAnchor.identifier) {
            planes.remove(at: index)
        }
    }
    
    
    
    //MARK: AR View Error Handleing
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}



//MARK: Extensions

//Delegate to accept the file location of the selected item
extension ARViewController: CatalogDelegate {
    func objectLocation(_ location: URL, _ name: String, _ itemIndex: Int) {
        objectSceneLocation = location
        print("Data Transfered")
        itemLabel.text = name
        selectedItemIndex = itemIndex
        delegate?.collapseSidePanels?()
    }
}









//MARK: AR Guesture Recognition

//Move the object
//    @objc func moveObject(_ gesture: UIPanGestureRecognizer) {
//        var currentAngleY: Float = 0.0
//
//        let touches = Set<UITouch>
//        let touch = touches.first!
//        let location = touch.location(in: sceneView)
//        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
//
//
//        if let currentNode = hitResults.first.node {
//
//        guard let nodeToRotate = currentNode else { return }
//
//        let translation = gesture.translation(in: gesture.view!)
//        var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0
//        newAngleY += currentAngleY
//
//        nodeToRotate.eulerAngles.y = newAngleY
//
//        if(gesture.state == .ended) { currentAngleY = newAngleY }
//
//        print(nodeToRotate.eulerAngles)
//
//        }
//
//    }



extension Date {
    func toMillis() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
