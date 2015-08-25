//
//  GraphController.swift
//  Graphics
//
//  Created by Mindaugas on 8/24/15.
//  Copyright © 2015 Mindaugas. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class GraphController {
    
    lazy var graphPointArray:[Int] = self.graphPoints
    lazy var relevantData:ArraySlice<GraphData> = self.getDataToUse
    
    var graphPoints : [Int] {
        get {
            var graphData = getDataToUse
            var graphPoint:[Int] = []
            
            for(var i = 0; i < graphData.count; i++){
                //print(graphData[i].cupsDrunk!.integerValue)
                graphPoint.append(graphData[i].cupsDrunk!.integerValue)
            }
//            print("graphPointArray Reversed")
//            print(graphPoint.reverse())
            return graphPoint
        }
    }
    
    var getDataToUse : ArraySlice<GraphData>{
        let fetchedData = fetchData()
        let beginIndex = fetchedData.1!-7
        let endIndex = fetchedData.1!-1
        print(fetchedData.0![beginIndex])
        print(fetchedData.0![endIndex])
        return fetchedData.0![beginIndex...endIndex]
    }
    
//    func weekBefore(){
//        let calendar = NSCalendar.currentCalendar()
//        let date = NSDate()
//        let dateFormatter:NSDateFormatter = NSDateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        
//        for(var i = 0; i < 7; i++){
//            let dayBeforeDate = calendar.dateByAddingUnit(NSCalendarUnit.Day, value: i * -1, toDate: date, options: NSCalendarOptions.MatchFirst)!
//            saveName(1, date: dateFormatter.stringFromDate(dayBeforeDate))
//        }
//    }
    
    func formattedGraphDate(stringToFormat: String, index: Int) -> String {
        let fullNameArr = split(stringToFormat.characters){$0 == "-"}.map(String.init)
        let dateComponents = NSDateComponents()
        dateComponents.year = (fullNameArr[0] as NSString).integerValue
        dateComponents.month = (fullNameArr[1] as NSString).integerValue
        dateComponents.day = (fullNameArr[2] as NSString).integerValue
        //
        let formatedDate = NSCalendar.currentCalendar().dateFromComponents(dateComponents)!
        let formatter = NSDateFormatter()
        if index == 6 {
            formatter.dateFormat = "MMM dd"
        } else {
            formatter.dateFormat = "dd"
        }
        return formatter.stringFromDate(formatedDate)
    }
    
    func saveName(name: Int, date: String, objectContext: NSManagedObjectContext) {
        //1
        do {
            let fetchRequestDate = NSFetchRequest(entityName: "GraphData")
            fetchRequestDate.predicate = NSPredicate(format: "dataDate = %@", date)
            let graphData : [GraphData] = executeFetchRequestT(fetchRequestDate, managedObjectContext: objectContext)!
            if graphData.count != 0{
                
                let managedObject = graphData[0]
                managedObject.cupsDrunk = name
                
            } else {
                let entity =  NSEntityDescription.entityForName("GraphData",
                    inManagedObjectContext:objectContext)
                
                let newConsumptionEntry = NSManagedObject(entity: entity!,
                    insertIntoManagedObjectContext:objectContext)
                
                newConsumptionEntry.setValue(name, forKey: "cupsDrunk")
                newConsumptionEntry.setValue(date, forKey: "dataDate")
            }
            try objectContext.save()
            graphPointArray = self.graphPoints
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
    
}