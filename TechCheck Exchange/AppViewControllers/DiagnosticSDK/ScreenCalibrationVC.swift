//
//  ScreenCalibrationVC.swift
//  InstaCashSDK
//
//  Created by Sameer Khan on 05/07/21.
//

import UIKit
import SwiftyJSON
import AVKit
import CoreMotion
import PopupDialog
import SwiftGifOrigin

class ScreenCalibrationVC: UIViewController {
    
    var screenRetryDiagnosis: (() -> Void)?
    var screenTestDiagnosis: (() -> Void)?
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var countLbl: UILabel!
    @IBOutlet weak var diagnoseProgressView: UIProgressView!
    @IBOutlet weak var headingLbl: UILabel!
    @IBOutlet weak var subHeadingLbl: UILabel!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var testImgView: UIImageView!
    
    @IBOutlet weak var viewGuide: UIView!
    @IBOutlet weak var screenImageView: UIImageView!
    @IBOutlet weak var guideBtn: UIButton!
    @IBOutlet weak var startGuideBtn: UIButton!
    
    var obstacleViews : [UIView] = []
    var flags: [Bool] = []
    var countdownTimer: Timer!
    var totalTime = 40
    var startTest = false
    var isComingFromDiagnosticTestResult = false
    //var resultJSON = JSON()
    
    var audioPlayer: AVAudioPlayer!
    var recording: Recording!
    
