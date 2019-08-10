//
//  SlideViewController.swift
//  ARCatalog
//
//  Created by Mathew Willett on 5/23/18.
//  Copyright © 2018 Mathew Willett. All rights reserved.
//


import UIKit
//import QuartzCore

class SlideViewController: UIViewController {

    enum SlideOutState {
        case bothCollapsed
        case leftPanelExpanded
        case rightPanelExpanded
    }


    var arNavigationController: UINavigationController!
    var arViewController: ARViewController!

    var currentState: SlideOutState = .bothCollapsed {
        didSet {
            let shouldShowShadow = currentState != .bothCollapsed
            showShadowForCenterViewController(shouldShowShadow)
        }
    }
    var leftViewController: OptionsViewController?

    var rightViewController: CatalogListViewController?

    let centerPanelExpandedOffset: CGFloat = 60

    var leftViewForPan = UIView()

    var rightViewForPan = UIView()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Ser the VC Identifier
        self.restorationIdentifier = "SlideViewController"
    
        arViewController = UIStoryboard.arViewController()
        arViewController.delegate = self
        
        // wrap the centerViewController in a navigation controller, so we can push views to it
        // and display bar button items in the navigation bar
        arNavigationController = UINavigationController(rootViewController: arViewController)
        view.addSubview(arNavigationController.view)
        addChildViewController(arNavigationController)

        arNavigationController.didMove(toParentViewController: self)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        arNavigationController.view.addGestureRecognizer(panGestureRecognizer)
        
        
//        leftViewForPan.frame = CGRect(x: 0, y: 0, width: 50, height: self.view.frame.height)
//        leftViewForPan.backgroundColor = UIColor.white
//
//        rightViewForPan.frame = CGRect(x: self.view.frame.width - 50 , y: 0, width: 50, height: self.view.frame.height)
//        rightViewForPan.backgroundColor = UIColor.white
        
        self.view.addSubview(leftViewForPan)
        self.view.addSubview(rightViewForPan)
    }
    
    
}
    

// MARK: CenterViewController delegate

extension SlideViewController: ARViewControllerDelegate {
    
    func toggleLeftPanel() {

        let notAlreadyExpanded = (currentState != .leftPanelExpanded)

        if notAlreadyExpanded {
            addLeftPanelViewController()
        }

        animateLeftPanel(shouldExpand: notAlreadyExpanded)
    }


    func toggleRightPanel() {
        let notAlreadyExpanded = (currentState != .rightPanelExpanded)

        if notAlreadyExpanded {
            addRightPanelViewController()
        }

        animateRightPanel(shouldExpand: notAlreadyExpanded)
    }

    func collapseSidePanels() {

        switch currentState {
        case .rightPanelExpanded:
            toggleRightPanel()
        case .leftPanelExpanded:
            toggleLeftPanel()
        default:
            break
        }
    }


    func addLeftPanelViewController() {
        guard leftViewController == nil else { return }

        if let vc = UIStoryboard.catalogViewController() {
            //vc.items = Item.wholeCatalog()

            addLeftChildSidePanelController(vc)
            leftViewController = vc
        }
    }

    func addLeftChildSidePanelController(_ sidePanelController: OptionsViewController) {

        //sidePanelController.delegate = arViewController

        view.insertSubview(sidePanelController.view, at: 0)

        addChildViewController(sidePanelController)
        sidePanelController.didMove(toParentViewController: self)
    }

    func addRightChildSidePanelController(_ sidePanelController: CatalogListViewController) {

        sidePanelController.delegate = arViewController

        view.insertSubview(sidePanelController.view, at: 0)

        addChildViewController(sidePanelController)
        sidePanelController.didMove(toParentViewController: self)
    }




    func addRightPanelViewController() {

        guard rightViewController == nil else { return }

        if let vc = UIStoryboard.optionsViewController() {
            //vc.animals = Animal.allDogs()
            addRightChildSidePanelController(vc)
            rightViewController = vc
        }
    }

    func animateLeftPanel(shouldExpand: Bool) {
        if shouldExpand {
            currentState = .leftPanelExpanded
            animateCenterPanelXPosition(
                targetPosition: arNavigationController.view.frame.width - centerPanelExpandedOffset)

        } else {
            animateCenterPanelXPosition(targetPosition: 0) { finished in
                self.currentState = .bothCollapsed
                self.leftViewController?.view.removeFromSuperview()
                self.leftViewController = nil
            }
        }
    }

    func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)? = nil) {

        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut, animations: {
                        self.arNavigationController.view.frame.origin.x = targetPosition
        }, completion: completion)
    }

    func animateRightPanel(shouldExpand: Bool) {

        if shouldExpand {
            currentState = .rightPanelExpanded
            animateCenterPanelXPosition(
                targetPosition: -arNavigationController.view.frame.width + centerPanelExpandedOffset)

        } else {
            animateCenterPanelXPosition(targetPosition: 0) { _ in
                self.currentState = .bothCollapsed

                self.rightViewController?.view.removeFromSuperview()
                self.rightViewController = nil
            }
        }
    }


    func showShadowForCenterViewController(_ shouldShowShadow: Bool) {

        if shouldShowShadow {
            arNavigationController.view.layer.shadowOpacity = 0.8
        } else {
            arNavigationController.view.layer.shadowOpacity = 0.0
        }
    }
}


// MARK: Gesture recognizer

extension SlideViewController: UIGestureRecognizerDelegate {
    
    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.location(in: rightViewForPan) != CGPoint(x: 0, y: 0) {
            
            
            print(recognizer.location(in: rightViewForPan))
            print(recognizer.location(in: leftViewForPan))
            
            
            let gestureIsDraggingFromLeftToRight = (recognizer.velocity(in: view).x > 0)
            
            switch recognizer.state {
                
            case .began:
                if currentState == .bothCollapsed {
                    if gestureIsDraggingFromLeftToRight {
                        addLeftPanelViewController()
                    } else {
                        addRightPanelViewController()
                    }
                    
                    showShadowForCenterViewController(true)
                }
                
            case .changed:
                if let rview = recognizer.view {
                    rview.center.x = rview.center.x + recognizer.translation(in: view).x
                    recognizer.setTranslation(CGPoint.zero, in: view)
                }
                
            case .ended:
                if let _ = leftViewController,
                    let rview = recognizer.view {
                    // animate the side panel open or closed based on whether the view
                    // has moved more or less than halfway
                    let hasMovedGreaterThanHalfway = rview.center.x > view.bounds.size.width
                    animateLeftPanel(shouldExpand: hasMovedGreaterThanHalfway)
                    
                } else if let _ = rightViewController,
                    let rview = recognizer.view {
                    let hasMovedGreaterThanHalfway = rview.center.x < 0
                    animateRightPanel(shouldExpand: hasMovedGreaterThanHalfway)
                }
                
            default:
                break
            }
        }
    }
}


//MARK: Define controller in the storyboard

    private extension UIStoryboard {
        
        static func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: Bundle.main) }
        
        static func catalogViewController() -> OptionsViewController? {
            return mainStoryboard().instantiateViewController(withIdentifier: "OptionsViewController") as? OptionsViewController
        }
        
        static func optionsViewController() -> CatalogListViewController? {
            return mainStoryboard().instantiateViewController(withIdentifier: "CatalogViewController") as? CatalogListViewController
        }
        
        static func arViewController() -> ARViewController? {
            return mainStoryboard().instantiateViewController(withIdentifier: "ARViewController") as? ARViewController
        }
    }
    
    
    


