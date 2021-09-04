//
//  AppConstant.swift
//  InstaCashApp
//
//  Created by Sameer Khan on 06/07/21.
//

import UIKit
import SwiftyJSON

//var AppdidFinishTestDiagnosis: (() -> Void)?
//var AppdidFinishRetryDiagnosis: (() -> Void)?

var AppBaseUrl = "https://exuat.reboxed.co/api/v1/public/"
var AppUserName = "storeIOS"
var AppApiKey = "b99d0f356515682d17cc90265703afc9"

// Api Name
let kStartSessionURL = AppBaseUrl + "startSession"
let kGetProductDetailURL = AppBaseUrl + "getProductDetail"
let kUpdateCustomerURL = AppBaseUrl + "updateCustomer"
let kGetSessionIdbyIMEIURL = AppBaseUrl + "getSessionIdbyIMEI"
let kPriceCalcNewURL = AppBaseUrl + "priceCalcNew"
let kSavingResultURL = AppBaseUrl + "savingResult"
let kIdProofURL = AppBaseUrl + "idProof"


var AppCurrentProductBrand = ""
var AppCurrentProductName = ""
var AppCurrentProductImage = ""

var hardwareQuestionsCount = 0
var AppQuestionIndex = -1

var AppHardwareQuestionsData : CosmeticQuestions?

// ***** App Theme Color ***** //
var AppThemeColorHexString : String?
var AppThemeColor : UIColor = UIColor().HexToColor(hexString: AppThemeColorHexString ?? "#591091", alpha: 1.0)

// ***** Font-Family ***** //
var AppFontFamilyName : String?

var AppBrownFontRegular = "\(AppFontFamilyName ?? "Brown")-Regular"
var AppBrownFontBold = "\(AppFontFamilyName ?? "Brown")-Bold"

var AppSupplyFontRegular = "\(AppFontFamilyName ?? "Supply")-Regular"
var AppSupplyFontMedium = "\(AppFontFamilyName ?? "Supply")-Medium"
var AppSupplyFontBold = "\(AppFontFamilyName ?? "Supply")-Bold"

var AppDrukFontMedium = "\(AppFontFamilyName ?? "Druk")-Medium"
var AppDrukFontBold = "\(AppFontFamilyName ?? "Druk")-Bold"

// ***** Button Properties ***** //
var AppBtnCornerRadius : CGFloat = 10
var AppBtnTitleColorHexString : String?
var AppBtnTitleColor : UIColor = UIColor().HexToColor(hexString: AppBtnTitleColorHexString ?? "#FFFFFF", alpha: 1.0)

// ***** App Tests Performance ***** //
var holdAppTestsPerformArray = [String]()
var AppTestsPerformArray = [String]()
var AppTestIndex : Int = 0

let AppUserDefaults = UserDefaults.standard
var AppResultJSON = JSON()
var AppResultString = ""

var AppOrientationLock = UIInterfaceOrientationMask.all

var AppLicenseKey : String?
//var AppUserName : String?
//var AppApiKey : String?
var AppUrl : String?
var AppLastAdded : String?
var AppLicenseLeft : Int?
var AppLicenseConsumed : Int?
var AppResultApplicableTill : Int?
var AppResumeTestApplicableTill : Int?

var App_AssistedIsEnable : Bool?
var App_AssistedApplicableTill : Int?
var App_AutomatedIsEnable : Bool?
var App_AutomatedApplicableTill : Int?
var App_PhysicalIsEnable : Bool?
var App_PhysicalApplicableTill : Int?

