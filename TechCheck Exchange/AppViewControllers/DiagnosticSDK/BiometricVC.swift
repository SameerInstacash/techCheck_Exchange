//
//  BiometricVC.swift
//  InstaCashSDK
//
//  Created by Sameer Khan on 05/07/21.
//

import UIKit
import PopupDialog
import BiometricAuthentication

class BiometricVC: UIViewController {

    var biometricRetryDiagnosis: (() -> Void)?
    var biometricTestDiagnosis: (() -> Void)?
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var countLbl: UILabel!
    @IBOutlet weak var diagnoseProgressView: UIProgressView!
    @IBOutlet weak var headingLbl: UILabel!
    @IBOutlet weak var subHeading1Lbl: UILabel!
    @IBOutlet weak var subHeading2Lbl: UILabel!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var skipBtn: UIButton!
    @IBOutlet weak var testImgView: UIImageView!
    
    var isComingFromDiagnosticTestResult = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.checkDeviceSupportOfBiometric()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.setUIElementsProperties()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppOrientationUtility.lockOrientation(.portrait)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    // MARK: Custom Methods
    func setUIElementsProperties() {
        
        self.subHeading2Lbl.setLineHeight(lineHeight: 3.0)
        self.subHeading2Lbl.textAlignment = .center
        
        self.setStatusBarColor(themeColor: AppThemeColor)
        
        self.startBtn.backgroundColor = AppThemeColor
        self.startBtn.layer.cornerRadius = AppBtnCornerRadius
        self.startBtn.setTitleColor(AppBtnTitleColor, for: .normal)
        let fontSizeStart = self.startBtn.titleLabel?.font.pointSize
        self.startBtn.titleLabel?.font = UIFont.init(name: AppSupplyFontMedium, size: fontSizeStart ?? 18.0)
        
        self.skipBtn.backgroundColor = AppThemeColor
        self.skipBtn.layer.cornerRadius = AppBtnCornerRadius
        self.skipBtn.setTitleColor(AppBtnTitleColor, for: .normal)
        let fontSizeSkip = self.skipBtn.titleLabel?.font.pointSize
        self.skipBtn.titleLabel?.font = UIFont.init(name: AppSupplyFontMedium, size: fontSizeSkip ?? 18.0)
        
        self.countLbl.textColor = AppThemeColor
        self.countLbl.font = UIFont.init(name: AppSupplyFontRegular, size: self.countLbl.font.pointSize)
        self.diagnoseProgressView.progressTintColor = AppThemeColor
    
        
        // MultiLingual
        self.startBtn.setTitle(self.getLocalizatioStringValue(key: "Start").uppercased(), for: .normal)
        self.skipBtn.setTitle(self.getLocalizatioStringValue(key: "Skip").uppercased(), for: .normal)
        //self.titleLbl.text = self.getLocalizatioStringValue(key: "Biometric Authentication")
        self.titleLbl.text = self.getLocalizatioStringValue(key: "TECHCHECK® DIAGNOSTICS")
        self.titleLbl.font = UIFont.init(name: AppSupplyFontRegular, size: self.titleLbl.font.pointSize)
        
    }
    
