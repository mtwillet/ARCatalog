//
//  SliderViews.swift
//  ARCatalog
//
//  Created by Mathew Willett on 1/20/19.
//  Copyright © 2019 Mathew Willett. All rights reserved.
//

import Foundation
import UIKit



class SliderViewController : ARViewControllerDelegate {
    
    
    //MARK: Initiallizer
    init(ARViewController middleVC: UIViewController, leftViewController leftVC: UIViewController, rightViewController rightVC: UIViewController){
        arViewController = middleVC
        leftViewController = leftVC
        rightViewController = rightVC
    }
    
    //MARK: Define State
    enum SlideOutState {
        case bothCollapsed
        case leftPanelExpanded
        case rightPanelExpanded
    }
    
    //MARK: Variables
    
    fileprivate var arNavigationController : UINavigationController!
    
    fileprivate var arViewController : UIViewController!
    
    fileprivate var currentState: SlideOutState = .bothCollapsed {
        didSet {
            let shouldShowShadow = currentState != .bothCollapsed
            //showShadowForCenterViewController(shouldShowShadow)
        }
    }
    
    fileprivate var leftViewController: UIViewController!
    
    fileprivate var rightViewController: UIViewController
    
    fileprivate let centerPanelExpandedOffset: CGFloat = 60
    
    fileprivate var leftViewForPan = UIView()
    
    fileprivate var rightViewForPan = UIView()
    

    
    
    
    
    
    
    
    
    
    
}
