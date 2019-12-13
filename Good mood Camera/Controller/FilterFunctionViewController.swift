//
//  FilterFunctionViewController.swift
//  Good mood Camera
//
//  Created by Stanley Tseng on 2019/12/11.
//  Copyright © 2019 StanleyAppWorld. All rights reserved.
//

import UIKit

class FilterFunctionViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var filterImagePreview: UIImageView!
    
    var parameter = FilterSetting()
    var filterNumber:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        filterImagePreview.image = parameter.pic
        
    }
    
    func buildImage(){
        
        let filter = ["", "CIPhotoEffectInstant", "CIPhotoEffectNoir", "CIPhotoEffectTonal", "CIPhotoEffectTransfer", "CIPhotoEffectFade", "CIPhotoEffectProcess", "CIPhotoEffectMono", "CIPhotoEffectChrome", "CIFalseColor", "CIColorPosterize", "CIColorInvert"]
        
        if parameter.pic != nil {
            let ciImage = CIImage(image: parameter.pic!)
            if let filter = CIFilter(name: filter[filterNumber]) {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                //filter.setValue(parameter.filterVolume, forKey: kCIInputIntensityKey)
                if let outputImage = filter.outputImage, let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) {
                    let image = UIImage(cgImage: cgImage)
                    filterImagePreview.image = image
                }
            }
        }
    }
    
    // 選擇濾鏡
    @IBAction func filterSelect(_ sender: UIButton) {
        if sender.tag == 0 {
            filterImagePreview.image = parameter.pic
        } else {
            filterNumber = sender.tag
            buildImage()
        }
    }
    
    // 儲存編輯後照片
    @IBAction func savePicture(_ sender: Any) {
        if let image = filterImagePreview.image {
            let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
}