    func checkDeviceSupportOfBiometric() {
        
        DispatchQueue.main.async {
            
            if BioMetricAuthenticator.canAuthenticate() {
                
                if BioMetricAuthenticator.shared.faceIDAvailable() {
                    
                    print("hello faceid available")
                    
                    self.testImgView.image = #imageLiteral(resourceName: "face-id")
                    
                    self.headingLbl.text = self.getLocalizatioStringValue(key: "Checking Face-Id")
                    self.headingLbl.font = UIFont.init(name: AppBrownFontBold, size: self.headingLbl.font.pointSize)
                    self.subHeading1Lbl.text = self.getLocalizatioStringValue(key: "First, enable the face-Id function on your phone")
                    self.subHeading1Lbl.font = UIFont.init(name: AppBrownFontRegular, size: self.subHeading1Lbl.font.pointSize)
                    self.subHeading2Lbl.text = self.getLocalizatioStringValue(key: "During the test place your face on the scanner as you normally would to unlock your phone")
                    self.subHeading2Lbl.font = UIFont.init(name: AppBrownFontRegular, size: self.subHeading2Lbl.font.pointSize)
                
                }else {
                    
                    self.testImgView.image = #imageLiteral(resourceName: "fingerprint")
                    
                    self.headingLbl.text = self.getLocalizatioStringValue(key: "Checking fingerprint scanner")
                    self.headingLbl.font = UIFont.init(name: AppBrownFontBold, size: self.headingLbl.font.pointSize)
                    self.subHeading1Lbl.text = self.getLocalizatioStringValue(key: "First, please enable fingerprint function")
                    self.subHeading1Lbl.font = UIFont.init(name: AppBrownFontRegular, size: self.subHeading1Lbl.font.pointSize)
                    self.subHeading2Lbl.text = self.getLocalizatioStringValue(key: "Then you will place your finger on the fingerprint scanner like you normally would during unlock")
                    self.subHeading2Lbl.font = UIFont.init(name: AppBrownFontRegular, size: self.subHeading2Lbl.font.pointSize)
                 
                }
            }else {
                
                DispatchQueue.main.async {
                    
                    let alertController = UIAlertController (title: self.getLocalizatioStringValue(key: "Enable Biometric") , message: self.getLocalizatioStringValue(key: "Go to Settings -> Touch ID & Passcode"), preferredStyle: .alert)
                    
                    let settingsAction = UIAlertAction(title: self.getLocalizatioStringValue(key: "Settings"), style: .default) { (_) -> Void in
                        
                        guard let settingsUrl = URL(string: "App-Prefs:root") else {
                            return
                        }
                        
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            if #available(iOS 10.0, *) {
                                
                                UIApplication.shared.open(settingsUrl, options: [:]) { (success) in
                                    
                                }
                                
                            } else {
                                // Fallback on earlier versions
                                
                                UIApplication.shared.openURL(settingsUrl)
                            }
                        }
                    }
                    
                    alertController.addAction(settingsAction)
                    
                    let cancelAction = UIAlertAction(title: self.getLocalizatioStringValue(key: "Cancel"), style: .default) { (_) -> Void in
                        
                        AppResultJSON["Fingerprint Scanner"].int = 0
                        AppUserDefaults.setValue(false, forKey: "Fingerprint Scanner")
                        
                        if !AppResultString.contains("CISS12;") {
                            AppResultString = AppResultString + "CISS12;"
                        }
                        
                        if self.isComingFromDiagnosticTestResult {
                            
                            guard let didFinishRetryDiagnosis = self.biometricRetryDiagnosis else { return }
                            didFinishRetryDiagnosis()
                            self.dismiss(animated: false, completion: nil)
                            
                        }
                        else{
                            
                            guard let didFinishTestDiagnosis = self.biometricTestDiagnosis else { return }
                            didFinishTestDiagnosis()
                            self.dismiss(animated: false, completion: nil)
                            
                        }
                    }
                    
                    alertController.addAction(cancelAction)
                    
                    alertController.popoverPresentationController?.sourceView = self.view
                    alertController.popoverPresentationController?.sourceRect = self.view.bounds
                    
                    self.present(alertController, animated: true, completion: nil)
                    
                }
                
                
                //*
                switch UIDevice.current.currentModelName {
                case "iPhone X","iPhone XR","iPhone XS","iPhone XS Max","iPhone 11","iPhone 11 Pro","iPhone 11 Pro Max","iPhone 12 mini","iPhone 12","iPhone 12 Pro","iPhone 12 Pro Max", "iPhone 13 Mini", "iPhone 13", "iPhone 13 Pro", "iPhone 13 Pro Max", "iPad Pro (11-inch) (1st generation)", "iPad Pro (11-inch) (2nd generation)", "iPad Pro (12.9-inch) (3rd generation)", "iPad Pro (12.9-inch) (4th generation)" :
                                        
                    self.testImgView.image = #imageLiteral(resourceName: "face-id")
                    
                    self.headingLbl.text = self.getLocalizatioStringValue(key: "Checking Face-Id")
                    self.headingLbl.font = UIFont.init(name: AppBrownFontBold, size: self.headingLbl.font.pointSize)
                    self.subHeading1Lbl.text = self.getLocalizatioStringValue(key: "First, enable the face-Id function on your phone")
                    self.subHeading1Lbl.font = UIFont.init(name: AppBrownFontRegular, size: self.subHeading1Lbl.font.pointSize)
                    self.subHeading2Lbl.text = self.getLocalizatioStringValue(key: "During the test place your face on the scanner as you normally would to unlock your phone")
                    self.subHeading2Lbl.font = UIFont.init(name: AppBrownFontRegular, size: self.subHeading2Lbl.font.pointSize)
                    
                   
                    break
                default:
                    
                    break
                }
                //*/
                
                
            }
            
        }
        
    }
    
    // MARK:- IBActions
    @IBAction func startButtonPressed(_ sender: UIButton) {
        
        if sender.titleLabel?.text == self.getLocalizatioStringValue(key:"Start").uppercased() {
            self.startBtn.setTitle(self.getLocalizatioStringValue(key:"Skip").uppercased(), for: .normal)
            
            self.startTest()
        }else {
            self.skipButtonPressed(sender)
        }
        
    }
    
    func startTest() {
        
        BioMetricAuthenticator.authenticateWithBioMetrics(reason: "") { (result) in
            
            switch result {
            case .success( _):
                print("Authentication Successful")
                
                AppResultJSON["Fingerprint Scanner"].int = 1
                AppUserDefaults.setValue(true, forKey: "Fingerprint Scanner")
                
                if AppResultString.contains("CISS12;") {
                    AppResultString = AppResultString.replacingOccurrences(of: "CISS12;", with: "")
                }
                
                if self.isComingFromDiagnosticTestResult {
                    
                    guard let didFinishRetryDiagnosis = self.biometricRetryDiagnosis else { return }
                    didFinishRetryDiagnosis()
                    self.dismiss(animated: false, completion: nil)
                    
                }
                else{
                    
                    guard let didFinishTestDiagnosis = self.biometricTestDiagnosis else { return }
                    didFinishTestDiagnosis()
                    self.dismiss(animated: false, completion: nil)
                    
                }
                
            case .failure(let error):
                print("Authentication Failed")
                
                
                // do nothing on canceled
                if error == .canceledByUser || error == .canceledBySystem {
            
                    return
                }
                
                // device does not support biometric (face id or touch id) authentication
                else if error == .biometryNotAvailable {
                    
                    self.showaAlert(message: error.message())
                }
                
                // show alternatives on fallback button clicked
                else if error == .fallback {
                    
                    // here we're entering username and password
                    self.showaAlert(message: error.message())
                    
                }
                
                // No biometry enrolled in this device, ask user to register fingerprint or face
                else if error == .biometryNotEnrolled {
                    
                    //self!.btnScanFingerPrint.isHidden = false
                    
                    let alertController = UIAlertController (title: self.getLocalizatioStringValue(key: "Enable Biometric") , message: self.getLocalizatioStringValue(key: "Go to Settings -> Touch ID & Passcode"), preferredStyle: .alert)
                    
                    let settingsAction = UIAlertAction(title: self.getLocalizatioStringValue(key: "Settings"), style: .default) { (_) -> Void in
                        
                        guard let settingsUrl = URL(string: "App-Prefs:root") else {
                            return
                        }
                        
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            if #available(iOS 10.0, *) {
                                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                    
                                })
                            } else {
                                // Fallback on earlier versions
                                UIApplication.shared.openURL(settingsUrl)
                            }
                        }
                    }
                    
                    alertController.addAction(settingsAction)
                    let cancelAction = UIAlertAction(title: self.getLocalizatioStringValue(key: "Cancel"), style: .default, handler: nil)
                    alertController.addAction(cancelAction)
                    
                    alertController.popoverPresentationController?.sourceView = self.view
                    alertController.popoverPresentationController?.sourceRect = self.view.bounds
                    
                    self.present(alertController, animated: true, completion: nil)
                   
                }
                
                // Biometry is locked out now, because there were too many failed attempts.
                // Need to enter device passcode to unlock.
                else if error == .biometryLockedout {
                    // show passcode authentication
                    
                    self.showaAlert(message: error.message())
                }
                
                // show error on authentication failed
                else {
                    
                    // Alert.showAlert(strMessage: error.message() as NSString, Onview: self!)
                    AppResultJSON["Fingerprint Scanner"].int = 0
                    AppUserDefaults.setValue(false, forKey: "Fingerprint Scanner")
                    
                    if !AppResultString.contains("CISS12;") {
                        AppResultString = AppResultString + "CISS12;"
                    }
                    
                    if self.isComingFromDiagnosticTestResult {
                        
                        guard let didFinishRetryDiagnosis = self.biometricRetryDiagnosis else { return }
                        didFinishRetryDiagnosis()
                        self.dismiss(animated: false, completion: nil)
                        
                    }
                    else{
                        
                        guard let didFinishTestDiagnosis = self.biometricTestDiagnosis else { return }
                        didFinishTestDiagnosis()
                        self.dismiss(animated: false, completion: nil)
                        
                    }
                    
                    
                }
                
            }
            
        }
                      
    }
    
    @IBAction func skipButtonPressed(_ sender: UIButton) {
        
        // Prepare the popup assets
        let title = self.getLocalizatioStringValue(key: "Biometric Authentication Test")
        let message = self.getLocalizatioStringValue(key: "If you skip this test there would be a substantial decline in the price offered.") + " " + self.getLocalizatioStringValue(key: "Do you still want to skip?")
        
        // Create the dialog
        let popup = PopupDialog(title: title, message: message,buttonAlignment: .horizontal, transitionStyle: .bounceDown, tapGestureDismissal: false, panGestureDismissal :false)
        
        // Create buttons
        let buttonOne = CancelButton(title: self.getLocalizatioStringValue(key: "Yes")) {
            
            AppResultJSON["Fingerprint Scanner"].int = -1
            AppUserDefaults.setValue(false, forKey: "Fingerprint Scanner")
            
            if !AppResultString.contains("CISS12;") {
                AppResultString = AppResultString + "CISS12;"
            }
            
            if self.isComingFromDiagnosticTestResult {
                
                guard let didFinishRetryDiagnosis = self.biometricRetryDiagnosis else { return }
                didFinishRetryDiagnosis()
                self.dismiss(animated: false, completion: nil)
                
            }
            else{
                
                guard let didFinishTestDiagnosis = self.biometricTestDiagnosis else { return }
                didFinishTestDiagnosis()
                self.dismiss(animated: false, completion: nil)
                
            }
                       
        }
        
        let buttonTwo = DefaultButton(title: self.getLocalizatioStringValue(key: "No")) {
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


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
}
