//
//  ViewController.swift
//  Graphics
//
//  Created by Mindaugas on 8/17/15.
//  Copyright © 2015 Mindaugas. All rights reserved.
//

import UIKit
import CoreData


class ViewController: UIViewController {

    @IBOutlet weak var counterView: CounterView!
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var averageWaterDrunk: UILabel!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var graphView: GraphView!
    @IBOutlet weak var medalView: MedalView!
    
    var isGraphViewShowing = false
    let week = 7
    let counterMax = 8
    let dateFormat = "yyyy-MM-dd"
    let graphDataEntityName = "GraphData"
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var graphPoint = graphPoints
        if graphPoint.count == 0 {
            weekBefore()
            saveDrinkData(0, date: todaysDateAsString, objectContext: appDelegate.managedObjectContext)
        } else {
            counterLabel.text = String(graphPoint[graphPoint.count-1])
            counterView.counter = graphPoint[graphPoint.count-1]
            checkTotal()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func weekBefore(){
        let calendar = NSCalendar.currentCalendar()
        let date = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = dateFormat
        
        for(var i = week; i > 0; i--){
            let dayBeforeDate : String
                dayBeforeDate = dateFormatter.stringFromDate(calendar.dateByAddingUnit(NSCalendarUnit.Day, value: i * -1, toDate: date, options: NSCalendarOptions.MatchFirst)!)
            saveDrinkData(0, date: dayBeforeDate, objectContext: appDelegate.managedObjectContext)
        }
    }
    
    func setupGraphDisplay() {
        checkForDeletions()
        if let relevantData = getDataToUse {
            var average : Double = 0
            for (var i = 0; i <= relevantData.count; i++) {
                var index = i
                index++
                if let labelView = graphView.viewWithTag(index) as? UILabel {
                    let stringDate = relevantData[i].dataDate!
                    labelView.text = formattedGraphDate(stringDate, index: i)
                    average = average + (relevantData[i].cupsDrunk?.doubleValue)!
                }
            }
            averageWaterDrunk.text = "\(average/(relevantData.count as NSNumber).doubleValue)"
            graphView.setNeedsDisplay()
        }
        
    }

    @IBAction func btnPushButton(button: PushButtonView) {
        
        if (button.isAddButton) {
            if(counterView.counter < counterMax){
                counterView.counter++
            }
        } else {
            if counterView.counter > 0 {
                counterView.counter--
            }
        }
        counterLabel.text = String(counterView.counter)
        
        saveDrinkData(counterView.counter, date: todaysDateAsString, objectContext: appDelegate.managedObjectContext)
        checkForDeletions()
        
        if isGraphViewShowing {
            counterViewTap(nil)
        }
        
        checkTotal()
    }
    
    @IBAction func counterViewTap(gesture:UITapGestureRecognizer?) {
        if (isGraphViewShowing) {
            
            //hide Graph
            UIView.transitionFromView(graphView,
                toView: counterView,
                duration: 1.0,
                options: [.TransitionFlipFromLeft, .ShowHideTransitionViews],
                completion:nil)
        } else {
            
            //show Graph
            UIView.transitionFromView(counterView,
                toView: graphView,
                duration: 1.0,
                options: [.TransitionFlipFromLeft, .ShowHideTransitionViews],
                completion: nil)
            setupGraphDisplay()
        }
        isGraphViewShowing = !isGraphViewShowing
        checkTotal()
    }
    
    func checkTotal() {
        if counterView.counter >= counterMax {
            medalView.showMedal(true)
        } else {
            medalView.showMedal(false)
        }
    }
    
    func checkForDeletions(){
        var dataToCheck : ([GraphData]?, Int?)
        dataToCheck = fetchData()
        if dataToCheck.1! == counterMax {
            let predicate = NSPredicate(format: "dataDate == %@", (dataToCheck.0!.first?.dataDate!)!)
            let fetchRequest = NSFetchRequest(entityName: graphDataEntityName)
            fetchRequest.predicate = predicate
            let fetchedEntities : [GraphData] = executeFetchRequestT(fetchRequest, managedObjectContext: appDelegate.managedObjectContext)!
            let entityToDelete = fetchedEntities.first
            appDelegate.managedObjectContext.deleteObject(entityToDelete!)
            do {
                try appDelegate.managedObjectContext.save()
            } catch {
                print("Could not delete \(error)")
            }
        }
    }
    
    func formattedGraphDate(stringToFormat: String, index: Int) -> String {
        let fullNameArr = split(stringToFormat.characters){$0 == "-"}.map(String.init)
        let dateComponents = NSDateComponents()
        dateComponents.year = (fullNameArr[0] as NSString).integerValue
        dateComponents.month = (fullNameArr[1] as NSString).integerValue
        dateComponents.day = (fullNameArr[2] as NSString).integerValue
        
        let formatedDate = NSCalendar.currentCalendar().dateFromComponents(dateComponents)!
        let formatter = NSDateFormatter()
        if index == 0 {
            formatter.dateFormat = "MMM dd"
        } else {
            formatter.dateFormat = "dd"
        }
        return formatter.stringFromDate(formatedDate)
    }
    
    func saveDrinkData(name: Int, date: String, objectContext: NSManagedObjectContext) {
        do {
            let fetchRequestDate = NSFetchRequest(entityName: graphDataEntityName)
            fetchRequestDate.predicate = NSPredicate(format: "dataDate = %@", date)
            let graphData : [GraphData]? = executeFetchRequestT(fetchRequestDate, managedObjectContext: objectContext)
            if (graphData != nil && graphData!.count != 0) {
                let managedObject = graphData![0]
                managedObject.cupsDrunk = name
            }
            else {
                let entity =  NSEntityDescription.entityForName(graphDataEntityName,
                    inManagedObjectContext:objectContext)
                
                let newConsumptionEntry = NSManagedObject(entity: entity!,
                    insertIntoManagedObjectContext:objectContext)
                
                newConsumptionEntry.setValue(name, forKey: "cupsDrunk")
                newConsumptionEntry.setValue(date, forKey: "dataDate")
            }
            try objectContext.save()
        } catch {
            print("Could not insert \(error)")
        }
    }
    
    func fetchData() -> ([GraphData]?, Int?){
        let fetchRequestAll = NSFetchRequest(entityName:graphDataEntityName)
        let graphData : [GraphData] = executeFetchRequestT(fetchRequestAll, managedObjectContext: appDelegate.managedObjectContext)!
        return (graphData, graphData.count)
    }
    
    func executeFetchRequestT<T:AnyObject>(request:NSFetchRequest, managedObjectContext:NSManagedObjectContext, error: NSErrorPointer = nil) -> [T]? {
        let localError: NSError? = nil
        do {
            if let results:[AnyObject] = try managedObjectContext.executeFetchRequest(request) {
                if results.count > 0 {
                    if results[0] is T {
                        let casted:[T] = results as! [T]
                        return .Some(casted)
                    }
                    
                    if error != nil {
                        error.memory = NSError(domain: "error_domain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Object in fetched results is not the expected type."])
                    }
                    
                } else if 0 == results.count {
                    return [T]() // just return an empty array
                }
            }
            
        } catch {
            print("Could not fetch \(error)")
        }
        
        
        if error != nil && localError != nil {
            error.memory = localError!
        }
        
        return .None
    }

    
    var todaysDateAsString : String {
        let todaysDate:NSDate = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.stringFromDate(todaysDate)
    }
    
    var graphPoints : [Int] {
        get {
            if let graphData = getDataToUse {
                var graphPoint:[Int] = []
                
                for(var i = 0; i < graphData.count; i++){
                    graphPoint.append(graphData[i].cupsDrunk!.integerValue)
                }
                return graphPoint
            }
            return []
        }
    }
    
    var getDataToUse : [GraphData]?{
        let fetchedData = fetchData()
        if fetchedData.1! != 0 {
            return fetchedData.0!
        } else {
            return nil
        }
    }
    
}

