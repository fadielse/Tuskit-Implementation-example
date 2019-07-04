//
//  TusKit_Swift4.swift
//  Codingsinubie
//
//  Created by Fadilah Hasan on 04/07/19.
//  Copyright © 2019 Fadielse. All rights reserved.
//

import Foundation

class YOUR_CLASS {
    
    // Variable TUS Session
    var tusSession: TUSSession?
    var uploadStore: TUSUploadStore?
    
    // variable that holds the asset image of the image picker
    var assets: [DKAsset] = []
    
    override func viewDidLoad() {
        let applicationSupportURL: URL? = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        
        
        // TODO: Replace YOUR_UPLOAD_fILE_NAME and YOUR_ENDPOINT_URL
        uploadStore = TUSFileUploadStore(url: (applicationSupportURL?.appendingPathComponent(YOUR_UPLOAD_fILE_NAME))!)
        tusSession = TUSSession(endpoint: YOUR_ENDPOINT_URL, dataStore: uploadStore!, allowsCellularAccess: true)
    }
    
    /**
     image picker function to take pictures to be uploaded
     this function is optional you can make a picker with other libraries for example, the most important asset variable is filled
     */
    func showPicker() {
        let pickerController = DKImagePickerController()
        pickerController.assetGroupTypes = [.smartAlbumUserLibrary, .albumSyncedAlbum, .albumRegular, .any]
        pickerController.assetType = .allPhotos
        pickerController.showsEmptyAlbums = false
        
        pickerController.maxSelectableCount = kMaxPhotoPick - uploadedPhotos.count
        
        pickerController.didSelectAssets = { (assets: [DKAsset]) in
            
            self.assets += assets
            self.startUploadImage(withIndex: self.uploadedPhotos.count)
        }
        
        self.present(pickerController, animated: true, completion: nil)
    }
}

// MARK: - Resumable Upload TUSKit Implementation
extension YOUR_CLASS {
    func startUploadImage(withIndex index: Int) {
        if assets.indices.contains(index) {
            let dataAsset = assets[index]
            
            dataAsset.fetchOriginalImage(false) { originalImage, info in
                let imageData = UIImageJPEGRepresentation(originalImage!, 0.5)
                
                let documentDir: URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.allDomainsMask)[0]
                let fileURl: URL = documentDir.appendingPathComponent(UUID.init().uuidString)
                
                if ((try! imageData?.write(to: fileURl)) != nil) {
                    let header = [
                        "Connection": "keep-alive",
                        "Access-Control-Request-Method": "POST",
                        "Access-Control-Request-Headers": "tus-resumable,upload-length,upload-metadata",
                        "Accept": "/",
                        "Accept-Encoding": "gzip, deflate"
                    ]
                    
                    let upload: TUSResumableUpload = (self.tusSession?.createUpload(fromFile: fileURl, headers: header, metadata: ["":""] ))!
                    
                    upload.progressBlock = {(_ bytesWritten: Int64, _ bytesTotal: Int64) -> Void in
                        // Update your progress bar here
                        print("progress: \(UInt64(bytesWritten)) / \(UInt64(bytesTotal))")
                    }
                    
                    upload.resultBlock = {(_ fileURL: URL) -> Void in
                        // Use the upload url
                        print("url: \(fileURL)")
                        
                        // TODO: Success code
                    }
                    
                    upload.failureBlock = {(_ error: Error?) -> Void in
                        // TODO: Handle the error
                        print("error: \(String(describing: error))")
                    }
                    
                    upload.resume()
                } else {
                    print("Error Write File")
                }
            }
        } else {
            print("error: index not found, asset count: \(assets.count), index: \(index)")
        }
    }
}
