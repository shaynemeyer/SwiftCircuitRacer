//
//  AnalogControl.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/2/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import UIKit

class AnalogControl: UIView {

    let baseCenter: CGPoint
    let knobImageView: UIImageView
    
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

}
