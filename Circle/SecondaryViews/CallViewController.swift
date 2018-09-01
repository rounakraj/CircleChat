//
//  CallViewController.swift
//  Circle
//
//  Created by Kumar Rounak on 02/09/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import UIKit

class CallViewController: UIViewController, SINCallDelegate {
    
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var declineButtonOutlet: UIButton!
    @IBOutlet weak var endCallButtonOutlet: UIButton!
    @IBOutlet weak var answerButtonOutlet: UIButton!
    @IBOutlet weak var speakerButtonOutlet: UIButton!
    @IBOutlet weak var muteButtonOutlet: UIButton!
    
    var speaker = false
    var muted = false
    var durationTimer: Timer! = nil
    var _call: SINCall!
    
    var callAnswered = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        usernameLabel.text = "Unknown User"
        let id = _call.remoteUserId
        getUsersFromFirestore(withIds: [id!]) { (allUsers) in
            
            if allUsers.count > 0 {
                
                let user = allUsers.first!
                self.usernameLabel.text = user.fullname
                imageFromData(pictureData: user.avatar, withBlock: { (image) in
                    
                    if image != nil {
                        self.avatarImageView.image = image!.circleMasked
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
            audioController().startPlayingSoundFile(pathForSound(soundName: "incoming"), loop: true)
            
        } else {
            
            callAnswered = true
            //show buttons
            setCallStatusText(text: "Calling...")
            showButtons()
            
        }
    }
    
    
    func audioController() -> SINAudioController {
        
        return appDelegate._client.audioController()
    }
    
    func setCall(call: SINCall) {
        _call = call
        _call.delegate = self
    }
    //MARK: IBActions
    
    
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
    
    
    @IBAction func answerButtonPressed(_ sender: Any) {
        callAnswered = true
        showButtons()
        audioController().stopPlayingSoundFile()
        _call.answer()
    }
    
    
    @IBAction func hangUpButtonPressed(_ sender: Any) {
        _call.hangup()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func declineButtonPressed(_ sender: Any) {
        _call.hangup()
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: SINCallDelegate
    
    func callDidProgress(_ call: SINCall!) {
        setCallStatusText(text: "Ringing...")
        audioController().startPlayingSoundFile(pathForSound(soundName: "ringback"), loop: true)
    }
    
    func callDidEstablish(_ call: SINCall!) {
        //start time
        startCallDurationTimer()
        showButtons()
        audioController().stopPlayingSoundFile()
        
    }
    
    func callDidEnd(_ call: SINCall!) {
        audioController().stopPlayingSoundFile()
        //stop call timer
        stopCallDurationTimer()
        dismiss(animated: true, completion: nil)
    }
    
    
    
    //MARK: TIMER
    
    @objc func onDuration() {
        
        let duration = Date().timeIntervalSince(_call.details.establishedTime)
        //update timer label
        updateTimerLabel(seconds: Int(duration))
        
    }
    
    func updateTimerLabel(seconds: Int) {
        let min = String(format: "%02d", (seconds / 60))
        let sec = String(format: "%02d", (seconds % 60))
        setCallStatusText(text: "\(min) : \(sec)")
        
    }
    
    func startCallDurationTimer() {
        self.durationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.onDuration), userInfo: nil, repeats: true)
        
    }
    
    func stopCallDurationTimer() {
        
        if durationTimer != nil {
            durationTimer.invalidate()
        }
    }
    
    //MARK: UpdateUI
    
    func setCallStatusText(text: String){
        statusLabel.text = text
    }
    
    func showButtons() {
        
        if callAnswered {
            declineButtonOutlet.isHidden = true
            endCallButtonOutlet.isHidden = false
            answerButtonOutlet.isHidden = true
            muteButtonOutlet.isHidden = false
            speakerButtonOutlet.isHidden = false
        } else {
            declineButtonOutlet.isHidden = false
            endCallButtonOutlet.isHidden = true
            answerButtonOutlet.isHidden = false
            muteButtonOutlet.isHidden = true
            speakerButtonOutlet.isHidden = true
            
        }
    }
    
    
    //MARK: Helpers
    
    func pathForSound(soundName: String) -> String {
        
        return Bundle.main.path(forResource: soundName, ofType: "wav")!
    }
}
