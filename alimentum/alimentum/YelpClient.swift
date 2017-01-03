//
//  AppDelegate.swift
//  alimentum
//
//  Created by Joseph Park, Nitish Dayal
//  Copyright © 2016 Joseph Park, Nitish Dayal. All rights reserved.
//
//  Libraries used in project include: UIKit, CoreLocation, 0AuthSwift
//

import UIKit
import OAuthSwift

//MARK: - YelpAPIConsole struct, to hold key & secret values for API call
struct YelpAPIConsole {
    
    var consumerKey = Credentials().c_key
    var consumerSecret = Credentials().c_secret
    var accessToken = Credentials().a_Token
    var accessTokenSecret = Credentials().a_TokenSecret
    
}


//MARK: - Make custom class YelpAPIClient that conforms to class NSObject
class YelpAPIClient: NSObject {
    
    let yelpSearchUrl = "https://api.yelp.com/v2/search"
    let clientOAuth: OAuthSwiftClient?
    let apiConsoleInfo: YelpAPIConsole
    
    override init() {
        apiConsoleInfo = YelpAPIConsole()
        self.clientOAuth = OAuthSwiftClient(consumerKey: apiConsoleInfo.consumerKey, consumerSecret: apiConsoleInfo.consumerSecret, accessToken: apiConsoleInfo.accessToken, accessTokenSecret: apiConsoleInfo.accessTokenSecret)
        super.init()
    }

    /* Add GET request functionality with Yelp! API authorized search URL */
    func searchPlacesWithParameters(_ searchParameters: Dictionary<String, String>, successSearch: @escaping (_ data: NSData, _ response: HTTPURLResponse) -> Void, failureSearch: (_ error: NSError) -> Void) {
        clientOAuth!.get(yelpSearchUrl, parameters: searchParameters, success: successSearch, failure: failureSearch)
    }
}
