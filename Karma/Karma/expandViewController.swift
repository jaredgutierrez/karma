 //
//  expandViewController.swift
//  karma2
//
//  Created by Jared Gutierrez on 4/2/16.
//  Copyright © 2016 Jared Gutierrez. All rights reserved.
//

import UIKit
import MapKit
import Parse

class expandViewController: UIViewController, UITextViewDelegate{
    
    @IBOutlet weak var backgroundImageView: UIImageView!

    @IBOutlet weak var receivedMessage: UITextView!
    @IBOutlet weak var response: UITextView!
    
    @IBOutlet weak var date: UILabel!
    
    @IBOutlet weak var sentMapView: MKMapView!
    
    @IBOutlet weak var sendReplyButton: UIButton!
    
//    func heightForView(text:String, #font:UIFont, #width:CGFloat) -> CGFloat{
//        let label:UILabel = UILabel(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width - 20, CGFloat.max))
//
//        return label.frame.height
//    }

    
    override func viewDidLoad() {
        self.view.sendSubviewToBack(backgroundImageView)
        
        
        receivedMessage.backgroundColor = UIColor(netHex: 0xFFA54F)
        self.response.clipsToBounds = false
        self.response.layer.cornerRadius = 3
        
        
        self.receivedMessage.clipsToBounds = true
        self.receivedMessage.layer.cornerRadius = 3
        
        self.receivedMessage.backgroundColor = UIColor(netHex: 0xF9A75E)
        //self.receivedMessage.backgroundColor = UIColor(red: 0.965, green: 0.698, blue: 0.42, alpha: 1.0)
        setPlaceholder()
        addMapPin()
        markAsRead()
        self.automaticallyAdjustsScrollViewInsets = false
        
        date.text = "Sent " + String(cleanTime(message!["sentDate"] as! NSDate))

        receivedMessage.text = message!["messageBody"] as? String
        receivedMessage.scrollEnabled = true
        receivedMessage.showsVerticalScrollIndicator = false
        receivedMessage.showsHorizontalScrollIndicator = false
        
        if replySent {
            self.response.editable = false
            response.textColor = UIColor.blackColor()
            response.textAlignment = NSTextAlignment.Center
            response.layer.shadowOffset = CGSizeMake(0, 1)
            response.layer.shadowColor = UIColor(netHex:0xCDBA96).CGColor
            response.layer.shadowOpacity = 0.7
            response.showsHorizontalScrollIndicator = false
            response.showsVerticalScrollIndicator = false
            
            
            self.sendReplyButton.hidden = true
            findReply()
        } else {
            if replyOpenText {
                response.becomeFirstResponder()
                print("wwwwwwwoooootttt")
            }
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        

    }
    var message: PFObject?
    var replyOpenText = false
    var currentUser = PFUser.currentUser()
    var locationName = ""
    var replySent = false
    
    
    func findReply() {
        
        var query = PFQuery(className:"Replies")
//        query.whereKey("authorized", equalTo: true)
        query.whereKey("flagged", notEqualTo: true)
        
        query.whereKey("messageId", equalTo: message!.objectId!)
        
        query.findObjectsInBackgroundWithBlock {
            
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            
            
            if error == nil {
                
                // The find succeeded.
                
                // Do something with the found objects
                
                if let objects = objects {
                    
                    for object in objects {
                        
                        if ((object["senderId"] as! String) == self.currentUser!.objectId) {
                            
                            var responseMessage = object["replyBody"] as! String
                            
                            self.response.text = responseMessage
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                // Log details of the failure
                
                print("Error: \(error!) \(error!.userInfo)")
                
            }
            
        }
        
    }
    
    
    func setPlaceholder() {
        response.delegate = self
       
        response.text = "How would you like to reply?"
        response.textColor = UIColor.lightGrayColor()
    }
    
    func textViewDidBeginEditing(response: UITextView) {
        if response.textColor == UIColor.lightGrayColor() {
            response.text = nil
            response.textColor = UIColor.blackColor()
        }
        UIView.animateWithDuration(0.5) {
            self.view.frame = CGRectOffset(self.view.frame, 0, -UIScreen.mainScreen().bounds.height/3 - 10)
            
        }
    }
    
    func textViewDidEndEditing(response: UITextView) {
        if (response.text == "") {
            response.text = "How would you like to reply?"
            response.textColor = UIColor.lightGrayColor()
        }
        UIView.animateWithDuration(0.5) {
            self.view.frame = CGRectOffset(self.view.frame, 0, UIScreen.mainScreen().bounds.height/3 + 10)
            
        }
        response.resignFirstResponder()
    }
    
    func displayAlert(title: String, displayError: String) {
        
        let alert = UIAlertController(title: title, message: displayError, preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { action in
            
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func addNewReply() {
        
        var displayError = ""
        if response.text == "" {
            displayError = "Please enter a positive reply!"
        }
        
        if displayError != "" {
            displayAlert("Incomplete Form", displayError: displayError)
        } else {
            
            let replyText = response.text
            
            let newReply = PFObject(className:"Replies")
            
            newReply["senderId"] = currentUser!.objectId
            newReply["messageId"] = message!.objectId
            newReply["replyBody"] = replyText
            newReply["replyDate"] = NSDate()
            newReply["authorized"] = false
            
            
            newReply.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    // The object has been saved.
                    self.message!.addUniqueObject((self.currentUser?.objectId)!, forKey:"repliedIds")
                    self.message!.saveInBackground()
                    self.setPlaceholder()
                    self.displayAlert("Sent", displayError: "Reply Sent!")
                    print("sucesssss!!!!")
                    //self.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    // There was a problem, check error.description
                    
                    displayError = "Please try again later!"
                    
                    self.displayAlert("Could Not Send Reply", displayError: displayError)
                }
            }

        }
    }
    
    
    func markAsRead() {
        message!.addUniqueObject((self.currentUser?.objectId)!, forKey:"readIds")
        message!.saveInBackground()
    }
    
    func addMapPin() {
        let locGeoPoint = message!["sentLocation"] as! PFGeoPoint
        let latitude: CLLocationDegrees = locGeoPoint.latitude
        let longtitude: CLLocationDegrees = locGeoPoint.longitude
        
        let location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longtitude)
        
        let geoCoder = CLGeocoder()
        
        
        //locationNot2D has the same latitudes and longitudes as "location," but
        //is an object of type CLLocation, as opposed to CLLocation2D. The reverse geocoder
        //takes in a CLLocation object.
        let locationNot2D = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geoCoder.reverseGeocodeLocation(locationNot2D) {
            (placemarks, error) -> Void in
            
            if placemarks != nil {
                let placeArray = placemarks as [CLPlacemark]!
                
                // Place details
                var placeMark: CLPlacemark!
                placeMark = placeArray?[0]
                
                
                // City
                if let city = placeMark.locality
                {
                    print(city)
                    self.locationName += city as String
                    self.locationName += ", "
                }
                
                if let state = placeMark.administrativeArea
                {
                    print(state)
                    self.locationName += state as String
                    self.locationName += ", "
                }
                
                // Country
                if let country = placeMark.country
                {
                    print(country)
                    self.locationName += country as String
                }
                
                //These next three lines will add an annotation of the specific location.
                //Comment out these lines adding an annotation of the
                //general city.
                //                    annotation.title = self.locationName
                //                    annotation.coordinate = location
                //                    self.reachMap.addAnnotation(annotation)
                
                //localLocationName is necessary to hold the value of self.locationName
                //because self.locationName will be set to nil in the line after this geocodeAddressString block,
                //before this geocodeAddressString block is done running.
                let localLocationName = self.locationName
                let geo = CLGeocoder()
                geo.geocodeAddressString(localLocationName, completionHandler: {(placemarks: [CLPlacemark]?, error: NSError?) -> Void in
                    if((error) != nil){
                        
                        print("Error", error)
                    }
                        
                    else {
                        let placemark:CLPlacemark = placemarks![0]
                        let coordinates:CLLocationCoordinate2D = placemark.location!.coordinate
                        
                        let pointAnnotation:MKPointAnnotation = MKPointAnnotation()
                        pointAnnotation.coordinate = coordinates
                        pointAnnotation.title = localLocationName
                        self.sentMapView.addAnnotation(pointAnnotation)
                        self.sentMapView.centerCoordinate = coordinates
                        self.sentMapView.selectAnnotation(pointAnnotation, animated: true)
                        print("Added annotation to map view")
                    }
                })
            }
            self.locationName = ""
        }
        
        
    }
    
    
    func cleanTime(sentDate: NSDate) -> String {
        
        var timeInterval : NSTimeInterval = sentDate.timeIntervalSinceNow
        timeInterval = timeInterval * -1
        
        //print(timeInterval)
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < (60 * 60) {
            let numMinutes = Int(floor(timeInterval / 60))
            return String(numMinutes) + " minutes ago"
        } else if timeInterval < (2*60*60) {
            return "1 hour ago"
        } else if timeInterval < (24*60*60) {
            let numHours = Int(floor(timeInterval / (60*60)))
            return String(numHours) + " hours ago"
        } else if timeInterval < (48 * 60 * 60) {
            return "1 day ago"
        } else if timeInterval < (7 * 24 * 60 * 60) {
            let numDays = Int(floor(timeInterval / (24*60*60)))
            return String(numDays) + " days ago"
        } else if timeInterval < (2 * 7 * 24 * 60 * 60) {
            return "1 week ago"
        } else if timeInterval < (30 * 24 * 60 * 60) {
            let numWeeks = Int(floor(timeInterval / (7*24*60*60)))
            return String(numWeeks) + " weeks ago"
        } else if timeInterval < (2 * 30 * 24 * 60 * 60) {
            return "1 month ago"
        } else if timeInterval < (365 * 24 * 60 * 60) {
            let numMonths = Int(floor(timeInterval / (30*24*60*60)))
            return String(numMonths) + " months ago"
        } else if timeInterval < (365 * 24 * 60 * 60) {
            return "1 year ago"
        }
        
        let numYears = Int(floor(timeInterval / (365*24*60*60)))
        return String(numYears) + " years ago"
        
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func sendReply(sender: AnyObject) {
        addNewReply()
        self.response.endEditing(true)
    }
    
   
    @IBOutlet weak var mapFrom: MKMapView!

}
