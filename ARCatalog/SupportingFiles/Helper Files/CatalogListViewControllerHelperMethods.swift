//
//  CatalogListView_HelperMethods.swift
//  ARCatalog
//
//  Created by Mathew Willett on 3/24/19.
//  Copyright © 2019 Mathew Willett. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore



class CLVCHelper {
    
    let testData = TestClient()
    
    //MARK: Download Bar
    
    func startDownloadBar(progressView : inout UIView){
        
        //Create Path
        let path = UIBezierPath()
        //Adding the line cap rounding later on will increse the length of the line by have of the views height. This takes that into acount by moving the start and end points.
        path.move(to: CGPoint(x: (0 + (progressView.frame.height / 2)), y: progressView.frame.height / 2))
        path.addLine(to: CGPoint(x: (progressView.frame.width - (progressView.frame.height / 2)), y: progressView.frame.height / 2))

        
        
        //Create shape layer for that path
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        shapeLayer.strokeColor = #colorLiteral(red: 0.01352947206, green: 0.2778841405, blue: 0.5233185279, alpha: 1).cgColor
        shapeLayer.lineWidth = progressView.frame.height
        shapeLayer.path = path.cgPath
        shapeLayer.lineCap = kCALineCapRound
        //Set to 0 so it doesnt appear initially. This is what will be animated
        shapeLayer.strokeEnd = 0
        
        
        //Add shape layer to view
        progressView.layer.addSublayer(shapeLayer)
        
        animateLine(sLayer: shapeLayer)
    }
    
    
    func stopAnimations(progressView : inout UIView){
        progressView.layer.removeAllAnimations()
        for layer in progressView.layer.sublayers ?? [] {
            layer.removeAllAnimations()
        }
    }
    
    
    fileprivate func animateLine(sLayer: CAShapeLayer) {
    
        
        //Animate the line
        // We want to animate the strokeEnd property of the circleLayer
        let startAnimation = CABasicAnimation(keyPath: "strokeStart")
        startAnimation.fromValue = -0.4
        startAnimation.toValue = 1
        //startAnimation.duration = 2
        startAnimation.isRemovedOnCompletion = false
        
        let endAnimation = CABasicAnimation(keyPath: "strokeEnd")
        endAnimation.fromValue = 0
        endAnimation.toValue = 1
        //endAnimation.duration = 2
        endAnimation.isRemovedOnCompletion = false
        
        let animation = CAAnimationGroup()
        animation.animations = [startAnimation, endAnimation]
        animation.duration = 1
        animation.repeatCount = .infinity
        
        // Do the actual animation
        sLayer.add(animation, forKey: "animate")
    }
    
    
    
    //MARK: Download Company Informaiton
    
    
    func dowloadCompanyInfo(label : UILabel) {
        let dbRef = Firestore.firestore().collection("Clients").document(testData.clientID)
        dbRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()
                for (key, value) in dataDescription! where key == "Company" {
                    label.text = "\(value)"
                }
            } else {
                print("Document does not exist")
            }
        }
        //return returnValue
    }
    
    
    
}
