//
//  PhotoAlbumViewController.swift
//  Good mood Camera
//
//  Created by Stanley Tseng on 2019/12/9.
//  Copyright © 2019 StanleyAppWorld. All rights reserved.
//

import UIKit

class PhotoAlbumViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var photoImagePreview: UIImageView!
    @IBOutlet weak var btnOpenPhotoAlbum: UIButton!
    @IBOutlet weak var btnEditPicture: UIButton!
    @IBOutlet weak var btnViewCancelSelect: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true)
        // Do any additional setup after loading the view.
    }
    
    // Open Photo Album
    @IBAction func openPhotoAlbum(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true)
    }
    
    // Select Picture
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        photoImagePreview.image = selectedImage
        dismiss(animated: true, completion: nil)
    }
    
    // btn Edit Picture (go to filter page)
    @IBAction func editPicture(_ sender: Any) {
        self.performSegue(withIdentifier: "goToFilterFuction", sender: " ")
    }
    
    @IBAction func btnCancelSelect(_ sender: UIButton) {
        
    }
    
    // 設定segue至FilterFuctionViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToFilterFuction"
        {
            let controller = segue.destination as! FilterFunctionViewController
            let data = FilterSetting(pic: photoImagePreview.image)
            controller.parameter = data
        }
    }
}
