//
//  PhotoListViewController.swift
//  ARCatalog
//
//  Created by Mathew Willett on 1/2/19.
//  Copyright © 2019 Mathew Willett. All rights reserved.
//

import Foundation
import UIKit
import SimpleImageViewer




class photoList : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    
    @IBOutlet weak var leftButton: UIBarButtonItem!
    
    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var navigationBar: UINavigationItem!
    
    @IBOutlet weak var rightButton: UIBarButtonItem!

    
    @IBAction func selectButton(_ sender: Any) {
        //Haptic Feedback
        let feedback = UISelectionFeedbackGenerator()
        feedback.selectionChanged()
        
        if rightButton.title == "Select" {
            //Change Left Button
            rightButton.title = "Cancel"
            //Change Right Button
            navigationBar.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(addExportVC))
            navigationBar.leftBarButtonItem?.isEnabled = false
            //Change Nave Bar Title
            navigationBar.title = "Select Photos"
            //Add Bottom View
            presentBottomView()
            
            button.isEnabled = false
            button.setTitleColor(UIColor.lightGray, for: .normal)
            
        } else {
            setNavBarBackToSelect()
            deselectCollectionCells()
            //Hide Bottom View
            hideBottomView()
        }
    }
    
    func setNavBarBackToSelect(){
        //Change Left Bar Button
        rightButton.title = "Select"
        //Chang Nav Bar Title
        navigationBar.title = "ARC Photos"
        //Change Right Bar Button
        navigationBar.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissView))
    }
    
    func setNavBarBackToCancel(){
        //Might Not Be Needed
    }
    

    @objc func dismissView() {
        //Haptic Feedback
        let feedback = UISelectionFeedbackGenerator()
        feedback.selectionChanged()
        
        dismiss(animated: true, completion: nil)
    }
    
    

    
    @objc func addExportVC(){
        var objectToSend : [Any] = selectedPhotos
        objectToSend.append(message!)
        
        let vc = UIActivityViewController(activityItems: objectToSend, applicationActivities: nil)
        
        vc.excludedActivityTypes = [UIActivityType.addToReadingList, UIActivityType.copyToPasteboard, UIActivityType.print, UIActivityType.assignToContact, UIActivityType.copyToPasteboard]
        
        present(vc, animated: true, completion: addExportVCCompletionFunctions)
        
        deselectCollectionCells()
        selectedItemIndex = []
        selectedItemFileName = []
        selectedPhotos = []
        
    }
    
    
    func addExportVCCompletionFunctions(){
        hideBottomView()
        setNavBarBackToSelect()
        deselectCollectionCells()
    }
    
    
    func deselectCollectionCells(){
        for index in selectedItemIndex {
            collectionView.cellForItem(at: index)?.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
   
    var button : UIButton = UIButton()
    
    func presentBottomView() {
        
        bottomView = UIView(frame: CGRect(x: 0, y: self.collectionView.frame.maxY, width: self.collectionView.frame.width, height: 70))

        bottomView.backgroundColor = UIColor.init(red: 0.976, green: 0.976, blue: 0.976, alpha: 1)

        button = UIButton(frame: CGRect(x: (self.bottomView.frame.width / 2) - 30, y: (self.bottomView.frame.height / 2) - 35, width: 60, height: 50))
        button.setTitleColor(UIColor.init(red: 0.08, green: 0.49, blue: 0.98, alpha: 1), for: .normal)
        button.setTitleColor(UIColor.init(red: 0.08, green: 0.49, blue: 0.98, alpha: 0.5), for: .highlighted)
        button.setTitle("Delete", for: .normal)
        button.addTarget(self, action: #selector(deletePhoto), for: .touchUpInside)
        
        self.bottomView.addSubview(button)
        
        self.view.addSubview(bottomView)

        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
            self.bottomView.transform = CGAffineTransform(translationX: 0, y: -70)
        }, completion: nil)
        
    }

    
    @objc func deletePhoto() {
        //Haptic Feedback
        let feedback = UISelectionFeedbackGenerator()
        feedback.selectionChanged()
        
        //Delete Selected Photos
        let fileManager = FileManager.default
        
        for file in selectedItemFileName {
            let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("/UserPhotos/" + file)
            
            do {
                try fileManager.removeItem(atPath: path)
            } catch {
                print("Error: deletePhoto - Error deleting photo from ARC")
            }
        }
        
        deselectCollectionCells()
        userPhotoList = getUserPhotoList()
        collectionView.reloadData()
        hideBottomView()
        setNavBarBackToSelect()
    }
    
    
    
    func hideBottomView(){
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveLinear, animations: {
            self.bottomView.transform = CGAffineTransform(translationX: 0, y: 0)
        }, completion: nil)
        
    }
    

    func checkIfImageIsSelected(index: Int) -> Bool {
        var checkValue = 0
        for item in selectedItemIndex {
            if item.row == index {
                checkValue += 1
            }
        }
        if checkValue > 0 {
            return true
        } else {
            return false
        }
    }
    

    func removeUserSelectionFromArray(index: IndexPath){
        var count = 0
        for item in selectedItemIndex {
            if item == index {
                selectedItemIndex.remove(at: count)
                selectedItemFileName.remove(at: count)
                selectedPhotos.remove(at: count)
            }
            count += 1
        }
    }
    
    
    
    
    var selectedPhotos : [UIImage] = []
    
    var selectedItemIndex : [IndexPath] = []

    var selectedItemFileName : [String] = []
    
    let reuseIdentifier = "imagePickerCell"
    
    var userPhotoList : [String] = []
    
    var bottomView = UIView()

    
    
    var message : MessageWithSubject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissView))
        
        userPhotoList = getUserPhotoList()
        
        message = MessageWithSubject(subject: "Welcome to ARC!", message: "ARC is a fantastic new App that can share your products in Augmented Reality! Take a look and tell us what you think!")
    
    }
    
    
   
    
    
    func getUserPhotoList() -> [String] {

        var photoList : [String] = []
        
        let fileManager = FileManager.default
        
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("/UserPhotos")
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: path).sorted()

            photoList = files
        }
        catch let error as NSError {
            print("Error: getUserPhotoList - Error getting the list of photos from user defaults. Error = \(error)")
        }
        
        return photoList
        
    }


    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.userPhotoList.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: (self.collectionView.frame.width / 4) - 2, height: (self.collectionView.frame.width / 4) - 2)
        
    }

    
    
    
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MyCollectionViewCell
     
        let fileManager = FileManager.default
        
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("UserPhotos/" + userPhotoList[indexPath.row])
        
        if fileManager.fileExists(atPath: path){
            cell.cellPhoto.image = UIImage(contentsOfFile: path)
        }else{
            print("No Image")
        }
        
        return cell
    }
    
    
    
    
    
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if rightButton.title == "Cancel" {
            
            if checkIfImageIsSelected(index: indexPath.row) == false {
            
                selectedItemFileName.append(userPhotoList[indexPath.row])
            
                collectionView.cellForItem(at: indexPath)?.layer.borderWidth = 3
                collectionView.cellForItem(at: indexPath)?.layer.borderColor = UIColor.green.cgColor
               
                selectedItemIndex.append(indexPath)
                
                let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("/UserPhotos/" + userPhotoList[indexPath.row])
                let image = UIImage(contentsOfFile: imagePath)
                selectedPhotos.append(image!)
                
                button.isEnabled = true
                button.setTitleColor(UIColor.init(red: 0.08, green: 0.49, blue: 0.98, alpha: 1), for: .normal)
                navigationBar.leftBarButtonItem?.isEnabled = true

                
            } else {
                collectionView.cellForItem(at: indexPath)?.layer.borderColor = UIColor.clear.cgColor
                removeUserSelectionFromArray(index: indexPath)
                
                if selectedPhotos == [] {
                    button.isEnabled = false
                    button.setTitleColor(UIColor.lightGray, for: .normal)
                    navigationBar.leftBarButtonItem?.isEnabled = false
                }
            }
            
        }
        
        if rightButton.title == "Select" {
            
            //Setup the image Preview View
            let cell = collectionView.cellForItem(at: indexPath) as! MyCollectionViewCell
            
            let configuration = ImageViewerConfiguration { config in
                config.imageView = cell.cellPhoto
            }
            
            let imageViewerController = ImageViewerController(configuration: configuration)
            
            present(imageViewerController, animated: true)
            
        }
        
      
            
            
        
        
        
        
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // change background color when user touches cell
//    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
//        let cell = collectionView.cellForItem(at: indexPath)
//        cell?.backgroundColor = UIColor.red
//    }
    
    
//
//    // change background color back when user releases touch
//    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
//        let cell = collectionView.cellForItem(at: indexPath)
//        cell?.backgroundColor = UIColor.cyan
//    }
    
    
    
    

    
}
    

    
    
    






class MyCollectionViewCell: UICollectionViewCell {
    
  //  @IBOutlet weak var myLabel: UILabel!
    
    @IBOutlet weak var cellPhoto: UIImageView!
    
    
}




class MessageWithSubject: NSObject, UIActivityItemSource {
    
    let subject:String
    let message:String
    
    init(subject: String, message: String) {
        self.subject = subject
        self.message = message
        
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return message
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        return message
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivityType?) -> String {
        return subject
    }
}
