//
//  CameraController.swift
//  Good mood Camera
//
//  Created by Stanley Tseng on 2019/12/10.
//  Copyright © 2019 StanleyAppWorld. All rights reserved.
//
//  Camera程式碼參考自APPCODA Simon版本
//  預計還要增加拍照後顯示照片在該頁面上，以及可開啟相簿，以上功能尚未製作。
//  鏡頭方向自動修正未解決（有找到相關程式碼，但還需要測試）

import AVFoundation
import UIKit

class CameraController: NSObject {
    
    var captureSession: AVCaptureSession?
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var currentCameraPosition: CameraPosition?
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    var photoOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var flashMode = AVCaptureDevice.FlashMode.off
    var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
}

extension CameraController {
    func prepare(completionHandler: @escaping (Error?) -> Void) {
        func createCaptureSession() {
            self.captureSession = AVCaptureSession()
        }
        
        func configureCaptureDevices() throws {
            // 使用AVCaptureDeviceDiscoverySession找出裝置上所有可用的內置相機 (.builtInDualCamera)。
            // ipad需要修改為（.builtInWideAngleCamera）
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [. builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
            let cameras = session.devices.compactMap { $0 }
            
            // 若找不到任何實體相機，就會出現錯誤訊息。
            guard !cameras.isEmpty else { throw CameraControllerError.noCamerasAvailable}
            
            // 這個循環會查看從前三段程式碼找到的可用相機，從而分辦前後相機。然後將後相機設定為自動對焦，過程中如遇上任何錯誤，也會出現錯誤訊息。
            for camera in cameras {
                if camera.position == .front {
                    self.frontCamera = camera
                }
                
                if camera.position == .back {
                    self.rearCamera = camera
                    
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    camera.unlockForConfiguration()
                }
            }
        }
        
        func configureDeviceInputs() throws {
            // 確認captureSession是否存在，若不存在就會出現錯誤訊息。
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            
            // 這些if流程主要是要建立所需的Capture Device Input來支援相片擷取。AVFoundation每一次Capture Session 僅能允許一台相機的輸入。由於裝置的初始設定通常是後相機，所以我們會先嘗試用後相機建立Input，再加到Capture Session；如出現錯誤，就會轉成前相機；若還是有問題，就會出現錯誤訊息。
            if let rearCamera = self.rearCamera {
                self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
                
                if captureSession.canAddInput(self.rearCameraInput!) { captureSession.addInput(self.rearCameraInput!)}
                self.currentCameraPosition = .rear
            }
                
            else if let frontCamera = self.frontCamera {
                self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                
                if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!)}
                self.currentCameraPosition = .front
            }
            else { throw CameraControllerError.noCamerasAvailable}
            
            
        }
        func configurePhotoOutput() throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            
            // 設定photoOutput，讓它使用jpeg檔案格式作為圖片編碼格式，再將photoOutput加入到captureSession，最後開始進行captureSession。
            self.photoOutput = AVCapturePhotoOutput()
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey :  AVVideoCodecType.jpeg])], completionHandler: nil)
            
            if captureSession.canAddOutput(self.photoOutput!) { captureSession.addOutput(self.photoOutput!)}
            captureSession.startRunning()
        }
        
        DispatchQueue(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
            }
                
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
                
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    // 應用captureSession來建立一個AVCaptureVideoPreview，並設定它為一個直向預覽畫面，再加入到所提供的視圖上。
    func displayPreview(on view: UIView) throws {
        
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        
        
        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.bounds
        
    }
    
    func switchCameras() throws {
        // 確保在切換相機時，有一個有效可運作的Capture Session，同時確認有正在使用的相機裝置。
        guard let currentCameraPosition = currentCameraPosition, let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        // 告知 Capture Session 開始設定。
        captureSession.beginConfiguration()
        
        // 取得Capture Session內所有Inputs的數組，並確保能切換至所要求的(前/後)相機。接著建立所需的Input Device，只要移除掉舊有的，再增加一個新Device就可以
        func switchToFrontCamera() throws {
            guard let rearCameraInput = self.rearCameraInput, captureSession.inputs.contains(rearCameraInput), let frontCamera = self.frontCamera else { throw CameraControllerError.invalidOperation }
            
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            captureSession.removeInput(rearCameraInput)
            
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                
                // 設定currentCameraPosition，這樣CameraController才會注意到這個改變
                self.currentCameraPosition = .front
            }
            
            else {
                throw CameraControllerError.invalidOperation
            }
        }
        
        // 取得Capture Session內所有Inputs的數組，並確保能切換至所要求的(前/後)相機。接著建立所需的Input Device，只要移除掉舊有的，再增加一個新Device就可以
        func switchToRearCamera() throws {
            guard let frontCameraInput = self.frontCameraInput, captureSession.inputs.contains(frontCameraInput), let rearCamera = self.rearCamera else { throw CameraControllerError.invalidOperation }
            
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            captureSession.removeInput(frontCameraInput)
            
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
                
                // 設定currentCameraPosition，這樣CameraController才會注意到這個改變
                self.currentCameraPosition = .rear
            }
            
            else {
                throw CameraControllerError.invalidOperation
            }
        }
        
        // 用switch來切換前後鏡頭
        switch currentCameraPosition {
        case .front:
            try switchToRearCamera()
            
        case .rear:
            try switchToFrontCamera()
        }
        
        // 提交或儲存設定好的Capture Session
        captureSession.commitConfiguration()
    }
    
    // 擷取一張圖像，供Camera Controller使用
    func captureImage(completion: @escaping (UIImage?, Error?) -> Void) {
        guard let captureSession = captureSession, captureSession.isRunning else { completion(nil, CameraControllerError.captureSessionIsMissing); return }
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
        self.photoCaptureCompletionBlock = completion
    }
    
}

// 拍照時畫面會隨著相機方向旋轉
//extension UIImagePickerController
//{
//    override open var shouldAutorotate: Bool {
//        return true
//    }
//
//    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return .all
//    }
//}

extension CameraController: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
    resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Swift.Error?) {
        if let error = error { self.photoCaptureCompletionBlock?(nil, error) }
        
        else if let buffer = photoSampleBuffer
            , let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: nil)
            , let image = UIImage(data: data) {
            self.photoCaptureCompletionBlock?(image,nil)
        }
    
        else {
            self.photoCaptureCompletionBlock?(nil, CameraControllerError.unknown)
        }
    }
}

extension CameraController {
    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    public enum CameraPosition {
        case front
        case rear
    }
}

