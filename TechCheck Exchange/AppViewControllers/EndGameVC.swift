//
//  EndGameVC.swift
//  TechCheck Exchange
//
//  Created by Sameer Khan on 16/08/21.
//

import UIKit
import Intercom
import SwiftyJSON

class EndGameVC: UIViewController {
    
    @IBOutlet weak var lblFinalMsg: UILabel!
    @IBOutlet weak var btnSeeOrderStatus: UIButton!
    @IBOutlet weak var btnChatWithUs: UIButton!
    
    var orderId = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setUIElements()
    }
    
    //MARK:- Custom Methods
    
    func setUIElements() {
        
        self.hideKeyboardWhenTappedAroundView()
        self.setStatusBarColor(themeColor: AppThemeColor)
        
        self.btnSeeOrderStatus.layer.cornerRadius = AppBtnCornerRadius
        self.btnChatWithUs.layer.cornerRadius = AppBtnCornerRadius
        
        self.showFinalMessageWithOrderID()
    }
    
    func showFinalMessageWithOrderID() {

        let msg = NSMutableAttributedString.init(string: "Your take back order \(self.orderId) has been placed. You can now take your device to the store vendor and complete the order for payment!")
        
        msg.setAttributes([NSAttributedString.Key.font : UIFont(name: AppBrownFontBold, size: CGFloat(20.0))!
                           , NSAttributedString.Key.foregroundColor : AppThemeColor], range: NSRange(location: 21,length:6))
       
        self.lblFinalMsg.attributedText = msg
        
    }
    
    //MARK:- IBAction
    @IBAction func btnOrderStatusPressed(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PreviousQuoteVC") as! PreviousQuoteVC
        vc.orderID = self.orderId
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnChatWithUSPressed(_ sender: UIButton) {
        
        if let imei = AppUserDefaults.string(forKey: "imei_number") {
            Intercom.registerUser(withUserId: imei)
            Intercom.presentMessenger()
        }
        
    }
    
    @IBAction func crossBtnPressed(_ sender: UIButton) {
        
        AppResultJSON = JSON()
        AppResultString = ""
        AppHardwareQuestionsData = nil
        hardwareQuestionsCount = 0
        AppQuestionIndex = -1
        self.resetAppUserDefaults()
        
        let StoreTokenVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "StoreTokenVC") as! StoreTokenVC
        self.navigationController?.pushViewController(StoreTokenVC, animated: true)
      
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
