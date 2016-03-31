//
//  YelpClient.swift
//  alimentum
//
//  Created by Nitish Dayal on 3/30/16.
//  Copyright © 2016 Joseph Park. All rights reserved.
//

import UIKit
import OAuthSwift

struct YelpAPIConsole {
    var consumerKey = Credentials().c_key
    var consumerSecret = Credentials().c_secret
    var accessToken = Credentials().a_Token
    var accessTokenSecret = Credentials().a_TokenSecret
}

class YelpAPIClient: NSObject {
    
    let APIBaseUrl = "https://api.yelp.com/v2"
    let clientOAuth: OAuthSwiftClient?
    let apiConsoleInfo: YelpAPIConsole
    
    override init() {
        apiConsoleInfo = YelpAPIConsole()
        self.clientOAuth = OAuthSwiftClient(consumerKey: apiConsoleInfo.consumerKey, consumerSecret: apiConsoleInfo.consumerSecret, accessToken: apiConsoleInfo.accessToken, accessTokenSecret: apiConsoleInfo.accessTokenSecret)
        super.init()
    }
    
    /*
     
     searchPlacesWithParameters: Function that can search for places using any specified API parameter
     
     Arguments:
     
     searchParameters: Dictionary<String, String>, optional (See https://www.yelp.co.uk/developers/documentation/v2/search_api )
     successSearch: success callback with data (NSData) and response (NSHTTPURLResponse) as parameters
     failureSearch: error callback with error (NSError) as parameter
     
     Example:
     
     var parameters = ["ll": "37.788022,-122.399797", "category_filter": "burgers", "radius_filter": "3000", "sort": "0"]
     
     searchPlacesWithParameters(parameters, successSearch: { (data, response) -> Void in
     println(NSString(data: data, encoding: NSUTF8StringEncoding))
     }, failureSearch: { (error) -> Void in
     println(error)
     })
     
     
     */
    
    func searchPlacesWithParameters(searchParameters: Dictionary<String, String>, successSearch: (data: NSData, response: NSHTTPURLResponse) -> Void, failureSearch: (error: NSError) -> Void) {
        let searchUrl = APIBaseUrl + "/search"
        clientOAuth!.get(searchUrl, parameters: searchParameters, success: successSearch, failure: failureSearch)
    }
}
