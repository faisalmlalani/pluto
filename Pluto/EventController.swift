//
//  EventController.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 6/28/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import Eureka
import Firebase
import NVActivityIndicatorView

class EventController: FormViewController, NVActivityIndicatorViewable {
        
    // MARK: - UI Components
    
    var loadingView: NVActivityIndicatorView?
    
    func handleCreateEvent() {
        
        // The user is saving a new event.
        // Check if the user has filled out all the required fields.
        if form.validate().isEmpty {
            
            // Create the event.
            createEvent()
            
            // Dismiss the controller.
            navigationController?.popViewController(animated: true)
        }
    }
    
    func handleUpdateEvent() {
        
        if let eventTitle = newEventValues["title"], let eventImage = newEventValues["eventImage"] {
            
            // The user is updating a created event.
            // Check if the user has filled out all the required fields.
            if form.validate().isEmpty {
                
                // Update the event.
                updateEvent(eventTitle: eventTitle as! String, eventImage: eventImage as! String)
            }
        }
        
        // Dismiss the controller.
        navigationController?.popViewController(animated: true)
    }
    
    func handleChangeEventCount() {
        
        if let eventToBeAddedOrRemoved = self.event {
            
            // The user wants to add a created event.
            changeEventCount(event: eventToBeAddedOrRemoved)
            
        }
        
        // Dismiss the controller.
        navigationController?.popViewController(animated: true)
    }
    