    var recordingSession: AVAudioSession!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.setUIElementsProperties()
        }
        
        DispatchQueue.main.async {
            self.checkAudio()
        }
                    
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkVibrator()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkMicrophone()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppOrientationUtility.lockOrientation(.portrait)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    // MARK:- IBActions
    @IBAction func startButtonPressed(_ sender: UIButton) {
        
        self.drawScreenTest()
    }
    
    @IBAction func onClickGuide(_ sender: Any) {
        self.viewGuide.isHidden = false
    }
    
    @IBAction func onClickStart(_ sender: Any) {
        self.viewGuide.isHidden = true
    }
    
    @IBAction func skipButtonPressed(_ sender: UIButton) {
    
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        
        // Prepare the popup assets
        let title = self.getLocalizatioStringValue(key:"Quit Diagnosis")
        let message = self.getLocalizatioStringValue(key:"Are you sure you want to quit?")
        
        // Create the dialog
        let popup = PopupDialog(title: title, message: message, buttonAlignment: .horizontal, transitionStyle: .bounceDown, tapGestureDismissal: false, panGestureDismissal :false)
        
        // Create buttons
        let buttonOne = CancelButton(title: self.getLocalizatioStringValue(key:"Yes")) {
            DispatchQueue.main.async() {
                //self.dismiss(animated: true) {
                    self.NavigateToHomePage()
                //}
            }
        }
        
        let buttonTwo = DefaultButton(title: self.getLocalizatioStringValue(key:"No")) {
            //Do Nothing
            popup.dismiss(animated: true, completion: nil)
        }
        
        // Add buttons to dialog
        // Alternatively, you can use popup.addButton(buttonOne)
        // to add a single button
        popup.addButtons([buttonOne, buttonTwo])
        popup.dismiss(animated: true, completion: nil)
        
        // Customize dialog appearance
        let pv = PopupDialogDefaultView.appearance()
        if UIDevice.current.model.hasPrefix("iPad") {
            pv.titleFont    = UIFont(name: AppBrownFontBold, size: 26)!
            pv.messageFont  = UIFont(name: AppBrownFontRegular, size: 22)!
        }else {
            pv.titleFont    = UIFont(name: AppBrownFontBold, size: 20)!
            pv.messageFont  = UIFont(name: AppBrownFontRegular, size: 16)!
        }
        
        // Customize the container view appearance
        let pcv = PopupDialogContainerView.appearance()
        pcv.cornerRadius    = 10
        pcv.shadowEnabled   = true
        pcv.shadowColor     = .black
        
        // Customize overlay appearance
        let ov = PopupDialogOverlayView.appearance()
        ov.blurEnabled     = true
        ov.blurRadius      = 30
        ov.opacity         = 0.7
        ov.color           = .black
        
        // Customize default button appearance
        let db = DefaultButton.appearance()
        DispatchQueue.main.async {
            db.titleLabel?.textColor = AppThemeColor
        }
        if UIDevice.current.model.hasPrefix("iPad") {
            db.titleFont      = UIFont(name: AppBrownFontRegular, size: 22)!
        }else {
            db.titleFont      = UIFont(name: AppBrownFontRegular, size: 16)!
        }
                
        // Customize cancel button appearance
        let cb = CancelButton.appearance()
        if UIDevice.current.model.hasPrefix("iPad") {
            cb.titleFont      = UIFont(name: AppBrownFontRegular, size: 22)!
        }else {
            cb.titleFont      = UIFont(name: AppBrownFontRegular, size: 16)!
        }
        
        // Present dialog
        self.present(popup, animated: true, completion: nil)
        
    }
    
    // MARK: Custom Methods
    func setUIElementsProperties() {
        
        self.subHeadingLbl.setLineHeight(lineHeight: 3.0)
        self.subHeadingLbl.textAlignment = .center
        
        self.setStatusBarColor(themeColor: AppThemeColor)
        
        self.startBtn.backgroundColor = AppThemeColor
        self.startBtn.layer.cornerRadius = AppBtnCornerRadius
        self.startBtn.setTitleColor(AppBtnTitleColor, for: .normal)
        let fontSize = self.startBtn.titleLabel?.font.pointSize
        self.startBtn.titleLabel?.font = UIFont.init(name: AppSupplyFontMedium, size: fontSize ?? 18.0)
        
        self.countLbl.textColor = AppThemeColor
        self.countLbl.font = UIFont.init(name: AppSupplyFontRegular, size: self.countLbl.font.pointSize)
        self.diagnoseProgressView.progressTintColor = AppThemeColor
        
        
        // MultiLingual
        self.startBtn.setTitle(self.getLocalizatioStringValue(key: "Start").uppercased(), for: .normal)
        //self.titleLbl.text = self.getLocalizatioStringValue(key: "Screen Calibration")
        self.titleLbl.text = self.getLocalizatioStringValue(key: "TECHCHECK® DIAGNOSTICS")
        self.titleLbl.font = UIFont.init(name: AppSupplyFontRegular, size: self.titleLbl.font.pointSize)
        self.headingLbl.text = self.getLocalizatioStringValue(key: "Touch Screen Test")
        self.headingLbl.font = UIFont.init(name: AppBrownFontBold, size: self.headingLbl.font.pointSize)
        self.subHeadingLbl.text = self.getLocalizatioStringValue(key: "Press “START” and run your finger over all the squares until each one turns purple")
        self.subHeadingLbl.font = UIFont.init(name: AppBrownFontRegular, size: self.subHeadingLbl.font.pointSize)
        
        
        //self.screenImageView.loadGif(name: "final_touch")
        
        self.guideBtn.setTitle(self.getLocalizatioStringValue(key: "Guide me").uppercased(), for: .normal)
        self.guideBtn.setTitleColor(AppThemeColor, for: .normal)
        let guideBtnFontSize = self.guideBtn.titleLabel?.font.pointSize
        self.guideBtn.titleLabel?.font = UIFont.init(name: AppBrownFontBold, size: guideBtnFontSize ?? 18.0)
        
        self.startGuideBtn.setTitle(self.getLocalizatioStringValue(key: "Start").uppercased(), for: .normal)
        self.startGuideBtn.backgroundColor = AppThemeColor
        self.startGuideBtn.layer.cornerRadius = AppBtnCornerRadius
        self.startGuideBtn.setTitleColor(AppBtnTitleColor, for: .normal)
        let startGuideBtnFontSize = self.startGuideBtn.titleLabel?.font.pointSize
        self.startGuideBtn.titleLabel?.font = UIFont.init(name: AppSupplyFontMedium, size: startGuideBtnFontSize ?? 18.0)
        
       
    }
    
    func drawScreenTest() {
        
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth:Int = Int(screenSize.width) + 10
        let screenHeight:Int = Int(screenSize.height)
        let widthPerimeterImage:Int =  Int(screenWidth/9)
        let heightPerimeterImage:Int = Int((screenHeight)/14)
        
        var l = 0
        var t = 20
        
        for _ in (0..<14).reversed()
        {
            for _ in (0..<9).reversed()
            {
                let view = LevelView(frame: CGRect(x: l, y: t, width: widthPerimeterImage, height: heightPerimeterImage))
                l = l+widthPerimeterImage
                
                obstacleViews.append(view)
                flags.append(false)
                self.view.addSubview(view)
            }
            l=0
            t=t+heightPerimeterImage
        }
        
        self.startTest = true
        self.startTimer()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.testTouches(touches: touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent!) {
        self.testTouches(touches: touches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    func testTouches(touches: Set<UITouch>) {
        
        // Get the first touch and its location in this view controller's view coordinate system
        let touch = touches.first
        let touchLocation = touch?.location(in: self.view)
        var finalFlag = true
        
        for (index,obstacleView) in obstacleViews.enumerated() {
            // Convert the location of the obstacle view to this view controller's view coordinate system
            let obstacleViewFrame = self.view.convert(obstacleView.frame, from: obstacleView.superview)
            
            // Check if the touch is inside the obstacle view
            if obstacleViewFrame.contains(touchLocation!) {
                flags[index] = true
                let levelLayer = CAShapeLayer()
                levelLayer.path = UIBezierPath(roundedRect: CGRect(x: 0,
                                                                   y: 0,
                                                                   width: obstacleViewFrame.width ,
                                                                   height: obstacleViewFrame.height),
                                               cornerRadius: 0).cgPath
                
                levelLayer.fillColor = AppThemeColor.cgColor
                obstacleView.layer.addSublayer(levelLayer)
                
            }
            
            finalFlag = flags[index]&&finalFlag
        }
        
        if finalFlag && startTest {
            endTimer(type: 1)
        }
        
    }
    
    func startTimer() {
        self.countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
    }
    
    @objc func updateTime() {
        if totalTime != 0 {
            totalTime -= 1
        } else {
            endTimer(type: 0)
        }
    }
    
    func endTimer(type: Int) {
        
        countdownTimer.invalidate()
        
        if type == 1 {
            
            AppUserDefaults.setValue(true, forKey: "screen")
            AppResultJSON["Screen"].int = 1
            
            if AppResultString.contains("SBRK01;") {
                AppResultString = AppResultString.replacingOccurrences(of: "SBRK01;", with: "")
            }
            
            if self.isComingFromDiagnosticTestResult {
                                
                guard let didFinishRetryDiagnosis = self.screenRetryDiagnosis else { return }
                didFinishRetryDiagnosis()
                self.dismiss(animated: false, completion: nil)
                
            }
            else{
                                
                guard let didFinishTestDiagnosis = self.screenTestDiagnosis else { return }
                didFinishTestDiagnosis()
                self.dismiss(animated: false, completion: nil)
                
            }
            
        }else{
            
            let title = self.getLocalizatioStringValue(key: "Touch Screen Test Failed!")
            let message = self.getLocalizatioStringValue(key: "Do you want to retry the test?")
            
            // Create the dialog
            let popup = PopupDialog(title: title, message: message,buttonAlignment: .horizontal, transitionStyle: .bounceDown, tapGestureDismissal: false, panGestureDismissal :false)
            
            // Create buttons
            let buttonOne = DefaultButton(title: self.getLocalizatioStringValue(key: "Yes")) {
                
                popup.dismiss(animated: true, completion: nil)
                
                DispatchQueue.main.async {
                    
                    for v in self.obstacleViews {
                        v.removeFromSuperview()
                    }
                    self.obstacleViews = []
                    self.flags = []
                    self.totalTime = 40
                    self.startTest = false
                    AppResultJSON = JSON()
                    
                    //self.screenImageView.isHidden = false
                }
                
            }
            
            let buttonTwo = CancelButton(title: self.getLocalizatioStringValue(key: "No")) {
                
                AppUserDefaults.setValue(false, forKey: "screen")
                AppResultJSON["Screen"].int = 0
                
                if !AppResultString.contains("SBRK01;") {
                    AppResultString = AppResultString + "SBRK01;"
                }
                
                if self.isComingFromDiagnosticTestResult {
                                        
                    guard let didFinishRetryDiagnosis = self.screenRetryDiagnosis else { return }
                    didFinishRetryDiagnosis()
                    self.dismiss(animated: false, completion: nil)
                }
                else{
                                        
                    guard let didFinishTestDiagnosis = self.screenTestDiagnosis else { return }
                    didFinishTestDiagnosis()
                    self.dismiss(animated: false, completion: nil)
                }
                
            }
            
            
            // Add buttons to dialog
            // Alternatively, you can use popup.addButton(buttonOne)
            // to add a single button
            popup.addButtons([buttonOne, buttonTwo])
            popup.dismiss(animated: true, completion: nil)
            
            // Customize dialog appearance
            let pv = PopupDialogDefaultView.appearance()
            if UIDevice.current.model.hasPrefix("iPad") {
                pv.titleFont    = UIFont(name: AppBrownFontBold, size: 26)!
                pv.messageFont  = UIFont(name: AppBrownFontRegular, size: 22)!
            }else {
                pv.titleFont    = UIFont(name: AppBrownFontBold, size: 20)!
                pv.messageFont  = UIFont(name: AppBrownFontRegular, size: 16)!
            }
            
            // Customize the container view appearance
            let pcv = PopupDialogContainerView.appearance()
            pcv.cornerRadius    = 10
            pcv.shadowEnabled   = true
            pcv.shadowColor     = .black
            
            // Customize overlay appearance
            let ov = PopupDialogOverlayView.appearance()
            ov.blurEnabled     = true
            ov.blurRadius      = 30
            ov.opacity         = 0.7
            ov.color           = .black
            
            // Customize default button appearance
            let db = DefaultButton.appearance()
            DispatchQueue.main.async {
                db.titleLabel?.textColor = AppThemeColor
            }
            if UIDevice.current.model.hasPrefix("iPad") {
                db.titleFont      = UIFont(name: AppBrownFontRegular, size: 22)!
            }else {
                db.titleFont      = UIFont(name: AppBrownFontRegular, size: 16)!
            }
                    
            // Customize cancel button appearance
            let cb = CancelButton.appearance()
            if UIDevice.current.model.hasPrefix("iPad") {
                cb.titleFont      = UIFont(name: AppBrownFontRegular, size: 22)!
            }else {
                cb.titleFont      = UIFont(name: AppBrownFontRegular, size: 16)!
            }
            
            // Present dialog
            self.present(popup, animated: true, completion: nil)
        }
        
    }
    
    
    
    func checkAudio() {
        
        guard let filePath = Bundle.main.path(forResource: "whistle", ofType: "mp3") else {
            print("not found")
            
            return
        }
      
        do {
            
            self.audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: filePath))
            self.audioPlayer.play()

            let outputVol = AVAudioSession.sharedInstance().outputVolume
            print("Device volume is: \(outputVol)")
            
            if(outputVol > 0.36) {
                
                AppUserDefaults.setValue(true, forKey: "Speakers")
                AppResultJSON["Speakers"].int = 1
                
            }else{
                
                AppUserDefaults.setValue(false, forKey: "Speakers")
                AppResultJSON["Speakers"].int = 0
                
                if !AppResultString.contains("CISS07;") {
                    AppResultString = AppResultString + "CISS07;"
                }
                
            }
        } catch let error {
            
            AppUserDefaults.setValue(false, forKey: "Speakers")
            AppResultJSON["Speakers"].int = 0
            
            if !AppResultString.contains("CISS07;") {
                AppResultString = AppResultString + "CISS07;"
            }
            
            print(error.localizedDescription)
        }

        
    }
    
    func checkMicrophone() {
        
        // Recording audio requires a user's permission to stop malicious apps doing malicious things, so we need to request recording permission from the user.
        
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(AVAudioSession.Category.playAndRecord)
            try recordingSession.setActive(true)
            
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        //self.createRecorder()
                        
                        AppUserDefaults.setValue(true, forKey: "Microphone")
                        AppResultJSON["Microphone"].int = 1
                        
                    } else {
                        // failed to record!
                        
                        AppUserDefaults.setValue(false, forKey: "Microphone")
                        AppResultJSON["Microphone"].int = 0
                        
                        if !AppResultString.contains("CISS08;") {
                            AppResultString = AppResultString + "CISS08;"
                        }
                        
                    }
                }
            }
        } catch {
            // failed to record!
            
            AppUserDefaults.setValue(false, forKey: "Microphone")
            AppResultJSON["Microphone"].int = 0
            
            if !AppResultString.contains("CISS08;") {
                AppResultString = AppResultString + "CISS08;"
            }
            
        }
    }
    
    func checkVibrator() {        
        
        let manager = CMMotionManager()
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 0.02
            manager.startDeviceMotionUpdates(to: .main) {
                [weak self] (data: CMDeviceMotion?, error: Error?) in
                if let x = data?.userAcceleration.x,
                    x > 0.03 {
                    
                    print("Device Vibrated at: \(x)")
                    
                    AppUserDefaults.setValue(true, forKey: "Vibrator")
                    AppResultJSON["Vibrator"].int = 1
                    
                    manager.stopDeviceMotionUpdates()
                }
            }
            
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
        }else {
            
            AppUserDefaults.setValue(false, forKey: "Vibrator")
            AppResultJSON["Vibrator"].int = 0
            
            if !AppResultString.contains("CISS13;") {
                AppResultString = AppResultString + "CISS13;"
            }
            
        }
        
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}

class LevelView : UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderWidth = 1.0
        let levelLayer = CAShapeLayer()
        levelLayer.path = UIBezierPath(roundedRect: CGRect(x: 0,
                                                           y: 0,
                                                           width: frame.width,
                                                           height: frame.height),
                                       cornerRadius: 0).cgPath
        levelLayer.fillColor = UIColor.white.cgColor
        self.layer.addSublayer(levelLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Required, but Will not be called in a Playground")
    }
    
}
