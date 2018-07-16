//
//  AudioViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 15/07/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import Foundation
import IQAudioRecorderController

class AudioViewController {
    
    var delegate: IQAudioRecorderViewControllerDelegate
    
    init(delegate_: IQAudioRecorderViewControllerDelegate){
        delegate = delegate_
    }
    
    func presentAudioRecorder(target: UIViewController) {
        let controller = IQAudioRecorderViewController()
        controller.delegate = delegate
        controller.title = "Recorder"
        controller.maximumRecordDuration = kAUDIOMAXDURATION
        controller.allowCropping = true
        
        target.presentBlurredAudioRecorderViewControllerAnimated(controller)
    }
    
    
    
}
