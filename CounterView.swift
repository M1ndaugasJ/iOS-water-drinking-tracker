//
//  CounterView.swift
//  Graphics
//
//  Created by Mindaugas on 8/18/15.
//  Copyright © 2015 Mindaugas. All rights reserved.
//

import UIKit

let NoOfGlasses = 8
let π:CGFloat = CGFloat(M_PI)

class CounterView: UIView {
    
    var counter: Int = 0 {
        didSet {
            if counter <=  NoOfGlasses {
                //the view needs to be refreshed
                setNeedsDisplay()
            }
        }
    }
    var outlineColor: UIColor = UIColor.blueColor()
    var counterColor: UIColor = UIColor.orangeColor()
    
    override func drawRect(rect: CGRect) {
        
        let center = CGPoint(x:bounds.width/2, y: bounds.height/2)
        let radius: CGFloat = max(bounds.width, bounds.height)
        let arcWidth: CGFloat = 76
        let startAngle: CGFloat = 3 * π / 4
        let endAngle: CGFloat = π / 4
        
        let path = UIBezierPath(arcCenter: center,
            radius: radius/2 - arcWidth/2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true)
        
        path.lineWidth = arcWidth
        counterColor.setStroke()
        path.stroke()
        
        let angleDifference: CGFloat = 2 * π - startAngle + endAngle
        
        //then calculate the arc for each single glass
        let arcLengthPerGlass = angleDifference / CGFloat(NoOfGlasses)
        
        if counter >= 1 {
            
            
            //then multiply out by the actual glasses drunk
            let outlineEndAngle = arcLengthPerGlass * CGFloat(counter) + startAngle
            
            //2 - draw the outer arc
            let outlinePath = UIBezierPath(arcCenter: center,
                radius: bounds.width/2 - 2.5,
                startAngle: startAngle,
                endAngle: outlineEndAngle,
                clockwise: true)
            
            //3 - draw the inner arc
            outlinePath.addArcWithCenter(center,
                radius: bounds.width/2 - arcWidth + 2.5,
                startAngle: outlineEndAngle,
                endAngle: startAngle,
                clockwise: false)
            
            //4 - close the path
            outlinePath.closePath()
            
            outlineColor.setStroke()
            outlinePath.lineWidth = 5.0
            outlinePath.stroke()
        }
        
    }
    
    
    
}