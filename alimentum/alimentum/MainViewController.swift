//
//  AppDelegate.swift
//  alimentum
//
//  Created by Joseph Park, Nitish Dayal
//  Copyright © 2016 Joseph Park, Nitish Dayal. All rights reserved.


import UIKit
import CoreLocation
import OAuthSwift

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {

    
//MARK: - Define variables to be used throughout app
    
    /* View Components */
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var viewTitle: UILabel!
    
    /* API Implementation (see YelpClient.swift) */
    let apiConsoleInfo = YelpAPIConsole()
    let client = YelpAPIClient()
    var apiSearchTerm: NSString!
    
    /* Define variables to be used for CoreLocation functionality */
    let locationManager = CLLocationManager()           //Provides access to CoreLocation framework
    var locationStatus : NSString = "Not Started"       // String updated based on location/privacy settings of User
    var userCurrentLocation: String!                    // Variable to store current location in form of City,State,ZIP,Country for API call
    let reverseGeolocation = CLGeocoder()               // Set CoreLocationGeoCoder to var reverseGeolocation.
    
    /* Variables for filtering returned address from API GET request */
    let chars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890,.:".characters)
    
    /* Define variabled to be assigned to returned values from API GET request */
    var businessList: NSArray = []          //Array of businesses returned from API call
    var amtOfBusinessesAvailable: Int!      //Total amt of businesses returned from API call (this var isn't used in the current iteration of this app)
    var phoneNumber = String()
    var categories = String()
    

    
    //MARK: - Default functions that are a part of UIViewController
    
    override func viewDidLoad() {
        print("viewdidload")
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        initAppearance()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
        loadingSpinner.layer.cornerRadius = 2.5

        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100.0
        DispatchQueue.main.async(execute: {
            self.checkLocationServices()
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: - TableView Functions
    
    /* Making separate section for each business to allow for spacing between cells */
    func numberOfSections(in tableView: UITableView) -> Int {
        if businessList.count > 1 {
            //print("sectionsintable \(businessList.count)")
            return businessList.count
        }
        else {
            return 1
        }
    }
    
    /* Each section should only have one row, for the one business it will hold */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section > 0 {
            print("rowsinsection")
            return 1
        } else {
            print(section, "rowsinsection")
            return 0
        }
    }
    
    /* Clear header for each section so that background view appears. */
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        print("headerview")
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    /* Set values for each cell */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "businessCellIdentifier", for: indexPath) as! BusinessListingTableViewCell
        print("tableview cellforrow ", indexPath.section)
        
        //Check if businessList array has length greater than 0 (contains any values)
        if businessList.count > 0 {
            
            //Declare constants for current cell, forcing type String where values are not implicity unwrapped as type String
            let currentBusiness = businessList[indexPath.section]
            
            //Unfiltered (AKA "dirty") values of currentBusiness city and display-address (pre-formatted address value...which is still really dirty)
            let dirtyCity = String(currentBusiness["location"]!!["city"]!!)
            let dirtyAddress = String(currentBusiness["location"]!!["display_address"]!!)
            
            //Check if currentBusiness has phone number, and if so then set variable phone to be said phone number
            if (currentBusiness["display_phone"]!) != nil {
                phoneNumber = String(currentBusiness["display_phone"]!!)
            } else {
                phoneNumber = "N/A"
            }
            
            //Set constant businessAddress to be returned value from function cleanReturnedAddress, passing in dirtyAddress and dirtyCity values as parameters
            let businessAddress = cleanReturnedAddress(dirtyAddress, city: dirtyCity)
            
            //Set display values for current cell
            cell.businessName.text = "\(currentBusiness["name"]!! as! String)"
            cell.callPhoneNumber.tag = indexPath.section
            cell.phoneNumber.text = "\(phoneNumber)"
            cell.address.text = "\(businessAddress)"
//            cell.foodType.text = "\(currentBusiness["categories"]!! as! String))"
            cell.rating.text = "\(String(currentBusiness["rating"]!! as! Int))/5 Yelp! rating"
        }
        return cell
    }
    
    
    //MARK: - CoreLocation Functions
    
    /* Simply checks to see if user has provided us with location access, then prints to log what type of accesss we have been granted */
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var shouldIAllow = false
        
        switch status {
        case CLAuthorizationStatus.restricted:
            locationStatus = "Restricted access to location"
        case CLAuthorizationStatus.denied:
            locationStatus = "User denied access to location"
        case CLAuthorizationStatus.notDetermined:
            locationStatus = "Status not determined"
        default:
            locationStatus = "Allowed access to location"
            shouldIAllow = true
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "LabelHasbeenUpdated"), object: nil)
        if (shouldIAllow == true) {
            NSLog("Location set to allowed")
            locationManager.startUpdatingLocation()
        } else {
            NSLog("Denied access: \(locationStatus)")
        }
    }
    
    /* Function is a required delegate method (this viewController conforms to the CLLocationManagerDelegate by including this function)
     that is called whenever the user's location is updated. Defaults to updating every second */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //Throw it in reverse. Gets placemark location (see Swift docs for type CLPlacemark) value from provided latitude/longitude.
        reverseGeolocation.reverseGeocodeLocation(manager.location!) { (placemarks, error) in
            if (error != nil) {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
            }
            if placemarks!.count > 0 {
                let pm = placemarks![0] as CLPlacemark
                self.displayLocationInfo(pm) //calls displayLocationInfo function if reverseGeolocation is successful
            } else {
                print("Problem with the data received from geocoder")
            }
        }
    }
    
    
    func displayLocationInfo(_ placemark: CLPlacemark) {
        
        //Set var userCurrentLocation to the returned values from successful reverseGeolocation.
        userCurrentLocation = "\(placemark.locality!),\(placemark.postalCode!),\(placemark.administrativeArea!),\(placemark.country!)"
        
        //stop updating location to save battery life (The location should essentially be grabbed only one time instead of updating every second)
        locationManager.stopUpdatingLocation()
        
        //Call function that sends API request, passing in the var userCurrentLocation = "City,State,ZIP,Country", and setting search term to "all"
        apiSearchTerm = "all"
        getFoodNearMe(userCurrentLocation, term: apiSearchTerm)
        
    }
    
    
    /* Function is a optional delegate method (this viewController can take advantage of this method because it conforms to the
     CLLocationManagerDelegate protocol) */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error finding location: \(error.localizedDescription)")
    }
    
    
    //MARK: - Custom Functions
    
    /* Function called if '+' button next to phone # is pressed */
    @IBAction func phoneCallButton(_ sender: UIButton) {
        //If businessList at index sender.tag has value for key "display_phone", open dialer app and autodial number
        if let numberToDial = businessList[sender.tag]["display_phone"]! as? String {
            let dialerValue = URL(string: "tel://\((numberToDial))")
            UIApplication.shared.openURL(dialerValue!)
        }
            //If businessList at index sender.tag has no value for key "display_phone", display UIAlertController
        else {
            showNilPhoneAlert()
        }
    }
    
    /* Function called when value of UISegmentedControl is changed */
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        
        //Changes term for API call from "all" to "delivery" to match corresponding Segmented Control option
        switch segmentControl.selectedSegmentIndex {
        case 0:
            self.apiSearchTerm = "all"
        case 1:
            self.apiSearchTerm = "delivery"
        default:
            break
        }
        
        //Calls function getFoodNearMe, passing in current location and updated API search term
        getFoodNearMe(userCurrentLocation, term: apiSearchTerm)
    }
    
    func initAppearance() -> Void {
        
        //Set background color
        let background = CAGradientLayer().turquoiseColor()
        background.frame = self.view.bounds
        self.view.layer.insertSublayer(background, at: 0)
    }
    
    
    /* Function to make API request, passing in users location for parameter "location",
     term updates based on 'delivery' or 'all' */
    func getFoodNearMe(_ location: String, term: NSString){
        
        //While running API get request and setting up table, display activity indicator
        loadingSpinner.startAnimating()
        
        client.searchPlacesWithParameters(
            [
                "term": "\(term)",
                "location": "\(location)",
                "radius_filter": "8046.72",
                "category_filter": "restaurants",
                "sort": "0",
                "actionlinks" : "false",
                "limit" : "11",
                "open_now" : "10059"
            ], successSearch: { (data, response) -> Void in
                do {
                    let result = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    self.businessList = result["businesses"]! as! NSArray
                    self.amtOfBusinessesAvailable = result["total"]! as! Int
                    self.animateTable()
                    print(result)
                } catch let error as NSError {
                    print(error)
                }
                
        }) { (error) -> Void in
            print(error)
        }
    }
    func showRefeshAlert() {
        let alert = UIAlertController(title: "Refresh Location", message: "Please check your Location Service Settings", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (alert) in
            self.checkLocationServices()
        }))
        show(alert, sender: self)
    }
    
    /* This alert will be displayed if user does not have Location Services enabled. Will also direct them to their settings page so that they may turn it on */
    func showLocationAlert() {
        let alert = UIAlertController(title: "Location Error", message: "Please allow Alimentum to access your location. \n Set the location setting to be 'ON' in \n \n Settings > Privacy > Location Services", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (alert) in
            UIApplication.shared.openURL(URL(string: "prefs:root=Privacy")!)
            self.showRefeshAlert()
        }))
        show(alert, sender: self)
    }
    
    
    /* This alert will be displayed if the user selects the '+' button next to a phone number where a business does not have a valid number available */
    func showNilPhoneAlert() {
        let alert = UIAlertController(title: "No Number Listed", message: "Sorry, this business does not have a valid number listed! 😥", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        show(alert, sender: self)
    }
    
    /* Called from IntroPageViewController on first app launch and MainViewController every app launch */
    func checkLocationServices() {
        /* Once main view has appeared, check if user has enabled location services on their device */
        if CLLocationManager.locationServicesEnabled() == false {
            showLocationAlert()     // If user has location services disabled, show UIAlertView described below in func showAlert
            
        } else {
            switch CLLocationManager.authorizationStatus() {
            case CLAuthorizationStatus.authorizedAlways, CLAuthorizationStatus.authorizedWhenInUse:
                break
            case CLAuthorizationStatus.notDetermined:
                self.locationManager.requestAlwaysAuthorization()
            case CLAuthorizationStatus.restricted, CLAuthorizationStatus.denied:
                let alertController = UIAlertController(
                    title: "Background Location Access Disabled",
                    message: "In order to use this application, please go to Settings and set Location Access to 'While Using the App' or 'Always'.",
                    preferredStyle: .alert)
                
                let openAction = UIAlertAction(title: "Settings", style: .default) { (action) in
                    if let url = URL(string:UIApplicationOpenSettingsURLString) {
                        UIApplication.shared.openURL(url)
                        self.showRefeshAlert()
                    }
                }
                alertController.addAction(openAction)
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
    }
    
    /* Returns cleaned address after running filters on passed in values for displayAddress and city */
    func cleanReturnedAddress(_ address: String, city: String) -> String {
        
        let whiteSpaceString = String(address.characters.filter { chars.contains($0) })
        var returnString = whiteSpaceString.removeWhitespace().replacingOccurrences(of: ",", with: " ")
        let insertCommaHere = returnString.characters.index(returnString.endIndex, offsetBy: -10)
        returnString.remove(at: insertCommaHere)
        returnString.insert(",", at: insertCommaHere)
        
        return returnString
    }
    
    /* Animates the tableView on every API call */
    func animateTable() {
        DispatchQueue.main.async(execute: {
            print("dispatchAsync animatetable")
            self.tableView.reloadData()
            self.scrollToFirstRow()
            let cells = self.tableView.visibleCells
            let tableHeight: CGFloat = self.tableView.bounds.size.height
            
            for i in cells {
                let cell: UITableViewCell = i as UITableViewCell
                cell.transform = CGAffineTransform(translationX: 0, y: tableHeight)
            }
            
            var index = 0
            
            for a in cells {
                let cell: UITableViewCell = a as UITableViewCell
                UIView.animate(withDuration: 1.3, delay: 0.02 * Double(index), usingSpringWithDamping: 2.0, initialSpringVelocity: 0, options: .transitionFlipFromTop, animations: {
                    cell.transform = CGAffineTransform(translationX: 0, y: 0);
                    }, completion: nil)
                
                index += 1
            }
        })
        loadingSpinner.stopAnimating()
    }
    
    /* Scrolls view to top of table. Called after reloading tableView data in animateTable */
    func scrollToFirstRow() {
        let indexPath = IndexPath(row: 0, section: 1)
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
}
