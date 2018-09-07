//
//  VideoCallViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 04/09/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit

class VideoCallViewController: UIViewController, SINCallDelegate {
    
    @IBOutlet weak var localView: UIView!
    @IBOutlet weak var remoteView: UIView!
    @IBOutlet weak var answerButtonOutlet: UIButton!
    @IBOutlet weak var declineButtonOutlet: UIButton!
    @IBOutlet weak var hangupButtonOutlet: UIButton!
    @IBOutlet weak var speakerButtonOutlet: UIButton!
    @IBOutlet weak var muteButtonOutlet: UIButton!
    @IBOutlet weak var imageViewOutlet: UIImageView!
    @IBOutlet weak var callStatusLabelOutlet: UILabel!
    @IBOutlet weak var fullNameLabelOutlet: UILabel!
    
    
    var incomingCall: SINCall?
    var _call: SINCall!
    var callAnswered = false
    var speaker = false
    var muted = false
    var showButton = true
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        let id = _call.remoteUserId
        getUsersFromFirestore(withIds: [id!]) { (allUsers) in
            
            if allUsers.count > 0 {
                
                let user = allUsers.first!
                self.fullNameLabelOutlet.text = user.fullname
                imageFromData(pictureData: user.avatar, withBlock: { (image) in
                    
                    if image != nil {
                        self.imageViewOutlet.image = image!.circleMasked
                    }
                })
            }
            
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        _call.delegate = self
        
        if _call.direction == SINCallDirection.incoming {
            //show our buttons
            showButtons()
            audioController().enableSpeaker()
            audioController().startPlayingSoundFile(pathForSound(soundName: "incoming"), loop: true)
            
        } else {
            
            callAnswered = true
            audioController().enableSpeaker()
            showButtons()
            
        }
        
    }
    
  
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func videoController() -> SINVideoController {
        
        return appDelegate._client.videoController()
    }
    
    func audioController() -> SINAudioController {
        
        return appDelegate._client.audioController()
    }
    
  
    
    //MARK: SINCall Delegate
    
    func callDidEnd(_ call: SINCall!) {
        print("Sinch Call Ended.")
        videoController().localView().removeFromSuperview()
        videoController().remoteView().removeFromSuperview()
        audioController().stopPlayingSoundFile()
        dismiss(animated: true, completion: nil)
    }
    
    func callDidProgress(_ call: SINCall!) {
       audioController().enableSpeaker()
       audioController().startPlayingSoundFile(pathForSound(soundName: "ringback"), loop: true)
    }
    
    func callDidEstablish(_ call: SINCall!) {
        
        showButtons()
        audioController().stopPlayingSoundFile()
        audioController().enableSpeaker()
        if _call.details.isVideoOffered {
            DispatchQueue.main.async {
                self.localView.addSubview(self.videoController().localView())
                self.localView.contentMode = .scaleAspectFill
                // 1. create a gesture recognizer (tap gesture)
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onTapLocalView(sender:)))
                // 2. add the gesture recognizer to a view
                self.localView.addGestureRecognizer(tapGesture)
                self.toggleButtons()
                
            }
            
        }
        
    }
    
    func callDidAddVideoTrack(_ call: SINCall?) {
        remoteView.addSubview(videoController().remoteView())
        remoteView.contentMode = .scaleAspectFill
        remoteView.frame =  remoteView.bounds
        // 1. create a gesture recognizer (tap gesture)
        let tapGestureRemote = UITapGestureRecognizer(target: self, action: #selector(self.onTapRemoteView(sender:)))
        // 2. add the gesture recognizer to a view
        self.remoteView.addGestureRecognizer(tapGestureRemote)
    }
    
        
    //MARK: IBActions
    
    @IBAction func answerButtonPressed(_ sender: Any) {
        
        callAnswered = true
        showButtons()
        
        _call.answer()
    }
    @IBAction func declineButtonPressed(_ sender: Any) {
        
        print("Decline Call Called")
        _call.hangup()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func hangupButtonPressed(_ sender: Any) {
        print("Hang Up Called")
        _call.hangup()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func muteButtonPressed(_ sender: Any) {
        
        if muted {
            muted = false
            audioController().unmute()
            muteButtonOutlet.setImage(UIImage(named: "mute"), for: .normal)
        } else {
            muted = true
            audioController().mute()
            muteButtonOutlet.setImage(UIImage(named: "muteSelected"), for: .normal)
        }
        
    }
    
    
    @IBAction func speakerButtonPressed(_ sender: Any) {
        
        if !speaker {
            speaker = true
            audioController().enableSpeaker()
            speakerButtonOutlet.setImage(UIImage(named: "speakerSelected"), for: .normal)
        } else {
            speaker = false
            audioController().disableSpeaker()
            speakerButtonOutlet.setImage(UIImage(named: "speaker"), for: .normal)
        }
        
    }
    
    
    
    @objc func onTapLocalView(sender: UITapGestureRecognizer) {
       print("Toggle Camera Position")
       self.videoController().captureDevicePosition = SINToggleCaptureDevicePosition(self.videoController().captureDevicePosition)
        
    }
    
    @objc func onTapRemoteView(sender: UITapGestureRecognizer) {
        print("Toggle Button ")
        toggleButtons()
        
    }
    
    //Helpers
    
    func showButtons() {
        
        if callAnswered {
            declineButtonOutlet.isHidden = true
            answerButtonOutlet.isHidden = true
            hangupButtonOutlet.isHidden = false
            fullNameLabelOutlet.isHidden = true
            callStatusLabelOutlet.isHidden = true
            imageViewOutlet.isHidden = true
            muteButtonOutlet.isHidden = false
            speakerButtonOutlet.isHidden = false
            
            
        } else {
            declineButtonOutlet.isHidden = false
            answerButtonOutlet.isHidden = false
            hangupButtonOutlet.isHidden = true
            fullNameLabelOutlet.isHidden = false
            callStatusLabelOutlet.isHidden = false
            imageViewOutlet.isHidden = false
            muteButtonOutlet.isHidden = true
            speakerButtonOutlet.isHidden = true
            
            
        }
    }
    
    
    func toggleButtons() {
        
        if showButton {
            showButton = false
            declineButtonOutlet.isHidden = true
            answerButtonOutlet.isHidden = true
            hangupButtonOutlet.isHidden = true
            fullNameLabelOutlet.isHidden = true
            callStatusLabelOutlet.isHidden = true
            imageViewOutlet.isHidden = true
            muteButtonOutlet.isHidden = true
            speakerButtonOutlet.isHidden = true
        } else {
            
            showButton = true
            declineButtonOutlet.isHidden = true
            answerButtonOutlet.isHidden = true
            hangupButtonOutlet.isHidden = false
            fullNameLabelOutlet.isHidden = true
            callStatusLabelOutlet.isHidden = true
            imageViewOutlet.isHidden = true
            muteButtonOutlet.isHidden = false
            speakerButtonOutlet.isHidden = false
            
        }
    }
    
    //MARK: Helpers
    
    func pathForSound(soundName: String) -> String {
        
        return Bundle.main.path(forResource: soundName, ofType: "wav")!
    }
    
}
