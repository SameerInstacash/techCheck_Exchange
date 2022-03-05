//
//  StoreTokenVC.swift
//  TechCheck Exchange
//
//  Created by Sameer Khan on 12/07/21.
//

import UIKit
import FirebaseDatabase
import QRCodeReader
import SwiftyJSON
import Alamofire
import JGProgressHUD

class StoreTokenVC: UIViewController, QRCodeReaderViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        
    @IBOutlet weak var txtFieldStoreToken: UITextField!
    @IBOutlet weak var lblImeiNumberTitle: UILabel!
    @IBOutlet weak var lblImeiNumber: UILabel!
    @IBOutlet weak var lblEnterStoreToken: UILabel!
    @IBOutlet weak var btnSubmit: UIButton!
    @IBOutlet weak var btnScanQR: UIButton!
    @IBOutlet weak var btnPreviousQuote: UIButton!
    @IBOutlet weak var imeiStackView: UIStackView!
    
    @IBOutlet weak var bottomContentView:UIView!
    
    @IBOutlet weak var btnLanguageSymbol: UIButton!
    @IBOutlet weak var languageView: UIView!
    @IBOutlet weak var languageBaseView: UIView!
    @IBOutlet weak var languageCollectionView: UICollectionView!
    @IBOutlet weak var languageCollectionViewHeightConstant: NSLayoutConstraint!
    @IBOutlet weak var btnLanguageDone: UIButton!
    @IBOutlet weak var btnLanguageCancel: UIButton!
    
    let reachability: Reachability? = Reachability()
    let hud = JGProgressHUD()
    var arrStoreUrlData = [StoreUrlData]()
    var arrCountrylanguages = [CountryLanguages]()
    var storeToken: String = ""
   
    var holdLanguageIndex : Int?
    var selectedLanguageIndex : Int?
    var selectedLanguageName : String?
    var selectedLanguageDBurl : String?
    
    // QRCodeReader
    lazy var reader: QRCodeReader = QRCodeReader()
    lazy var readerVC: QRCodeReaderViewController = {
    let builder = QRCodeReaderViewControllerBuilder {
    $0.reader          = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
    $0.showTorchButton = true
    
    $0.reader.stopScanningWhenCodeIsFound = false
    }
    
    return QRCodeReaderViewController(builder: builder)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.languageCollectionView.register(UINib(nibName: "CountryLanguageCVCell", bundle: nil), forCellWithReuseIdentifier: "CountryLanguageCVCell")
        
        
        self.fetchStoreDataFromFirebase()
        self.fetchLanguagesFromFirebase()

        self.setUIElements()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let IMEI = AppUserDefaults.value(forKey: "imei_number") as? String {
            self.lblImeiNumber.text = IMEI
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
        self.view.frame.origin.y = -100
    }
    
    @objc func keyboardWillHide(sender: NSNotification) {
         self.view.frame.origin.y = 0
    }
    
    //MARK:- IBAction
    @IBAction func submitBtnPressed(_ sender: UIButton) {
        
        self.storeToken = String(self.txtFieldStoreToken.text ?? "0")
        
        guard self.storeToken != "" else {
            self.showaAlert(message: self.getLocalizatioStringValue(key: "Please Enter Store Token."))
            return
        }
        
        
        if self.storeToken.count >= 4 {
            let enteredToken = self.storeToken.prefix(4)
            
            for tokens in self.arrStoreUrlData {
                if tokens.strPrefixKey == enteredToken {
                    AppBaseUrl = tokens.strUrl
                    
                    AppUserDefaults.setValue(tokens.strTnc, forKey: "tncendpoint")
                    AppUserDefaults.setValue(tokens.strType, forKey: "storeType")
                    AppUserDefaults.setValue(tokens.strIsTradeOnline, forKey: "tradeOnline")
                    
                    AppUserDefaults.setValue(tokens.strUrl, forKey: "AppBaseUrl")
                    
                    self.verifyUserSmartCode()
                    
                    break
                }
            }
            
        }else {
            self.showaAlert(message: self.getLocalizatioStringValue(key: "Please Enter Valid Store Token"))
        }

    }
    
    @IBAction func scanQRBtnPressed(_ sender: UIButton) {
    
        guard checkScanPermissions() else { return }
        
        readerVC.modalPresentationStyle = .formSheet
        readerVC.delegate               = self
        
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in
            if let result = result {
                
                print("result is : \(result.value)")
                self.storeToken = String(result.value)
                print("code is : \(self.storeToken.prefix(4))")
                
                if self.storeToken.count >= 8 {
                    
                    let enteredToken = self.storeToken.prefix(4)
                    
                    for tokens in self.arrStoreUrlData {
                        if tokens.strPrefixKey == enteredToken {
                            AppBaseUrl = tokens.strUrl
                            
                            AppUserDefaults.setValue(tokens.strTnc, forKey: "tncendpoint")
                            AppUserDefaults.setValue(tokens.strType, forKey: "storeType")
                            AppUserDefaults.setValue(tokens.strIsTradeOnline, forKey: "tradeOnline")
                            
                            AppUserDefaults.setValue(tokens.strUrl, forKey: "AppBaseUrl")
                            
                            self.verifyUserSmartCode()
                            
                            break
                        }
                    }
                    
                }else {
                    self.showaAlert(message: self.getLocalizatioStringValue(key: "Store Token Not Valid"))
                }
                
            }
        }
        
        present(readerVC, animated: true, completion: nil)
    }
    
    @IBAction func previousQuoteBtnPressed(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PreviousQuoteVC") as! PreviousQuoteVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func languageSymbolBtnPressed(_ sender: UIButton) {
        self.languageView.isHidden = !self.languageView.isHidden
        
        self.holdLanguageIndex = self.selectedLanguageIndex
        
        self.languageCollectionView.reloadData()
    }
    
    @IBAction func languageDoneBtnPressed(_ sender: UIButton) {
        self.languageView.isHidden = !self.languageView.isHidden

        self.selectedLanguageIndex = self.holdLanguageIndex

        self.holdLanguageIndex = nil

        if self.selectedLanguageIndex != nil {
            self.selectedLanguageName = self.arrCountrylanguages[self.selectedLanguageIndex ?? 0].strLanguageName
        }

        if let strLangName = self.selectedLanguageName {
            self.getLanguagesFromDataBase(strLangName)
        }

        self.languageCollectionView.reloadData()

    }
    
    @IBAction func languageCancelBtnPressed(_ sender: UIButton) {
        self.languageView.isHidden = !self.languageView.isHidden
        
        self.holdLanguageIndex = nil
    }
    
    //MARK:- Firebase Database Methods
    func fetchStoreDataFromFirebase() {
                
        if reachability?.connection.description != "No Connection" {
            
            self.showHudLoader()
            
            StoreUrlData.fetchStoreUrlsFromFireBase(isInterNet: true, getController: self) { (storeData) in
                
                DispatchQueue.main.async {
                    self.hud.dismiss()
                }
                
                if storeData.count > 0 {
                    self.arrStoreUrlData = storeData
                }else {
                    self.showaAlert(message: self.getLocalizatioStringValue(key: "No Data Found"))
                }
                
            }
            
        }else {
            self.showaAlert(message: self.getLocalizatioStringValue(key: "Please Check Internet connection."))
        }
        
    }
    
    func fetchLanguagesFromFirebase() {
                
        if reachability?.connection.description != "No Connection" {
            
            self.showHudLoader()
            
            CountryLanguages.fetchLanguageFromFireBase(isInterNet: true, getController: self) { (languages) in
                
                DispatchQueue.main.async {
                    self.hud.dismiss()
                }
                
                if languages.count > 0 {
                    
                    self.selectedLanguageIndex = 0
                    
                    self.btnLanguageSymbol.setTitle(languages[self.selectedLanguageIndex ?? 0].strLanguageSymbol, for: .normal)
                    
                    self.selectedLanguageName = languages[self.selectedLanguageIndex ?? 0].strLanguageName
                    self.getLanguagesFromDataBase(self.selectedLanguageName ?? "")
                    
                    if languages.count > 1 {
                        self.btnLanguageSymbol.isHidden = false
                    }
                    
                }else {
                    self.btnLanguageSymbol.isHidden = true
                }
                
            }
         
        }else {
            self.showaAlert(message: self.getLocalizatioStringValue(key: "Please Check Internet connection."))
        }
        
    }
    
    func getLanguagesFromDataBase(_ selectLangName : String) {
        
        if reachability?.connection.description != "No Connection" {
            
            self.showHudLoader()
        
            CountryLanguages.fetchLanguageFromFireBase(isInterNet: true, getController: self) { (arrCountryLangs) in
                
                DispatchQueue.main.async {
                    self.hud.dismiss()
                }
                
                if arrCountryLangs.count > 0 {
                    
                    self.arrCountrylanguages = arrCountryLangs

                    // ***** Download Selected Country's Language From selected index ***** //
                    for lang in arrCountryLangs {
                        if lang.strLanguageName == selectLangName {
                            
                            self.selectedLanguageDBurl = lang.strLanguageUrl
                            
                            //save here language details
                                                        
                            AppUserDefaults.setValue(lang.strLanguageName, forKey: "LanguageName")
                            AppUserDefaults.setValue(lang.strLanguageVersion, forKey: "LanguageVersion")
                            
                            self.btnLanguageSymbol.setTitle(lang.strLanguageSymbol, for: .normal)
                            self.btnLanguageSymbol.backgroundColor = #colorLiteral(red: 0.3490196078, green: 0.06274509804, blue: 0.568627451, alpha: 1)
                            
                            DispatchQueue.main.async {
                                self.downloadSelectedLanguage(self.selectedLanguageDBurl ?? "")
                            }
                            
                        }
                    }
                    
                }
                else{
                    self.showaAlert(message: self.getLocalizatioStringValue(key: "Sorry! No Language Available"))
                }
            }
            
        }else {
            self.showaAlert(message: self.getLocalizatioStringValue(key: "No connection found"))
        }
        
    }
    
    func downloadSelectedLanguage(_ strUrl : String) {
        
        if reachability?.connection.description != "No Connection" {
            
            DispatchQueue.main.async {
                
                self.showHudLoader()
                
                let url:URL = URL(string: strUrl)!
                let session = URLSession.shared
                
                let request = NSMutableURLRequest(url: url)
                request.httpMethod = "GET"
                //request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
                
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) in
                    
                    DispatchQueue.main.async {
                        self.hud.dismiss()
                    }
                        
                    guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                        return
                    }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data ?? Data(), options: []) as? NSDictionary {
                            
                            //print(json)
                            
                            DispatchQueue.main.async {
                                self.saveLocalizationString(json)
                                //AppUserDefaults.setCountryLanguage(data: json)
                                self.changeLanguageOfUI()
                            }
                        }
                        
                    } catch {
                        print("JSON serialization failed: ", error)
                        self.showaAlert(message: self.getLocalizatioStringValue(key: "JSON serialization failed"))
                    }
                    
                })
                task.resume()
            }
            
            
        }else {
            self.showaAlert(message: self.getLocalizatioStringValue(key: "No connection found"))
        }
        
    }
    
    //MARK:- Custom Methods
    func navigateToMainHomePage() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "HomeVC") as! HomeVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func changeLanguageOfUI() {
        
        self.txtFieldStoreToken.placeholder = self.getLocalizatioStringValue(key: "Store token")
        self.lblImeiNumberTitle.text = self.getLocalizatioStringValue(key: "IMEI/ SERIAL")
        self.lblEnterStoreToken.text = self.getLocalizatioStringValue(key: "Enter store token and submit or click scan qr code to begin diagnostics")
        
        self.btnSubmit.setTitle(self.getLocalizatioStringValue(key: "Submit").uppercased(), for: .normal)
        self.btnScanQR.setTitle(self.getLocalizatioStringValue(key: "Scan QR").uppercased(), for: .normal)
        self.btnPreviousQuote.setTitle(self.getLocalizatioStringValue(key: "Previous Quote").uppercased(), for: .normal)
        self.btnLanguageDone.setTitle(self.getLocalizatioStringValue(key: "done").uppercased(), for: .normal)
        self.btnLanguageCancel.setTitle(self.getLocalizatioStringValue(key: "Cancel").uppercased(), for: .normal)
        
    }
    
    func setUIElements() {
       
        DispatchQueue.main.async {
            self.bottomContentView.roundCorners(corners: [.topLeft,.topRight], radius: 10.0)
        }
        
        
        self.hideKeyboardWhenTappedAroundView()
        self.setStatusBarColor(themeColor: AppThemeColor)
        
        self.txtFieldStoreToken.layer.cornerRadius = AppBtnCornerRadius
        
        self.btnSubmit.layer.cornerRadius = AppBtnCornerRadius
        self.btnScanQR.layer.cornerRadius = AppBtnCornerRadius
        self.btnPreviousQuote.layer.cornerRadius = AppBtnCornerRadius
        
        self.imeiStackView.layer.cornerRadius = AppBtnCornerRadius
        self.imeiStackView.layer.borderWidth = 0.4
        self.imeiStackView.layer.borderColor = #colorLiteral(red: 0.5764705882, green: 0.5764705882, blue: 0.5764705882, alpha: 0.5)
        
        self.btnLanguageSymbol.layer.cornerRadius = 30.0
        self.languageBaseView.layer.cornerRadius = AppBtnCornerRadius
        self.btnLanguageDone.layer.cornerRadius = 25.0
        self.btnLanguageCancel.layer.cornerRadius = 25.0
        
        self.btnPreviousQuote.layer.borderWidth = 1.0
        self.btnPreviousQuote.layer.borderColor = #colorLiteral(red: 0.8666666667, green: 0.8666666667, blue: 0.8666666667, alpha: 1)
    }
    
    private func checkScanPermissions() -> Bool {
        do {
            return try QRCodeReader.supportsMetadataObjectTypes()
        } catch let error as NSError {
            let alert: UIAlertController
            
            switch error.code {
            case -11852:
                alert = UIAlertController(title: self.getLocalizatioStringValue(key: "Error"), message: self.getLocalizatioStringValue(key: "This app is not authorized to use Back Camera."), preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: self.getLocalizatioStringValue(key: "Setting"), style: .default, handler: { (_) in
                    
                    DispatchQueue.main.async {
                        
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
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
                    
                }))
                
                alert.addAction(UIAlertAction(title: self.getLocalizatioStringValue(key: "Cancel"), style: .cancel, handler: nil))
            default:
                alert = UIAlertController(title: self.getLocalizatioStringValue(key: "Error"), message: self.getLocalizatioStringValue(key: "Reader not supported by the current device"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: self.getLocalizatioStringValue(key: "OK"), style: .cancel, handler: nil))
            }
            
            present(alert, animated: true, completion: nil)
            
            return false
        }
    }
    
    func getTotalSize() -> Int64 {
        var space: Int64 = 0
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            space = ((systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value)!
            space = space/1000000000
            if space<8{
                space = 8
            } else if space<16{
                space = 16
            } else if space<32{
                space = 32
            } else if space<64{
                space = 64
            } else if space<128{
                space = 128
            } else if space<256{
                space = 256
            } else if space<512{
                space = 512
            }
        } catch {
            space = 0
        }
        return space
    }
    
    // MARK: - QRCodeReader Delegate Methods
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
        
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    
    //MARK:- collection view methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if self.selectedLanguageIndex != nil {
            
            self.languageCollectionViewHeightConstant.constant = CGFloat(self.arrCountrylanguages.count) * 50.0 + CGFloat(self.arrCountrylanguages.count) * 10.0
            
            return self.arrCountrylanguages.count
            
        }else {
            
            self.languageCollectionViewHeightConstant.constant = 0.0
            return 0
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CountryLanguageCVCell", for: indexPath) as! CountryLanguageCVCell
        
        if let ind = self.holdLanguageIndex {
            
            if indexPath.item == ind {
                cell.baseView.backgroundColor = #colorLiteral(red: 0.3490196078, green: 0.06274509804, blue: 0.568627451, alpha: 1)
                cell.lblLanguageName.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            }else {
                cell.baseView.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                cell.lblLanguageName.textColor = #colorLiteral(red: 0.3490196078, green: 0.06274509804, blue: 0.568627451, alpha: 1)
            }
            
        }else {
            
            if indexPath.item == self.selectedLanguageIndex {
                cell.baseView.backgroundColor = #colorLiteral(red: 0.3490196078, green: 0.06274509804, blue: 0.568627451, alpha: 1)
                cell.lblLanguageName.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            }else {
                cell.baseView.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                cell.lblLanguageName.textColor = #colorLiteral(red: 0.3490196078, green: 0.06274509804, blue: 0.568627451, alpha: 1)
            }
        }
        
        cell.lblLanguageName.text = self.arrCountrylanguages[indexPath.item].strLanguageName
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.holdLanguageIndex = indexPath.item
        self.languageCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if UIDevice.current.model.hasPrefix("iPad") {
            return CGSize(width: collectionView.frame.size.width, height: 60.0)
        }else {
            return CGSize(width: collectionView.frame.size.width, height: 50.0)
        }
        
    }
    
    //MARK:- Web Service Methods
    func showHudLoader() {
        
        DispatchQueue.main.async {
            self.hud.textLabel.text = ""
            self.hud.backgroundColor = #colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 0.4)
            self.hud.show(in: self.view)
        }
        
    }
    
    func verifyUserSmartCode() {
        
        self.view.endEditing(true)
        
        var params = [String : Any]()
        params = ["userName" : AppUserName,
                  "apiKey" : AppApiKey,
                  "IMEINumber" : self.lblImeiNumber.text ?? "",
                  "device" : UIDevice.current.currentModelName,
                  "memory" : self.getTotalSize(),
                  "ram" : ProcessInfo.processInfo.physicalMemory,
                  
                  //"device" : "iPhone XR",
                  //"memory" : "128",
                  //"ram" : "3073741824",
                  
                  "storeToken" : self.storeToken]
        
        //print("params = \(params)")
        //print(kStartSessionURL)
        //44017470
        
        //var header = HTTPHeaders()
        //header = ["X-API-KEY" : "CODEX@123"]
    
        self.showHudLoader()
        
        if let url = AppUserDefaults.value(forKey: "AppBaseUrl") as? String {
            AppBaseUrl = url
        }
        
        let webService = AF.request(kStartSessionURL, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: nil, interceptor: nil, requestModifier: nil)
        //webService.authenticate(username: "admin", password: "1234").responseJSON { (responseData) in
        webService.responseJSON { (responseData) in
            
            DispatchQueue.main.async {
                self.hud.dismiss()
            }
            //print(responseData.value as? [String:Any] ?? [:])
            
            switch responseData.result {
            case .success(_):
                                
                do {
                    let json = try JSON(data: responseData.data ?? Data())
                    //print(json)
                    
                    if json["status"] == "Success" {
                        
                        var productId = "0"
                        let productData = json["productData"]
                        
                        if productData["id"].string ?? "" != "" {
                            
                            productId = productData["id"].string ?? ""
                            
                            let productBrandName = productData["brandName"]
                            let productName = productData["name"]
                            let productImage = productData["image"]
                            
                            AppUserDefaults.set(productBrandName.string, forKey: "product_brand")
                            AppUserDefaults.set(productId, forKey: "product_id")
                            AppUserDefaults.set("\(productName)", forKey: "productName")
                            AppUserDefaults.set("\(productImage)", forKey: "productImage")
                            AppUserDefaults.set(json["customerId"].string ?? "", forKey: "customer_id")
                            AppUserDefaults.set(self.storeToken, forKey: "store_code")
                            
                            let serverData = json["serverData"]
                            //print("\n\n\(serverData["currencyJson"])")
                            let jsonEncoder = JSONEncoder()
                            
                            let currencyJSON = serverData["currencyJson"]
                            let jsonData = try jsonEncoder.encode(currencyJSON)
                            let jsonString = String(data: jsonData, encoding: .utf8)
                            AppUserDefaults.set(jsonString, forKey: "currencyJson")
                            
                            let priceData = json["priceData"]
                            let uptoPrice = priceData["msg"].string ?? ""
                            AppUserDefaults.set(uptoPrice, forKey: "uptoPrice")
                            
                            DispatchQueue.main.async() {
                                AppCurrentProductBrand = productBrandName.stringValue
                                AppCurrentProductName = productName.stringValue
                                AppCurrentProductImage = productImage.stringValue
                                
                                self.navigateToMainHomePage()
                            }
                            
                        }else{
                            self.showaAlert(message: self.getLocalizatioStringValue(key: "Device not found!"))
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
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
