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
        // 1
        baseCenter = CGPoint(x: viewFrame.size.width / 2,
            y: viewFrame.size.height / 2)
        
        // 2
        knobImageView = UIImageView(image: UIImage(named: "knob"))
        knobImageView.frame.size.width /= 2
        knobImageView.frame.size.height /= 2
        knobImageView.center = baseCenter
        
        super.init(frame: viewFrame)
        
        // 3
        userInteractionEnabled = true
        
        // 4
        let baseImageView = UIImageView(frame: bounds)
        baseImageView.image = UIImage(named: "base")
        addSubview(baseImageView)
        
        // 5
        addSubview(knobImageView)
        
        // 6
        assert(CGRectContainsRect(bounds, knobImageView.bounds),
            "Analog control should be larger than the knob in size")
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }

}