    func createEvent() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            
            print("ERROR: could not get user ID.")
            return
        }
        
        // Add other required values like count to the event.
        newEventValues["count"] = 1 as AnyObject
        newEventValues["creator"] = uid as AnyObject
        
        guard let latitude = coordinate?.latitude, let longitude = coordinate?.longitude else {
            
            print("ERROR: no coordinate found.")
            return
        }
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        LocationService.sharedInstance.convertCoordinatesToAddress(latitude: latitude, longitude: longitude) { (address) in
            
            self.newEventValues["address"] = address as AnyObject
            
            /// An event created on Firebase with a random key.
            let newEventRef = DataService.ds.REF_EVENTS.childByAutoId()
            
            self.updateFirebaseWith(newEventReference: newEventRef, location: location)
        }
    }
    
    func updateFirebaseWith(newEventReference: DatabaseReference, location: CLLocation) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            
            print("ERROR: could not get user ID.")
            return
        }
        
        /// Uses the event reference to add data to the event created on Firebase.
        newEventReference.setValue(newEventValues, withCompletionBlock: { (error, reference) in
            
            /// The key for the event created on Firebase.
            let newEventKey = newEventReference.key
            
            /// A reference to the new event under the current user.
            let userEventRef = DataService.ds.REF_CURRENT_USER.child("events").child(newEventKey)
            userEventRef.setValue(true) // Sets the value to true indicating the event is under the user.
            
            /// A reference to the current user under the event.
            let eventUserRef = DataService.ds.REF_EVENTS.child(newEventKey).child("users").child(uid)
            eventUserRef.setValue(true)
            
            // Save the event location to Firebase.
            let geoFire = GeoFire(firebaseRef: DataService.ds.REF_EVENT_LOCATIONS)
            geoFire?.setLocation(location, forKey: newEventKey)
            
            // Use the Event model to reference the event so we can add a message to it.
            let newEvent = Event(eventKey: newEventKey, eventData: self.newEventValues as Dictionary<String, AnyObject>)
            
            // Create a default message and add it to the event.
            EventService.sharedInstance.addDefaultMessagesTo(event: newEvent)
        })
    }
    
    func updateEvent(eventTitle: String, eventImage: String) {
        
        if let eventKey = self.event?.key {
        
            /// Holds the reference to the user's image key in the database.
            let eventRef = DataService.ds.REF_EVENTS.child(eventKey)
        
            // Sets the value for the updated fields.
            
            let updatedEvent = ["title": eventTitle as Any,
                                "eventImage": eventImage as Any]
            
            eventRef.updateChildValues(updatedEvent)
        }
    }
    
    func changeEventCount(event: Event) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            
            print("ERROR: could not get user ID.")
            return
        }
        
        if let eventKey = event.key {
            
            let eventRef = DataService.ds.REF_EVENTS.child(eventKey).child("events").child(uid)
            let userEventRef = DataService.ds.REF_CURRENT_USER_EVENTS.child(eventKey)
            
            // Adjust the database to reflect whether or not the user is going to the event.
            
            EventService.sharedInstance.checkIfUserIsGoingToEvent(eventKey: eventKey) { (isUserGoing) in
                
                if isUserGoing {
                    
                    event.adjustCount(addToCount: false)
                    eventRef.removeValue()
                    userEventRef.removeValue()
                    
                } else {
                    
                    event.adjustCount(addToCount: true)
                    eventRef.setValue(true)
                    userEventRef.setValue(true)
                }
            }
        }
    }
    
    // MARK: - Global Variables
    
    var coordinate: CLLocationCoordinate2D?
    
    var event: Event?
    
    var isNewEvent = false
    var newEventValues = [String: AnyObject]()
    var isEventCreator = false
    
    // MARK: - View Configuration

    fileprivate func navigationBarCustomization() {
        
        // Set the color of the navigationItem to white.
        let colorAttribute = [NSForegroundColorAttributeName: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = colorAttribute
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBarCustomization()
        
        // Customize the view.
        tableView.backgroundColor = HIGHLIGHT_COLOR
        tableView.separatorColor = LIGHT_BLUE_COLOR
        
        checkPassedInEvent()
    }
    
    func checkPassedInEvent() {
        
        var navigationItemTitle: String?
        var manipulateEventBarButtonItem: UIBarButtonItem?
        
        guard let uid = Auth.auth().currentUser?.uid else {
            
            print("ERROR: could not get user ID.")
            return
        }
        
        if event == nil {
            
            // The user wants to create a new event.
            isNewEvent = true
            isEventCreator = true
            
            newEventValues = ["title": "", "eventImage": "", "eventDescription": "", "address": "", "timeStart": Date(), "timeEnd": Date()] as [String: AnyObject]
            
            LocationService.sharedInstance.convertCoordinatesToAddress(latitude: (self.coordinate?.latitude)!, longitude: (self.coordinate?.longitude)!, completion: { (address) in
                
                self.newEventValues["address"] = address as AnyObject
            })
            
            navigationItemTitle = "Create Event"
            manipulateEventBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleCreateEvent))
            navigationItem.rightBarButtonItems = [manipulateEventBarButtonItem!]
            
        } else {

            newEventValues = ["title": event?.title,
                              "eventImage": event?.image,
                              "eventDescription": event?.eventDescription,
                              "address": event?.address,
                              "timeStart": event?.timeStart,
                              "timeEnd": event?.timeEnd] as [String: AnyObject]
            
            // The user is viewing a created event.
            // Check if the user is the event creator.
            if let eventCreator = event?.creator {
                
                if eventCreator == uid {
                    
                    // The user is the event creator.
                    isEventCreator = true
                    
                    navigationItemTitle = "Edit Event"
                    manipulateEventBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(handleUpdateEvent))
                    navigationItem.rightBarButtonItems = [manipulateEventBarButtonItem!]
                    
                } else {
                    
                    // The user is not the creator.
                    self.tableView.isUserInteractionEnabled = false
                    
                    navigationItemTitle = "Event Details"
                    
                    if let eventKey = event?.key {
                    
                        // Check if the user is already going to the event.
                        EventService.sharedInstance.checkIfUserIsGoingToEvent(eventKey: eventKey, completion: { (isUserGoing) in
                            
                            if isUserGoing {
                                
                                manipulateEventBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_clear_white"), style: .plain, target: self, action: #selector(self.handleChangeEventCount))
                                
                            } else {
                                
                                manipulateEventBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_add_white"), style: .plain, target: self, action: #selector(self.handleChangeEventCount))
                            }
                            
                            self.navigationItem.rightBarButtonItems = [manipulateEventBarButtonItem!]
                        })
                    }
                }
            }
        }
        
        navigationItem.title = navigationItemTitle
        setUpForm()

    }
    
    func setUpForm() {
        
        // Create a form using the Eureka library.
        form
            +++ Section("Header")
            <<< TextRow() {
                $0.title = "Title"
                $0.cell.backgroundColor = DARK_BLUE_COLOR
                $0.value = newEventValues["title"] as? String
                $0.onChange { row in
                    
                    // Set the value to the event's title.
                    self.newEventValues["title"] = row.value as AnyObject
                }
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                $0.cellUpdate { (cell, row) in
                    
                    cell.titleLabel?.textColor = WHITE_COLOR
                    cell.textField.textColor = WHITE_COLOR
                    cell.tintColor = WHITE_COLOR
                    
                    if !row.isValid {
                        
                        // The row is empty, notify the user by highlighting the label.
                        cell.titleLabel?.textColor = UIColor.red
                    }
                }
            }
            <<< PushRow<String>() {
                $0.title = "Select image"
                $0.options = ["🍔", "🏈", "🎉", "🎷"]
                $0.cell.backgroundColor = DARK_BLUE_COLOR
                $0.value = (newEventValues["eventImage"] as? String)
                $0.selectorTitle = "Choose an emoji"
                $0.onChange { row in
                    
                    // Set the value to the event's image.
                    self.newEventValues["eventImage"] = row.value as AnyObject
                }
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                $0.cellUpdate { (cell, row) in
                    
                    cell.textLabel?.textColor = WHITE_COLOR
                    cell.tintColor = WHITE_COLOR
                    
                    if !row.isValid {
                        
                        // The row is empty, notify the user by highlighting the label.
                        cell.textLabel?.textColor = UIColor.red
                    }
                }
                _ = $0.onPresent { (from, to) in
                    
                    // Change the colors of the push view controller.
                    to.view.layoutSubviews()
                    to.tableView?.backgroundColor = DARK_BLUE_COLOR
                    to.tableView.separatorColor = LIGHT_BLUE_COLOR
                    to.selectableRowCellUpdate = { (cell, row) in
                     
                        cell.backgroundColor = DARK_BLUE_COLOR
                    }
                }
            }
            <<< TextAreaRow() {
                $0.placeholder = "Description"
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
                $0.cell.backgroundColor = DARK_BLUE_COLOR
                $0.value = newEventValues["eventDescription"] as? String
                $0.cellUpdate({ (cell, row) in
                    
                    cell.textView.backgroundColor = DARK_BLUE_COLOR
                    cell.textView.textColor = WHITE_COLOR
                    cell.textView.tintColor = WHITE_COLOR
                    cell.placeholderLabel?.textColor = WHITE_COLOR
                })
                $0.onChange { row in
                    
                    // Set the value to the event's description.
                    self.newEventValues["eventDescription"] = row.value as AnyObject
                }
            }
            
            +++ Section("Location")
            <<< LabelRow () {
                $0.title = (newEventValues["address"] as? String)
                $0.tag = "address"
                $0.cell.backgroundColor = DARK_BLUE_COLOR
                $0.cellUpdate({ (cell, row) in
                    
                    cell.textLabel?.textColor = WHITE_COLOR
                    cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 12)
                    
                })
            }
            <<< LocationRow(){
                $0.title = "Change location"
                $0.value = CLLocation(latitude: (coordinate?.latitude)!, longitude: (coordinate?.longitude)!)
                $0.cell.backgroundColor = DARK_BLUE_COLOR
                //$0.value = eventAddress
                $0.cellUpdate({ (cell, row) in
                    
                    cell.textLabel?.textColor = WHITE_COLOR
                    cell.tintColor = WHITE_COLOR
                    cell.detailTextLabel?.textColor = UIColor.clear
                    
                    if !row.isValid {
                        
                        // The row is empty, notify the user by highlighting the label.
                        cell.textLabel?.textColor = UIColor.red
                    }
                })
                $0.onChange { [weak self] row in
                    
                    let addressLabelRow: LabelRow! = self?.form.rowBy(tag: "address")
                    
                    // Set the value to the event's coordinates.
                    if let eventCoordinate = row.value?.coordinate {
                        
                        self?.coordinate = eventCoordinate
                        
                        LocationService.sharedInstance.convertCoordinatesToAddress(latitude: eventCoordinate.latitude, longitude: eventCoordinate.longitude, completion: { (address) in
                            
                            addressLabelRow.value = address
                        })
                    }
                }
            }
            
            +++ Section("Time")
            <<< DateTimeInlineRow("Starts") {
                $0.title = $0.tag
                $0.value = Date().addingTimeInterval(60*60*24)
                $0.cell.backgroundColor = DARK_BLUE_COLOR
                $0.value = (newEventValues["timeStart"] as? String)?.toDate()
                $0.cellUpdate { (cell, row) in
                    
                    cell.textLabel?.textColor = WHITE_COLOR
                    cell.tintColor = WHITE_COLOR
                    cell.detailTextLabel?.textColor = WHITE_COLOR
                    
                    if self.isNewEvent {
                        
                        // Set the starting value to the event's start time.
                        let timeStart = row.value?.toString()
                        self.newEventValues["timeStart"] = timeStart as AnyObject
                    }
                }
                }
                .onChange { [weak self] row in
                    
                    let endRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
                    
                    if let endRowValue = endRow.value {
                    
                        if row.value?.compare(endRowValue) == .orderedDescending {
                            
                            endRow.value = Date(timeInterval: 60*60, since: row.value!)
                            
                            endRow.cell!.textLabel?.textColor = UIColor.red
                            
                            endRow.updateCell()
                            
                            // Set the value to the event's start time.
                            let timeStart = row.value?.toString()
                            self?.newEventValues["timeStart"] = timeStart as AnyObject
                            
                            // Set the endRow's value to the event's end time (in case he/she does not change the end row).
                            let timeEnd = endRowValue.toString()
                            self?.newEventValues["timeEnd"] = timeEnd as AnyObject
                        }
                    }
                }
                .onExpandInlineRow { cell, row, inlineRow in
                    
                    inlineRow.cellUpdate() { cell, row in
                        cell.datePicker.datePickerMode = .dateAndTime
                        cell.datePicker.backgroundColor = DARK_BLUE_COLOR
                        cell.datePicker.setValue(WHITE_COLOR, forKey: "textColor")
                    }
                    let color = cell.detailTextLabel?.textColor
                    row.onCollapseInlineRow { cell, _, _ in
                        cell.detailTextLabel?.textColor = color
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
            }
            <<< DateTimeInlineRow("Ends") {
                $0.title = $0.tag
                $0.value = Date().addingTimeInterval(60*60*25)
                $0.cell.backgroundColor = DARK_BLUE_COLOR
                $0.value = (newEventValues["timeEnd"] as? String)?.toDate()
                $0.cellUpdate { (cell, row) in
                    
                    cell.textLabel?.textColor = WHITE_COLOR
                    cell.tintColor = WHITE_COLOR
                    cell.detailTextLabel?.textColor = WHITE_COLOR
                    
                    if self.isNewEvent {
                        
                        // Set the starting value to the event's end time.
                        let timeEnd = row.value?.toString()
                        self.newEventValues["timeEnd"] = timeEnd as AnyObject
                    }
                }
                }
                .onChange { [weak self] row in
                    let startRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                    
                    if let startRowValue = startRow.value {
                    
                        if row.value?.compare(startRowValue) == .orderedAscending {
                            
                            row.cell!.textLabel?.textColor = UIColor.red
                        }
                            
                        else {
                            
                            row.cell!.textLabel?.textColor = WHITE_COLOR
                        }
                    }
                    
                    row.updateCell()
                    
                    // Set the value to the event's end time.
                    let timeEnd = row.value?.toString()
                    self?.newEventValues["timeEnd"] = timeEnd as AnyObject
                }
                .onExpandInlineRow { cell, row, inlineRow in
                    inlineRow.cellUpdate { cell, dateRow in
                        cell.datePicker.datePickerMode = .dateAndTime
                        cell.datePicker.backgroundColor = DARK_BLUE_COLOR
                        cell.datePicker.setValue(WHITE_COLOR, forKey: "textColor")
                    }
                    let color = cell.detailTextLabel?.textColor
                    row.onCollapseInlineRow { cell, _, _ in
                        cell.detailTextLabel?.textColor = color
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
        }
        
        // Add a delete option if the user is the event's creator.
        if !isNewEvent && isEventCreator {
            
            form
                +++ Section("Delete")
                <<< ButtonRow() { (row: ButtonRow) -> Void in
                    
                        row.title = "Delete"
                    }
                    .cellUpdate({ (cell, row) in
                        
                        cell.backgroundColor = DARK_BLUE_COLOR
                        cell.textLabel?.textColor = UIColor.red
                    })
                    .onCellSelection { [weak self] (cell, row) in
                        
                        // Delete the event.
                        if let eventToBeDeleted = self?.event {
                            
                            self?.deleteEvent(event: eventToBeDeleted)
                        }
                    }
        }
    }
    
    func deleteEvent(event: Event) {
        
        let notice = SCLAlertView()
        
        notice.addButton("Delete") { 
            
            if let eventKey = event.key {
                                
                DataService.ds.REF_EVENTS.child(eventKey).removeValue()
                DataService.ds.REF_CURRENT_USER_EVENTS.child(eventKey).removeValue()
                DataService.ds.REF_EVENT_LOCATIONS.child(eventKey).removeValue()
                
                // Grab the messages under the event and delete them.
                MessageService.sharedInstance.deleteMessagesUnder(eventKey: eventKey, completion: { 
                    
                    DataService.ds.REF_EVENT_MESSAGES.child(eventKey).removeValue()
                })
            }
            
            // Dismiss the controller.
            self.navigationController?.popViewController(animated: true)
        }
        
        notice.showWarning("Are you sure?", subTitle: "This event will be deleted and event-goers will be notified.", closeButtonTitle: "On second thought...")
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        // Change header label color.
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel?.textColor = LIGHT_BLUE_COLOR
        }
    }
}
