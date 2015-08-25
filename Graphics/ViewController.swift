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
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        var graphPoint = graphPoints
        if graphPoint.count == 0 {
            weekBefore()
        } else {
            var relevantData = getDataToUse!
            if(relevantData[relevantData.count-1].dataDate! != todaysDateAsString){
                saveName(0, date: todaysDateAsString, objectContext: appDelegate.managedObjectContext)
            }
            counterLabel.text = String(graphPoint[graphPoint.count-1])
            counterView.counter = graphPoint[graphPoint.count-1]
            checkTotal()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func weekBefore(){
        let calendar = NSCalendar.currentCalendar()
        let date = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for(var i = 7; i > 0; i--){
            let dayBeforeDate = calendar.dateByAddingUnit(NSCalendarUnit.Day, value: i * -1, toDate: date, options: NSCalendarOptions.MatchFirst)!
            saveName(0, date: dateFormatter.stringFromDate(dayBeforeDate), objectContext: appDelegate.managedObjectContext)
        }
    }
    
    func setupGraphDisplay() {
        
        if let relevantData = getDataToUse {
            var average : Double = 0
            
            
            for (var i = 0; i <= 6; i++) {
                var index = i
                index++
                if let labelView = graphView.viewWithTag(index) as? UILabel {
                    let stringDate = relevantData[i].dataDate!
                    labelView.text = formattedGraphDate(stringDate, index: i)
                    print("\(relevantData[i].dataDate) \(relevantData[i].cupsDrunk) ")
                    average = average + (relevantData[i].cupsDrunk?.doubleValue)!
                }
            }
            averageWaterDrunk.text = "\(average/(relevantData.count as NSNumber).doubleValue)"
            graphView.setNeedsDisplay()
        }
        
    }

    @IBAction func btnPushButton(button: PushButtonView) {
        
        if (button.isAddButton) {
            if(counterView.counter < 8){
                counterView.counter++
            }
        } else {
            if counterView.counter > 0 {
                counterView.counter--
            }
        }
        counterLabel.text = String(counterView.counter)
        
        if isGraphViewShowing {
            counterViewTap(nil)
        }
        let managedContext = appDelegate.managedObjectContext
        saveName(counterView.counter, date: todaysDateAsString, objectContext: managedContext)
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
        if counterView.counter >= 8 {
            medalView.showMedal(true)
        } else {
            medalView.showMedal(false)
        }
    }
    
    func formattedGraphDate(stringToFormat: String, index: Int) -> String {
        let fullNameArr = split(stringToFormat.characters){$0 == "-"}.map(String.init)
        let dateComponents = NSDateComponents()
        dateComponents.year = (fullNameArr[0] as NSString).integerValue
        dateComponents.month = (fullNameArr[1] as NSString).integerValue
        dateComponents.day = (fullNameArr[2] as NSString).integerValue
        //
        let formatedDate = NSCalendar.currentCalendar().dateFromComponents(dateComponents)!
        let formatter = NSDateFormatter()
        if index == 0 {
            formatter.dateFormat = "MMM dd"
        } else {
            formatter.dateFormat = "dd"
        }
        return formatter.stringFromDate(formatedDate)
    }
    
    func saveName(name: Int, date: String, objectContext: NSManagedObjectContext) {
        do {
            let fetchRequestDate = NSFetchRequest(entityName: "GraphData")
            fetchRequestDate.predicate = NSPredicate(format: "dataDate = %@", date)
            let graphData : [GraphData]? = executeFetchRequestT(fetchRequestDate, managedObjectContext: objectContext)
            if (graphData != nil && graphData!.count != 0) {
                let managedObject = graphData![0]
                managedObject.cupsDrunk = name
            }
            else {
                let entity =  NSEntityDescription.entityForName("GraphData",
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
    
    func fetchData(objectContext: NSManagedObjectContext) -> ([GraphData]?, Int?){
        let fetchRequestAll = NSFetchRequest(entityName:"GraphData")
        let graphData : [GraphData] = executeFetchRequestT(fetchRequestAll, managedObjectContext: objectContext)!
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
        let calendar = NSCalendar.currentCalendar()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        _ = calendar.dateByAddingUnit(NSCalendarUnit.Day, value: +2, toDate: todaysDate, options: NSCalendarOptions.MatchFirst)!
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
    
    var getDataToUse : ArraySlice<GraphData>?{
        let managedContext = appDelegate.managedObjectContext
        let fetchedData = fetchData(managedContext)
        if fetchedData.0!.count != 0 {
            let beginIndex = fetchedData.1!-7
            let endIndex = fetchedData.1!-1
            return fetchedData.0![beginIndex...endIndex]
        } else {
            return nil
        }
    }
    
}

