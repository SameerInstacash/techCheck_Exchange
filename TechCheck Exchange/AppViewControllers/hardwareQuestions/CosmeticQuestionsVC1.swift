//
//  CosmeticQuestionsVC1.swift
//  TechCheck Exchange
//
//  Created by Sameer Khan on 14/07/21.
//

import UIKit
import AlamofireImage

class CosmeticQuestionsVC1: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var arrQuestionAnswer : Questions?
    var TestDiagnosis: (() -> Void)?
    var questionInd = 0
    var selectedAppCode = ""
    
    @IBOutlet weak var lblQuestionName: UILabel!
    @IBOutlet weak var cosmeticCollectionView: UICollectionView!
    @IBOutlet weak var btnContinue: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUIElements()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (self.arrQuestionAnswer?.specificationValue?.count ?? 0) > 0 {
            self.lblQuestionName.text = arrQuestionAnswer?.specificationName
        }else {
            self.lblQuestionName.text = arrQuestionAnswer?.conditionSubHead
        }
      
    }
    
    //MARK:- IBAction
    @IBAction func backBtnPressed(_ sender: UIButton) {
    
    }
    
    @IBAction func continueBtnPressed(_ sender: UIButton) {
        
        if self.selectedAppCode == "" {
            self.showaAlert(message: self.getLocalizatioStringValue(key: "Please select one option"))
        }else {
            
            AppResultString = AppResultString + self.selectedAppCode + ";"
            
            guard let didFinishRetryDiagnosis = self.TestDiagnosis else { return }
            didFinishRetryDiagnosis()
            self.dismiss(animated: false, completion: nil)
        }
                
    }
    
    //MARK:- Custom Methods
  
    func setUIElements() {
        self.setStatusBarColor(themeColor: AppThemeColor)
        
        self.btnContinue.layer.cornerRadius = AppBtnCornerRadius
    }
    
    // MARK: - UICollectionView DataSource & Delegates
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if (self.arrQuestionAnswer?.specificationValue?.count ?? 0) > 0 {
            return self.arrQuestionAnswer?.specificationValue?.count ?? 0
        }else {
            return self.arrQuestionAnswer?.conditionValue?.count ?? 0
        }
       
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cosmeticCell1 = collectionView.dequeueReusableCell(withReuseIdentifier: "cosmeticCell1", for: indexPath)
        cosmeticCell1.layer.cornerRadius = AppBtnCornerRadius
        
        let iconImgView : UIImageView = cosmeticCell1.viewWithTag(10) as! UIImageView
        let lblIconName : UILabel = cosmeticCell1.viewWithTag(20) as! UILabel
        
        if (self.arrQuestionAnswer?.specificationValue?.count ?? 0) > 0 {
            let answer = self.arrQuestionAnswer?.specificationValue?[indexPath.item]
            let str = answer?.value?.removingPercentEncoding
            
            lblIconName.text = str?.replacingOccurrences(of: "+", with: " ")
            
            if let qImage = self.arrQuestionAnswer?.specificationValue?[indexPath.item].image {
                if let imgUrl = URL(string: qImage) {
                    iconImgView.af.setImage(withURL: imgUrl)
                }
            }
            
            
        }else {
            let answer = self.arrQuestionAnswer?.conditionValue?[indexPath.item]
            let str = answer?.value?.removingPercentEncoding
            
            lblIconName.text = str?.replacingOccurrences(of: "+", with: " ")
            
            if let qImage = self.arrQuestionAnswer?.conditionValue?[indexPath.item].image {
                if let imgUrl = URL(string: qImage) {
                    iconImgView.af.setImage(withURL: imgUrl)
                }
            }
         
        }
        
        
        return cosmeticCell1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if (self.arrQuestionAnswer?.specificationValue?.count ?? 0) > 0 {
            self.selectedAppCode = self.arrQuestionAnswer?.specificationValue?[indexPath.item].appCode ?? ""
        }else {
            self.selectedAppCode = self.arrQuestionAnswer?.conditionValue?[indexPath.item].appCode ?? ""
        }
        
        print(self.selectedAppCode)
        
        
        AppResultString = AppResultString + self.selectedAppCode + ";"
        
        guard let didFinishRetryDiagnosis = self.TestDiagnosis else { return }
        didFinishRetryDiagnosis()
        self.dismiss(animated: false, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: self.cosmeticCollectionView.bounds.width/2 - 10, height: self.cosmeticCollectionView.bounds.width/2 - 10)
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
