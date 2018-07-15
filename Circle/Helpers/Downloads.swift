//
//  Downloads.swift
//  Circle
//
//  Created by Kumar Rounak on 15/07/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import Foundation
import FirebaseStorage
import Firebase
import MBProgressHUD
import AVFoundation

let storage = Storage.storage()

//MARK: Upload Image


func uploadImage(image: UIImage, chatRoomId: String, view: UIView, completion: @escaping (_ imageLink: String?) -> Void) {
    
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    progressHUD.mode = .determinateHorizontalBar
    
    let dateString = dateFormatter().string(from: Date())
    
    let photoFileName =  "CircleChat/PictureMessages/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".jpg"
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(photoFileName)
    
    let imageData = image.jpegData(compressionQuality: 0.7)
    
    var task: StorageUploadTask!
    task = storageRef.putData(imageData!, metadata: nil, completion: { (metadata, error) in
        
        task.removeAllObservers()
        progressHUD.hide(animated:  true)
        
        
        if error != nil{
            print("Error uploading the image \(error!.localizedDescription)")
            return
        }
        
        storageRef.downloadURL(completion: { (url, error) in
            
            guard let downloadURl = url else {
                completion(nil)
                return
            }
            completion(downloadURl.absoluteString)
            
        })
    })
    
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
        
        
    }
}



//MARK: Upload Video

func uploadVideo(video: NSData, chatRoomId: String, view: UIView, completion: @escaping (_ videoLink: String?) -> Void) {
    
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    progressHUD.mode = .determinateHorizontalBar
    
    let dateString = dateFormatter().string(from: Date())
    
    let videoFileName =  "CircleChat/VideoMessages/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".mov"
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(videoFileName)
    
    var task: StorageUploadTask!
    task = storageRef.putData(video as Data, metadata: nil, completion: { (metadata, error) in
        
        task.removeAllObservers()
        progressHUD.hide(animated:  true)
        
        
        if error != nil{
            print("Error uploading the video \(error!.localizedDescription)")
            return
        }
        
        storageRef.downloadURL(completion: { (url, error) in
            
            guard let downloadURl = url else {
                completion(nil)
                return
            }
            completion(downloadURl.absoluteString)
            
        })
    })
    
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
        
        
    }
    print("Video Uploaded\n")
}


//MARK: HELPERS


//CreateThumbNail

func videoThumbNail(video: NSURL) -> UIImage {
    let asset = AVURLAsset(url: video as URL, options: nil)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    
    let time = CMTimeMakeWithSeconds(0.5, preferredTimescale: 1000)
    var actualTime = CMTime.zero
    
    var image: CGImage?
    do {
        image = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
        
    } catch let error as NSError {
        print("Error creating thumbnail")
    }
    
    let thumbNail = UIImage(cgImage: image!)
    
    return thumbNail
}

//Download Image

func downloadImage(imageUrl: String, completion: @escaping (_ image: UIImage?) -> Void) {

    let imageURL = NSURL(string: imageUrl)
    let imageFileName = (imageUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    
    
    if fileExistsAtPath(path: imageFileName) {
        //exist
        
        if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(fileName: imageFileName)) {
            completion(contentsOfFile)
        }
        else {
            print("Could not generate the image.")
            completion(nil)
        }
    }
    else {
        //does not exist
        
        let downloadQueue = DispatchQueue(label: "imageDownloadQueue")
        downloadQueue.async {
            let data = NSData(contentsOf: imageURL! as URL)
            
            if data != nil {
                var docURL = getDocumnetsURL()
                docURL = docURL.appendingPathComponent(imageFileName, isDirectory: false)
                data!.write(to: docURL, atomically: true)
                let imageToReturn = UIImage(data: data! as Data)
                DispatchQueue.main.async {
                    completion(imageToReturn!)
                }
                
            } else {
                DispatchQueue.main.async {
                    print("No Image in DataBase")
                    completion(nil)
                }
            }
        }
        
    }
}



//Download Video


func downloadVideo(videoUrl: String, completion: @escaping (_ isReadyToPlay: Bool, _ videoFileName: String) -> Void) {
    
    let videoURL = NSURL(string: videoUrl)
    let videoFileName = (videoUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    
    
    if fileExistsAtPath(path: videoFileName) {
        //exist
        
       completion(true, videoFileName)
    }
    else {
        //does not exist
        
        let downloadQueue = DispatchQueue(label: "videoDownloadQueue")
        downloadQueue.async {
            let data = NSData(contentsOf: videoURL! as URL)
            
            if data != nil {
                var docURL = getDocumnetsURL()
                docURL = docURL.appendingPathComponent(videoFileName, isDirectory: false)
                data!.write(to: docURL, atomically: true)
               
                DispatchQueue.main.async {
                    completion(true, videoFileName)
                }
                
            } else {
                DispatchQueue.main.async {
                    print("No Video in DataBase")
                   
                }
            }
        }
        
    }
}

func fileInDocumentsDirectory(fileName: String) -> String {
    
    let fileURL = getDocumnetsURL().appendingPathComponent(fileName)
    
    return fileURL.path
}


func getDocumnetsURL() -> URL {
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    return documentsURL!
    
}

func fileExistsAtPath(path: String) -> Bool

{
    var doesExist = false
    let filePath = fileInDocumentsDirectory(fileName: path)
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: filePath){
        doesExist = true
    }else {
        doesExist = false
    }
    
    return doesExist
}

