//
//  AnalogControl.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/2/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import UIKit

protocol AnalogControlPositionChange {
    func analogControlPositionChanged(analogControl: AnalogControl, position: CGPoint)
}

class AnalogControl: UIView {

    let baseCenter: CGPoint
    let knobImageView: UIImageView
    
    var relativePosition: CGPoint!
    
    var delegate: AnalogControlPositionChange?
    
    override init(frame viewFrame: CGRect) {
        // calculate the neutral position of the knob.
        baseCenter = CGPoint(x: viewFrame.size.width / 2,
            y: viewFrame.size.height / 2)
        
        // create the knob from knob.png and display in a neutral position.
        knobImageView = UIImageView(image: UIImage(named: "knob"))
        knobImageView.frame.size.width /= 2
        knobImageView.frame.size.height /= 2
        knobImageView.center = baseCenter
        
        super.init(frame: viewFrame)
        
        // set touches enabled.
        userInteractionEnabled = true
        
        // create a view out of base.png
        let baseImageView = UIImageView(frame: bounds)
        baseImageView.image = UIImage(named: "base")
        addSubview(baseImageView)
        
        // add the knob to the view
        addSubview(knobImageView)
        
        // check the controls bounding box contains the entire knob
        assert(CGRectContainsRect(bounds, knobImageView.bounds),
            "Analog control should be larger than the knob in size")
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    func updateKnobWithPosition(position:CGPoint) {
        // Substract the position of the touch from the center of the joypad image.
        var positionToCenter = position - baseCenter
        var direction: CGPoint
        
        if positionToCenter == CGPointZero {
            direction = CGPointZero
        } else {
            direction = positionToCenter.normalized()
        }
        
        // calculate the radius and the length of the relative offset.
        let radius = frame.size.width / 2
        var length = positionToCenter.length()
        
        // if length is greater than radius, make a vector that points in the same direction but has length of the radius.
        if length > radius {
            length = radius
            positionToCenter = direction * radius
        }
        
        let relPosition = CGPoint(x: direction.x * (length/radius),
            y: direction.y * (length/radius))
        
        knobImageView.center = baseCenter + positionToCenter
        relativePosition = relPosition
        
        delegate?.analogControlPositionChanged(self, position: relativePosition)
    }
    
    override func touchesBegan(touches: NSSet,
        withEvent event: UIEvent) {
        let touchLocation = touches.anyObject()!.locationInView(self)
        updateKnobWithPosition(touchLocation)
    }
    
    override func touchesMoved(touches: NSSet,
        withEvent event: UIEvent) {
        let touchLocation = touches.anyObject()!.locationInView(self)
        updateKnobWithPosition(touchLocation)
    }
    
    override func touchesEnded(touches: NSSet,
        withEvent event: UIEvent) {
        updateKnobWithPosition(baseCenter)
    }
    
    override func touchesCancelled(touches: NSSet!,
        withEvent event: UIEvent!) {
        updateKnobWithPosition(baseCenter)
    }
}
