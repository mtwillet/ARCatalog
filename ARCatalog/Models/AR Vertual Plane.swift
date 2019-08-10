//
//  AR Model.swift
//  ARCatalog
//
//  Created by Mathew Willett on 5/20/18.
//  Copyright © 2018 Mathew Willett. All rights reserved.
//


//TEST: Plane detection
import UIKit
import SceneKit
import ARKit

class VirtualPlane: SCNNode {
    
    var anchor: ARPlaneAnchor!
    var planeGeometry: SCNPlane!
    
    /**
     * The init method will create a SCNPlane geometry and add a node generated from it.
     */
    init(anchor: ARPlaneAnchor) {
        super.init()
        
        // initialize anchor and geometry, set color for plane
        self.anchor = anchor
        self.planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        //self.planeGeometry = SCNPlane(width: 64, height: 64)
        //self.planeGeometry.cornerRadius = 32
        
        
        let material = initializePlaneMaterial()
        
        self.planeGeometry!.materials = [material]

        
        // create the SceneKit plane node. As planes in SceneKit are vertical, we need to initialize the y coordinate to 0, use the z coordinate,
        // and rotate it 90º.
        let planeNode = SCNNode(geometry: self.planeGeometry)
        planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
        
        
        // update the material representation for this plane
        updatePlaneMaterialDimensions()
        
        // add this node to our hierarchy.
        self.addChildNode(planeNode)
    }
    
    
    
    /**
     * Creates and initializes the material for our plane, a semi-transparent gray area.
     */
    func initializePlaneMaterial() -> SCNMaterial {
        
        let material = SCNMaterial()
        //material.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
        
        
        var smallCircle: UIBezierPath {
            return UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 50.0, height: 50.0))
        }
        
        //var bigCircle: UIBezierPath {
        //    return UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 500, height: 500))
        //}
        
        //Create shape layer for that path
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        shapeLayer.fillColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        shapeLayer.strokeColor = #colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1).cgColor
        shapeLayer.lineWidth = 10
        shapeLayer.path = smallCircle.cgPath
        
        
        let startAnimation = CABasicAnimation(keyPath: nil)
        startAnimation.fromValue = #colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1).cgColor
        startAnimation.toValue = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1).cgColor
        startAnimation.isRemovedOnCompletion = true
        startAnimation.duration = 5
        startAnimation.repeatCount = 0
        startAnimation.fillMode = kCAFillModeForwards
        
        shapeLayer.add(startAnimation, forKey: nil)
        
        //material.addAnimation(startAnimation, forKey: "animation")

        
        material.diffuse.contents = shapeLayer
        
        
        return material
    }
    
    

    
    
    
    
    
    
    /**
     * This method will update the plan when it changes.
     * Remember that we corrected the y and z coordinates on init, so we need to take that into account
     * when modifying the plane.
     */
    func updateWithNewAnchor(_ anchor: ARPlaneAnchor) {
        // first, we update the extent of the plan, because it might have changed
        self.planeGeometry.width = CGFloat(anchor.extent.x)
        self.planeGeometry.height = CGFloat(anchor.extent.z)
        
        // now we should update the position (remember the transform applied)
        self.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        
        // update the material representation for this plane
        updatePlaneMaterialDimensions()
    }
    
    /**
     * The material representation of the plane should be updated as the plane gets updated too.
     * This method does just that.
     */
    func updatePlaneMaterialDimensions() {
        // get material or recreate
        let material = self.planeGeometry.materials.first!

        // scale material to width and height of the updated plane
        let width = Float(self.planeGeometry.width)
        let height = Float(self.planeGeometry.height)
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
