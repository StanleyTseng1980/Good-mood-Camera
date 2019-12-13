//
//  ThemeOptionsViewController.swift
//  Good mood Camera
//
//  Created by Stanley Tseng on 2019/12/9.
//  Copyright © 2019 StanleyAppWorld. All rights reserved.
//
//  原訂計畫是拍立得相機模式，目前先完成第一階段基礎功能
//  未來會再調整為Camera的拍立得模式，以及在Camera增加錄影功能
//  目前Picture Collage（照片拼貼功能)尚在研究中，目前還沒有功能唷！
//  有使用ipad做實機測試，但...目前應該是在iPhone11版面猜不會跑掉喔！
//  此為練習作業，目前沒有做Auto Layout！所以建議在iPhone11做實機測試

import UIKit

class ThemeOptionsViewController: UIViewController {
    
    @IBOutlet weak var btnPolaroidCamera: UIButton!
    @IBOutlet weak var btnPhotoAlbum: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    // Open Camera
    @IBAction func goToCamera(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToCamera", sender: " ")
    }
    
    // Open Photo Album
    @IBAction func goToPhotoAlbum(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToPhotoAlbum", sender: " ")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

