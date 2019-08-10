//
//  ARViewControllerDelegate.swift
//  ARCatalog
//
//  Created by Mathew Willett on 5/23/18.
//  Copyright © 2018 Mathew Willett. All rights reserved.
//

import UIKit
import Foundation
import ARKit

//Left Right Pane delegate
@objc
protocol ARViewControllerDelegate {
    @objc optional func toggleLeftPanel()
    @objc optional func toggleRightPanel()
    @objc optional func collapseSidePanels()
}



//Catalog Delegate
protocol CatalogDelegate {
    //MARK: Replace
    //Replace with the selected item location
    func objectLocation(_ location: URL, _ name: String, _ itemIndex: Int)
}
//
//protocol ResetViews {
//    func resetVC()
//}
