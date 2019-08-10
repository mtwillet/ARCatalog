////
////  VirtualObjectInteraction.swift
////  ARCatalog
////
////  Created by Mathew Willett on 1/22/19.
////  Copyright © 2019 Mathew Willett. All rights reserved.
////
//
//import Foundation
//import ARKit
//
//
//
//
//class ObjectInteraction : NSObject, UIGestureRecognizerDelegate {
//    
//    var sceneARView : UIView
//    
//    init(sceneView : UIView){
//        sceneARView = sceneView
//        
//        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
//        rotationGesture.delegate = self
//        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
//        
//        // Add gestures to the `sceneView`.
//        sceneARView.addGestureRecognizer(rotationGesture)
//        sceneARView.addGestureRecognizer(tapGesture)
//        
//        
//    }
//    
//    
//    
//    @objc
//    func didRotate(_ gesture: UIRotationGestureRecognizer) {
//        guard gesture.state == .changed else { return }
//        
//        /*
//         - Note:
//         For looking down on the object (99% of all use cases), we need to subtract the angle.
//         To make rotation also work correctly when looking from below the object one would have to
//         flip the sign of the angle depending on whether the object is above or below the camera...
//         */
//        trackedObject?.objectRotation -= Float(gesture.rotation)
//        
//        gesture.rotation = 0
//    }
//    
//    @objc
//    func didTap(_ gesture: UITapGestureRecognizer) {
//        let touchLocation = gesture.location(in: sceneARView)
//        
//        if let tappedObject = sceneARView.virtualObject(at: touchLocation) {
//            // Select a new object.
//            selectedObject = tappedObject
//        } else if let object = selectedObject {
//            // Teleport the object to whereever the user touched the screen.
//            translate(object, basedOn: touchLocation, infinitePlane: false, allowAnimation: false)
//            sceneView.addOrUpdateAnchor(for: object)
//        }
//    }
//    
//    
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        // Allow objects to be translated and rotated at the same time.
//        return true
//    }
//    
//    
//    /// - Tag: DragVirtualObject
//    func translate(_ object: VirtualObject, basedOn screenPos: CGPoint, infinitePlane: Bool, allowAnimation: Bool) {
//        guard let cameraTransform = sceneARView.session.currentFrame?.camera.transform,
//            let result = sceneARView.smartHitTest(screenPos,
//                                                infinitePlane: infinitePlane,
//                                                objectPosition: object.simdWorldPosition,
//                                                allowedAlignments: object.allowedAlignments) else { return }
//        
//        let planeAlignment: ARPlaneAnchor.Alignment
//        if let planeAnchor = result.anchor as? ARPlaneAnchor {
//            planeAlignment = planeAnchor.alignment
//        } else if result.type == .estimatedHorizontalPlane {
//            planeAlignment = .horizontal
//        } else if result.type == .estimatedVerticalPlane {
//            planeAlignment = .vertical
//        } else {
//            return
//        }
//        
//        /*
//         Plane hit test results are generally smooth. If we did *not* hit a plane,
//         smooth the movement to prevent large jumps.
//         */
//        let transform = result.worldTransform
//        let isOnPlane = result.anchor is ARPlaneAnchor
//        object.setTransform(transform,
//                            relativeTo: cameraTransform,
//                            smoothMovement: !isOnPlane,
//                            alignment: planeAlignment,
//                            allowAnimation: allowAnimation)
//    }
//    
//    
//    
//    
//}
//
//
//
///// Extends `UIGestureRecognizer` to provide the center point resulting from multiple touches.
//extension UIGestureRecognizer {
//    func center(in view: UIView) -> CGPoint {
//        let first = CGRect(origin: location(ofTouch: 0, in: view), size: .zero)
//        
//        let touchBounds = (1..<numberOfTouches).reduce(first) { touchBounds, index in
//            return touchBounds.union(CGRect(origin: location(ofTouch: index, in: view), size: .zero))
//        }
//        
//        return CGPoint(x: touchBounds.midX, y: touchBounds.midY)
//    }
//}
