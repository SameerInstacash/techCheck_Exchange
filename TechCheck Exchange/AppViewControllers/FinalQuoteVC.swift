//
//  FinalQuoteVC.swift
//  TechCheck Exchange
//
//  Created by Sameer Khan on 14/07/21.
//

import UIKit
import JGProgressHUD
import SwiftyJSON
import Alamofire
import AlamofireImage
import Luminous
import BiometricAuthentication
import DKCamera

class FinalQuoteVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var deviceView: UIView!
    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var lblDeviceBrand: UILabel!
    @IBOutlet weak var lblDeviceName: UILabel!
    @IBOutlet weak var lblOrderRef: UILabel!
    @IBOutlet weak var lblQuoteAmount: UILabel!
    @IBOutlet weak var btnFinish: UIButton!
    @IBOutlet weak var btnUploadId: UIButton!
    @IBOutlet weak var lblYouCouldBe: UILabel!
    @IBOutlet weak var lblGetUpto: UILabel!
    
    @IBOutlet weak var quoteTableView: UITableView!
    @IBOutlet weak var quoteTableViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var skipView: UIView!
    @IBOutlet weak var skipViewHeightConstraint : NSLayoutConstraint!
    @IBOutlet weak var skipViewTopConstraint : NSLayoutConstraint!
    @IBOutlet weak var skipTableView: UITableView!
    @IBOutlet weak var btnReturnTests: UIButton!
    
    
    let hud = JGProgressHUD()
    let reachability: Reachability? = Reachability()
    var metaDetails = JSON()
    var currentOrderId = ""
    var arrFailedAndSkipedTest = [ModelCompleteDiagnosticFlow]()
    
    var arrQuestion = [String]()
    var arrAnswer = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if reachability?.connection.description != "No Connection" {
            self.getpriceCalculation()
        }else {
            self.showaAlert(message: self.getLocalizatioStringValue(key: "Please Check Internet connection."))
        }

        DispatchQueue.main.async {
            self.setDeviceData()
            self.setUIElements()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.skipTableView.register(UINib(nibName: "SkipTestCell", bundle: nil), forCellReuseIdentifier: "SkipTestCell")
        self.quoteTableView.register(UINib(nibName: "ResultCell", bundle: nil), forCellReuseIdentifier: "ResultCell")
        
        
        self.quoteTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        
        self.createTableFromPassFailedTests()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        self.quoteTableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    //MARK:- IBAction
    @IBAction func backBtnPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func finishBtnPressed(_ sender: UIButton) {
        //self.NavigateToHomePage()
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "EndGameVC") as! EndGameVC
        vc.orderId = self.currentOrderId
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func uploadIdBtnPressed(_ sender: UIButton) {
        
        let camera = DKCamera()
        
        camera.didCancel = {
            self.dismiss(animated: true, completion: nil)
        }
        
        camera.didFinishCapturingImage = { (image: UIImage?, metadata: [AnyHashable : Any]?) in
        
            DispatchQueue.main.async {
                
                self.dismiss(animated: true, completion: nil)
                
                let newImage = self.resizeImage(image: image!, newWidth: 800)
                let backgroundImage = newImage
                let watermarkImage = #imageLiteral(resourceName: "watermark")
                UIGraphicsBeginImageContextWithOptions(backgroundImage.size, false, 0.0)
                backgroundImage.draw(in: CGRect(x: 0.0, y: 0.0, width: backgroundImage.size.width, height: backgroundImage.size.height))
                watermarkImage.draw(in: CGRect(x: 0.0, y: 0.0, width: watermarkImage.size.width, height: backgroundImage.size.height))
                
                let result = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
               
                let imageData:Data = (result ?? UIImage()).jpegData(compressionQuality: 1.0) ?? Data()
                
                let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
                
                self.uploadIdProof(photoStr: strBase64)
                
            }
            
        }
        
        self.present(camera, animated: true, completion: nil)
    }
    
    @IBAction func returnTestsBtnPressed(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "HomeVC") as! HomeVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK:- Custom Methods
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
  
    func setUIElements() {
        
        self.lblYouCouldBe.setLineHeight(lineHeight: 3.0)
        self.lblYouCouldBe.textAlignment = .left
        
        self.lblGetUpto.setLineHeight(lineHeight: 3.0)
        self.lblGetUpto.textAlignment = .left
        
        self.setStatusBarColor(themeColor: AppThemeColor)
        
        self.lblQuoteAmount.layer.cornerRadius = AppBtnCornerRadius
        self.lblQuoteAmount.layer.borderWidth = 1.0
        self.lblQuoteAmount.layer.borderColor = AppThemeColor.cgColor
        
        self.deviceView.layer.cornerRadius = AppBtnCornerRadius
        self.btnFinish.layer.cornerRadius = AppBtnCornerRadius
        self.btnUploadId.layer.cornerRadius = AppBtnCornerRadius
        
        self.quoteTableView.layer.cornerRadius = AppBtnCornerRadius
        self.skipView.layer.cornerRadius = AppBtnCornerRadius
        self.btnReturnTests.layer.cornerRadius = AppBtnCornerRadius
        
    }
    
    func setDeviceData() {
                
        if let pBrand = AppUserDefaults.string(forKey: "product_brand") {
            self.lblDeviceBrand.text = pBrand
        }
        
        if let pName = AppUserDefaults.string(forKey: "productName") {
            self.lblDeviceName.text = pName.replacingOccurrences(of: "Apple ", with: "")
        }else {
            self.lblDeviceName.text = ""
        }
        
        if let pImage = AppUserDefaults.string(forKey: "productImage") {
            if let imgUrl = URL(string: pImage) {
                self.deviceImageView.af.setImage(withURL: imgUrl)
            }
        }
    }
        
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if(keyPath == "contentSize"){
            if let newvalue = change?[.newKey]
            {
                let newsize  = newvalue as! CGSize
                self.quoteTableViewHeightConstraint.constant = newsize.height + 0.0
            }
        }
    }
    
    //MARK:- Web Service Methods
    func showHudLoader(msg:String) {
        hud.textLabel.text = msg
        hud.backgroundColor = #colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 0.4)
        hud.show(in: self.view)
    }
    
    func getpriceCalculation() {
        
        var IMEI = ""
        var productId = ""
        var storeCode = ""
        
        if let pId = AppUserDefaults.string(forKey: "product_id") {
            productId = pId
        }
        
        if let sCode = AppUserDefaults.string(forKey: "store_code") {
            storeCode = sCode
        }
        
        if let imei = AppUserDefaults.value(forKey: "imei_number") as? String {
            IMEI = imei
        }
        
        var params = [String : Any]()
        params = ["userName" : AppUserName,
                  "apiKey" : AppApiKey,
                  "imei" : IMEI,
                  "isAppCode" : "1",
                  "str" : AppResultString,
                  "storeCode" : storeCode,
                  "productId" : productId]
        
        //print("params = \(params)")
    
        self.showHudLoader(msg: "Getting Price...")
        
        let webService = AF.request(kPriceCalcNewURL, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: nil, interceptor: nil, requestModifier: nil)
        webService.responseJSON { (responseData) in
            
            self.hud.dismiss()
            //print(responseData.value as? [String:Any] ?? [:])
            
            switch responseData.result {
            case .success(_):
                                
                do {
                    let json = try JSON(data: responseData.data ?? Data())
                    
                    if json["status"] == "Success" {
                        
                        if  let offerpriceString = json["msg"].string {
                                                        
                            DispatchQueue.main.async {
                                
                                let finalSummaryText = json["productDescription"].stringValue
                                var arrSummaryString : [String?] = finalSummaryText.components(separatedBy: ";")
                                
                                var arrItem = [""]
                                
                                for _ in arrSummaryString {
                                    if let ind = arrSummaryString.firstIndex(of: "") {
                                        arrSummaryString.remove(at: ind)
                                    }
                                }
                                
                                for item in arrSummaryString {
                                    arrItem = item?.components(separatedBy: "->") ?? []
                                    
                                    if arrItem.count > 1 {
                                        self.arrQuestion.append(arrItem[0])
                                        self.arrAnswer.append(arrItem[1])
                                    }else {
                                        let pre = self.arrAnswer.last
                                        let val = (pre ?? "") + " & " + arrItem[0]
                                        let key = self.arrQuestion.last
                                        
                                        self.arrQuestion.removeLast()
                                        self.arrAnswer.removeLast()
                                        
                                        self.arrQuestion.append(key ?? "")
                                        self.arrAnswer.append(val)
                                    }
                                }
                                
                                    self.quoteTableView.dataSource = self
                                    self.quoteTableView.delegate = self
                                    self.quoteTableView.reloadData()
                                
                            }
                            
                            
                            let jsonString = AppUserDefaults.string(forKey: "currencyJson") ?? ""
                            var multiplier : Float = 1.0
                            var symbol : String = "₹"
                            var curCode : String = "INR"
                            let symbolNew = json["currency"].string
                            
                            if let dataFromString = jsonString.data(using: .utf8, allowLossyConversion: false) {
                                
                                print("currency JSON")
                                let currencyJson = try JSON(data: dataFromString)
                                multiplier = Float(currencyJson["Conversion Rate"].stringValue) ?? 0
                                print("multiplier: \(multiplier)")
                                symbol = currencyJson["Symbol"].stringValue
                                curCode = currencyJson["Code"].stringValue
                                
                            }else{
                                print("No values")
                            }
                            
                            var diagnosisChargeString = Float()
                            DispatchQueue.main.async() {
                                
                                if let type = UserDefaults.standard.value(forKey: "storeType") as? Int {
                                    if type == 0 {
                                        diagnosisChargeString = Float(json["diagnosisCharges"].intValue)
                                    }else {
                                        diagnosisChargeString = Float(json["pawn"].intValue)
                                    }
                                }
                                
                                
                                if let online = UserDefaults.standard.value(forKey: "tradeOnline") as? Int {
                                    if online == 0 {
                                        //self.tradeInBtn.isHidden = true
                                    }else {
                                        //self.tradeInBtn.isHidden = false
                                    }
                                }
                            }
                            
                            if symbol != symbolNew {
                                diagnosisChargeString = diagnosisChargeString * multiplier
                            }
                            
                            var offer = Float(offerpriceString)!
                            if curCode != symbolNew {
                                offer = offer * multiplier
                            }
                            
                            let payable = offer - diagnosisChargeString
                            print("payable: \(offer - diagnosisChargeString) ")
                            
                            DispatchQueue.main.async() {
                                
                                self.saveResult(price: offerpriceString)
                                
                                if (json["deviceStatusFlag"].exists() && json["deviceStatusFlag"].intValue == 1)
                                {
                                    self.lblQuoteAmount.text = json["deviceStatus"].stringValue

                                }else{
                                    
                                    //"Offered price " + "\(symbol)\(Int(payable))"
                                    self.lblQuoteAmount.text = "\(symbol)\(Int(payable))"
                                    
                                }
                                
                            }
                            
                        }
                        
                    }else {
                        self.showaAlert(message: json["msg"].stringValue)
                    }
                    
                }catch {
                    self.showaAlert(message: self.getLocalizatioStringValue(key: "JSON Exception"))
                }
                
                break
            case .failure(_):
                print(responseData.error ?? NSError())
                self.showaAlert(message: self.getLocalizatioStringValue(key: "Something went wrong!!"))
                break
            }
      
        }
        
    }
    
    func saveResult(price: String) {
        
        var netType = "Mobile"
        if Luminous.Network.isConnectedViaWiFi {
            netType = "Wifi"
        }
        metaDetails["currentCountry"].string = Luminous.Locale.currentCountry
        metaDetails["Internet  Type"].string = netType
        metaDetails["Internet  SSID"].string = Luminous.Network.SSID
        metaDetails["Internet Availability"].bool = Luminous.Network.isInternetAvailable
        metaDetails["Carrier Name"].string = Luminous.Carrier.name
        metaDetails["Carrier MCC"].string = Luminous.Carrier.mobileCountryCode
        metaDetails["Carrier MNC"].string = Luminous.Carrier.mobileNetworkCode
        metaDetails["Carrier Allows VOIP"].bool = Luminous.Carrier.isVoipAllowed
        metaDetails["GPS Location"].string = Luminous.Locale.currentCountry
        metaDetails["Battery Level"].float = Luminous.Battery.level
        metaDetails["Battery State"].string = "\(Luminous.Battery.state)"
        metaDetails["currentCountry"].string = Luminous.Locale.currentCountry
        
        
        var IMEI = ""
        var productId = ""
        var customerId = ""
        let resultCode = ""
        var devicename = ""
        
        if let imei = AppUserDefaults.value(forKey: "imei_number") as? String {
            IMEI = imei
        }
        
        if let pId = AppUserDefaults.string(forKey: "product_id") {
            productId = pId
        }
        
        if let cId = AppUserDefaults.string(forKey: "customer_id") {
            customerId = cId
        }
        
        if let dName = AppUserDefaults.string(forKey: "productName") {
            devicename = dName
        }
        
        var params = [String : Any]()
        params = ["userName" : AppUserName,
                  "apiKey" : AppApiKey,
                  "customerId" : customerId,
                  "resultCode" : resultCode,
                  "resultJson" : AppResultJSON,
                  "price" : price,
                  "deviceName" : devicename,
                  "conditionString" : AppResultString,
                  "metaDetails" : self.metaDetails,
                  "IMEINumber" : IMEI,
                  "productId" : productId]
        
        //print("params = \(params)")
    
        self.showHudLoader(msg: "")
        
        let webService = AF.request(kSavingResultURL, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: nil, interceptor: nil, requestModifier: nil)
        webService.responseJSON { (responseData) in
            
            self.hud.dismiss()
            //print(responseData.value as? [String:Any] ?? [:])
            
            switch responseData.result {
            case .success(_):
                                
                do {
                    let json = try JSON(data: responseData.data ?? Data())
                    
                    if json["status"] == "Success" {
                        
                        let msg = json["msg"]
                        self.currentOrderId = msg["orderId"].string ?? ""
                        self.lblOrderRef.text = "Order Ref " + self.currentOrderId
                        
                        self.showaAlert(message: self.getLocalizatioStringValue(key: "Details Synced to the server. Please contact Store Executive for further information"))
                        
                    }else {
                        self.showaAlert(message: json["msg"].stringValue)
                    }
                    
                }catch {
                    self.showaAlert(message: self.getLocalizatioStringValue(key: "JSON Exception"))
                }
                
                break
            case .failure(_):
                print(responseData.error ?? NSError())
                self.showaAlert(message: self.getLocalizatioStringValue(key: "Something went wrong!!"))
                break
            }
      
        }
        
    }
    
    func uploadIdProof(photoStr : String) {
        
        var customerId = ""
        if let cId = AppUserDefaults.string(forKey: "customer_id") {
            customerId = cId
        }
        
        var params = [String : Any]()
        params = ["userName" : AppUserName,
                  "apiKey" : AppApiKey,
                  "orderId" : self.currentOrderId,
                  "customerId" : customerId,
                  "photo" : photoStr]
        
        //print("params = \(params)")
    
        self.showHudLoader(msg: self.getLocalizatioStringValue(key: "Uploading..."))
        
        let webService = AF.request(kIdProofURL, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: nil, interceptor: nil, requestModifier: nil)
        webService.responseJSON { (responseData) in
            
            self.hud.dismiss()
            //print(responseData.value as? [String:Any] ?? [:])
            
            switch responseData.result {
            case .success(_):
                                
                do {
                    let json = try JSON(data: responseData.data ?? Data())
                    
                    if json["status"] == "Success" {
                        
                        DispatchQueue.main.async() {
                            self.showaAlert(message: self.getLocalizatioStringValue(key: "Photo Id uploaded successfully!"))
                        }
                        
                    }else {
                        self.showaAlert(message: json["msg"].stringValue)
                    }
                    
                }catch {
                    self.showaAlert(message: self.getLocalizatioStringValue(key: "JSON Exception"))
                }
                
                break
            case .failure(_):
                print(responseData.error ?? NSError())
                self.showaAlert(message: self.getLocalizatioStringValue(key: "Something went wrong!!"))
                break
            }
      
        }
        
    }
    
    //MARK:- Tableview Delegates Methods
  
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.skipTableView {
            return  self.arrFailedAndSkipedTest.count
        }else {
            return self.arrQuestion.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.skipTableView {
            let SkipTestCell = tableView.dequeueReusableCell(withIdentifier: "SkipTestCell", for: indexPath) as! SkipTestCell
            SkipTestCell.lblTestName.text = self.arrFailedAndSkipedTest[indexPath.item].strTestType
           
            return SkipTestCell
            
        }else {
            let ResultCell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! ResultCell
            ResultCell.lblQuestion.text = self.arrQuestion[indexPath.item]
            ResultCell.lblAnswer.text = self.arrAnswer[indexPath.item]
           
            return ResultCell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func createTableFromPassFailedTests() {
        
        self.arrFailedAndSkipedTest.removeAll()
        
        if let val = AppUserDefaults.value(forKey: "deadPixel") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Dead Pixels"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "screen") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Screen"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
       
        if let val = AppUserDefaults.value(forKey: "Rotation") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Rotation"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "Proximity") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Proximity"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "Hardware Buttons") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Hardware Buttons"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "Earphone") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Earphone"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "USB") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Charger"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "Camera") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Camera"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "Autofocus") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Autofocus"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        var biometricTestName = ""
        if BioMetricAuthenticator.canAuthenticate() {
            
            if BioMetricAuthenticator.shared.faceIDAvailable() {
                biometricTestName = "Face-Id Scanner"
            }else {
                biometricTestName = "Fingerprint Scanner"
            }
            
            if let val = AppUserDefaults.value(forKey: "Fingerprint Scanner") as? Bool {
                let model = ModelCompleteDiagnosticFlow()
                model.strTestType = biometricTestName
                
                if !val {
                    self.arrFailedAndSkipedTest.append(model)
                }
            }
           
        }else {
            
            if LocalAuth.shared.hasTouchId() {
                print("Has Touch Id")
            } else if LocalAuth.shared.hasFaceId() {
                print("Has Face Id")
            } else {
                print("Device does not have Biometric Authentication Method")
            }
            
            print("Device does not have Biometric Authentication Method")
            
            biometricTestName = "Biometric Authentication"
            
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = biometricTestName
            self.arrFailedAndSkipedTest.append(model)
            
        }
        
        
        if let val = AppUserDefaults.value(forKey: "WIFI") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "WIFI"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "Bluetooth") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Bluetooth"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "GSM") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "GSM"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "GSM") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "SMS Verification"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "GPS") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "GPS"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "Microphone") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Microphone"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
             
        if let val = AppUserDefaults.value(forKey: "Speakers") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Speakers"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "Vibrator") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Vibrator"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        /*
        if let val = AppUserDefaults.value(forKey: "Torch") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "FlashLight"
            
         if !val {
             self.arrFailedAndSkipedTest.append(model)
         }
        }
        */
        
        if let val = AppUserDefaults.value(forKey: "Storage") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Storage"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if let val = AppUserDefaults.value(forKey: "Battery") as? Bool {
            let model = ModelCompleteDiagnosticFlow()
            model.strTestType = "Battery"
            
            if !val {
                self.arrFailedAndSkipedTest.append(model)
            }
        }
        
        if self.arrFailedAndSkipedTest.count > 0 {
            let testHeight = self.arrFailedAndSkipedTest.count * 35
            self.skipViewHeightConstraint.constant = CGFloat(200 + testHeight)
        }
        else{
            self.skipViewTopConstraint.constant = 0
            self.skipViewHeightConstraint.constant = 0
        }
              
        DispatchQueue.main.async {
            self.skipTableView.dataSource = self
            self.skipTableView.delegate = self
            self.skipTableView.reloadData()
        }
                
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
