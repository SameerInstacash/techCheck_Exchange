//
//  UserDetailVC.swift
//  TechCheck Exchange
//
//  Created by Sameer Khan on 14/07/21.
//

import UIKit
import JGProgressHUD
import Alamofire
import SwiftyJSON
import FirebaseDatabase

class UserDetailVC: UIViewController {

    @IBOutlet weak var lblCustomerDetail: UILabel!
    @IBOutlet weak var lblEnterDetail: UILabel!
    @IBOutlet weak var txtFieldName: UITextField!
    @IBOutlet weak var txtFieldEmail: UITextField!
    @IBOutlet weak var txtFieldContactNumber: UITextField!
    @IBOutlet weak var btnCheckBox: UIButton!
    @IBOutlet weak var btnContinue: UIButton!
    @IBOutlet weak var baseView: UIView!
    
    let hud = JGProgressHUD()
    var isCheckBoxSelect = false
    let reachability: Reachability? = Reachability()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setUIElements()
       
    }
    
    //MARK:- Web Service Methods
    func showHudLoader() {
        hud.textLabel.text = ""
        hud.backgroundColor = #colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 0.4)
        hud.show(in: self.view)
    }
    
    func updateCustomerDetails() {
        
        var customerId = ""
   
        if let cId = AppUserDefaults.string(forKey: "customer_id") {
            customerId = cId
        }
        
        var params = [String : Any]()
        params = ["userName" : AppUserName,
                  "apiKey" : AppApiKey,
                  "customerId" : customerId,
                  "name" : self.txtFieldName.text ?? "",
                  "mobile" : self.txtFieldContactNumber.text ?? "",
                  "email" : self.txtFieldEmail.text ?? ""]
        
        //print("params = \(params)")
        
        //var header = HTTPHeaders()
        //header = ["X-API-KEY" : "CODEX@123"]
    
        self.showHudLoader()
        
        if let url = AppUserDefaults.value(forKey: "AppBaseUrl") as? String {
            AppBaseUrl = url
        }
        
        let webService = AF.request(kUpdateCustomerURL, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: nil, interceptor: nil, requestModifier: nil)
        //webService.authenticate(username: "admin", password: "1234").responseJSON { (responseData) in
        webService.responseJSON { (responseData) in
            
            self.hud.dismiss()
            //print(responseData.value as? [String:Any] ?? [:])
            
            switch responseData.result {
            case .success(_):
                                
                do {
                    let json = try JSON(data: responseData.data ?? Data())
                    //print(json)
                    
                    if json["status"] == "Success" {
                        
                        let vc = self.storyboard?.instantiateViewController(withIdentifier: "FinalQuoteVC") as! FinalQuoteVC
                        self.navigationController?.pushViewController(vc, animated: true)
                        
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
    
    //MARK:- IBAction
    @IBAction func backBtnPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tncBtnPressed(_ sender: UIButton) {
        
        if let tncURL = AppUserDefaults.value(forKey: "tncendpoint") as? String {
            
            if let url = URL(string: tncURL), UIApplication.shared.canOpenURL(url) {
               if #available(iOS 10.0, *) {
                  UIApplication.shared.open(url, options: [:], completionHandler: nil)
               } else {
                  UIApplication.shared.openURL(url)
               }
            }
            
        }
            
    }
    
    @IBAction func continueBtnPressed(_ sender: UIButton) {
        
        if self.validation() {
            
            self.view.endEditing(true)
            
            if reachability?.connection.description != "No Connection" {
                
                self.updateCustomerDetails()
                
            }else {
                self.showaAlert(message: self.getLocalizatioStringValue(key: "Please Check Internet connection."))
            }
            
        }
        
    }
    
    @IBAction func checkBoxBtnPressed(_ sender: UIButton) {
        if !sender.isSelected {
            sender.isSelected = !sender.isSelected
            
            self.isCheckBoxSelect = sender.isSelected
        }else {
            sender.isSelected = !sender.isSelected
            
            self.isCheckBoxSelect = sender.isSelected
        }
    }
    
    //MARK:- Custom Methods
    
    func setUIElements() {
        
        self.lblEnterDetail.setLineHeight(lineHeight: 3.0)
        self.lblEnterDetail.textAlignment = .left
        
        self.setStatusBarColor(themeColor: AppThemeColor)
        self.setPaddingOnTextField()
        
        self.btnContinue.layer.cornerRadius = AppBtnCornerRadius
        self.baseView.layer.cornerRadius = AppBtnCornerRadius
    }
    
    func validation() -> Bool {
        
        if self.txtFieldName.text?.isEmpty ?? false {
            
            self.showaAlert(message: self.getLocalizatioStringValue(key: "Please enter your name"))
            
            return false
        }else if self.txtFieldEmail.text?.isEmpty ?? false {
            
            self.showaAlert(message: self.getLocalizatioStringValue(key: "Please enter your email"))
            
            return false
        }else if !self.isValidEmail(self.txtFieldEmail.text!) {
            
            self.showaAlert(message: self.getLocalizatioStringValue(key: "Please enter valid email"))
            
            return false
        } else if self.txtFieldContactNumber.text?.isEmpty ?? false {
            
            self.showaAlert(message: self.getLocalizatioStringValue(key: "Please enter your contact no."))
            
            return false
        }else if !self.isCheckBoxSelect {
            
            self.showaAlert(message: self.getLocalizatioStringValue(key: "Please accept terms & conditions"))
            
            return false
        } else {
            return true
        }
        
    }

    func setPaddingOnTextField() {
        
        let padd = UITextField.init(frame: CGRect.init(x: 0, y: 0, width: 40, height: self.txtFieldContactNumber.bounds.height))
        padd.text = "+44"
        padd.font = UIFont.init(name: AppBrownFontRegular, size: 16.0)
        padd.textColor = #colorLiteral(red: 0.5764705882, green: 0.5764705882, blue: 0.5764705882, alpha: 1)
        padd.textAlignment = .center
        padd.isUserInteractionEnabled = false
        
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: self.txtFieldContactNumber.bounds.height))
        paddingView.addSubview(padd)
        self.txtFieldContactNumber.leftView = paddingView
        self.txtFieldContactNumber.leftViewMode = .always
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
